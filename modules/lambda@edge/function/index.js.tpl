"use strict";

/**
 * Lambda@Edge — Viewer Request
 * ─────────────────────────────────────────────────────────────────────────────
 * Captures rich per-request metadata at CloudFront edge locations and publishes
 * it asynchronously to Kinesis Data Streams without blocking the viewer request.
 *
 * Metadata collected:
 *   • Geo       – country, region, city, lat/lon, timezone, postal (CF headers)
 *   • Device    – type (mobile/tablet/desktop), OS, browser  (User-Agent)
 *   • Referrer  – full referrer URL
 *   • Request   – method, URI, query string, host, client IP
 *   • Context   – CloudFront distribution ID, request ID, edge location
 *
 * Runtime limits (viewer-request): 128 MB RAM · 5 s timeout · no env vars
 * ─────────────────────────────────────────────────────────────────────────────
 * Values injected by Terraform templatefile():
 *   STREAM_NAME  = ${kinesis_stream_name}
 *   STREAM_REGION = ${kinesis_region}
 */

const { KinesisClient, PutRecordCommand } = require("@aws-sdk/client-kinesis");

// ── Constants baked in at Terraform plan time (no env var support in L@E) ─────
const STREAM_NAME   = "${kinesis_stream_name}";
const STREAM_REGION = "${kinesis_region}";

// Re-use the client across warm invocations
const kinesisClient = new KinesisClient({ region: STREAM_REGION });

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Safely read the first value of a CloudFront header (lowercase key).
 * Returns null when the header is absent.
 */
function getHeader(headers, name) {
  const entry = headers[name.toLowerCase()];
  return entry && entry.length > 0 ? entry[0].value : null;
}

/**
 * Extract all CloudFront-injected geo headers.
 * CloudFront populates these automatically at the edge — no GeoIP library needed.
 * https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/adding-cloudfront-headers.html
 */
function extractGeo(headers) {
  return {
    country:     getHeader(headers, "cloudfront-viewer-country"),
    countryName: getHeader(headers, "cloudfront-viewer-country-name"),
    region:      getHeader(headers, "cloudfront-viewer-country-region"),
    regionName:  getHeader(headers, "cloudfront-viewer-country-region-name"),
    city:        getHeader(headers, "cloudfront-viewer-city"),
    latitude:    getHeader(headers, "cloudfront-viewer-latitude"),
    longitude:   getHeader(headers, "cloudfront-viewer-longitude"),
    timezone:    getHeader(headers, "cloudfront-viewer-time-zone"),
    postalCode:  getHeader(headers, "cloudfront-viewer-postal-code"),
    metroCode:   getHeader(headers, "cloudfront-viewer-metro-code"),
    isDesktop:   getHeader(headers, "cloudfront-is-desktop-viewer"),
    isMobile:    getHeader(headers, "cloudfront-is-mobile-viewer"),
    isTablet:    getHeader(headers, "cloudfront-is-tablet-viewer"),
    isSmartTV:   getHeader(headers, "cloudfront-is-smarttv-viewer"),
  };
}

/**
 * Lightweight UA parser — avoids bundling heavy libraries inside a 128 MB edge fn.
 * Returns { type, os, browser } — "unknown" when no match.
 */
function detectDevice(ua) {
  if (!ua) return { type: "unknown", os: "unknown", browser: "unknown" };

  const type =
    /mobi|android|iphone|ipad|ipod|blackberry|iemobile|opera mini/i.test(ua)
      ? "mobile"
      : /tablet|ipad/i.test(ua)
      ? "tablet"
      : "desktop";

  const os =
    /windows nt/i.test(ua)      ? "Windows"
    : /mac os x/i.test(ua)      ? "macOS"
    : /android/i.test(ua)       ? "Android"
    : /iphone|ipad|ipod/i.test(ua) ? "iOS"
    : /linux/i.test(ua)         ? "Linux"
    : /cros/i.test(ua)          ? "ChromeOS"
    : "Other";

  const browser =
    /edg\//i.test(ua)           ? "Edge"
    : /opr\//i.test(ua)         ? "Opera"
    : /chrome/i.test(ua)        ? "Chrome"
    : /firefox/i.test(ua)       ? "Firefox"
    : /safari/i.test(ua)        ? "Safari"
    : /msie|trident/i.test(ua)  ? "IE"
    : "Other";

  // Extract approximate browser version for analytics granularity
  const versionMatch = ua.match(
    /(?:Chrome|Firefox|Safari|Edg|OPR)[\/ ]([\d.]+)/i
  );
  const browserVersion = versionMatch ? versionMatch[1].split(".")[0] : null;

  return { type, os, browser, browserVersion };
}

/**
 * Parse the Accept-Language header into a prioritised array.
 * e.g. "en-US,en;q=0.9,es;q=0.8" → ["en-US", "en", "es"]
 */
function parseAcceptLanguage(raw) {
  if (!raw) return [];
  return raw
    .split(",")
    .map((s) => s.trim().split(";")[0])
    .filter(Boolean);
}

// ─────────────────────────────────────────────────────────────────────────────
// Handler
// ─────────────────────────────────────────────────────────────────────────────
exports.handler = async (event) => {
  const cfRecord  = event.Records[0].cf;
  const { request, config } = cfRecord;
  const { headers, uri, method, querystring, clientIp } = request;

  // ── 1. Assemble metadata record ───────────────────────────────────────────
  const userAgent = getHeader(headers, "user-agent");
  const referrer  =
    getHeader(headers, "referer") || getHeader(headers, "referrer");

  const record = {
    // Timestamps & identifiers
    timestamp:      new Date().toISOString(),
    requestId:      config.requestId,
    distributionId: config.distributionId,
    eventType:      config.eventType,

    // HTTP request details
    method,
    uri,
    querystring: querystring || null,
    host:        getHeader(headers, "host"),
    protocol:    getHeader(headers, "cloudfront-forwarded-proto"),

    // Client
    clientIp,
    userAgent,
    referrer,
    acceptLanguages: parseAcceptLanguage(getHeader(headers, "accept-language")),
    acceptEncoding:  getHeader(headers, "accept-encoding"),

    // Geo — populated by CloudFront, zero latency
    geo: extractGeo(headers),

    // Device — derived from UA
    device: detectDevice(userAgent),

    // Cache context
    cacheControl: getHeader(headers, "cache-control"),
    pragma:       getHeader(headers, "pragma"),
  };

  // ── 2. Fire-and-forget publish to Kinesis ─────────────────────────────────
  // We intentionally do NOT await the Kinesis call.
  // Viewer-request functions have a hard 5 s budget; analytics must never
  // delay or break the viewer experience.
  kinesisClient
    .send(
      new PutRecordCommand({
        StreamName:   STREAM_NAME,
        PartitionKey: clientIp || uri,       // routes to a consistent shard
        Data:         Buffer.from(JSON.stringify(record)),
      })
    )
    .catch((err) => {
      // Swallow all Kinesis errors — analytics failures must be transparent
      console.error(
        JSON.stringify({
          level:   "ERROR",
          message: "Kinesis publish failed",
          error:   err.message,
          stream:  STREAM_NAME,
          uri,
        })
      );
    });

  // ── 3. Return the request unmodified ─────────────────────────────────────
  return request;
};
