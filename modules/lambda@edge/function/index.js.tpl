"use strict";

const { KinesisClient, PutRecordCommand } = require("@aws-sdk/client-kinesis");

const STREAM_NAME   = "${kinesis_stream_name}";
const STREAM_REGION = "${kinesis_region}";

const kinesisClient = new KinesisClient({ region: STREAM_REGION });

function getHeader(headers, name) {
  const entry = headers[name.toLowerCase()];
  return entry && entry.length > 0 ? entry[0].value : null;
}

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

function detectDevice(ua) {
  if (!ua) return { type: "unknown", os: "unknown", browser: "unknown" };

  const type =
    /mobi|android|iphone|ipad|ipod|blackberry|iemobile|opera mini/i.test(ua)
      ? "mobile"
      : /tablet|ipad/i.test(ua)
      ? "tablet"
      : "desktop";

  const os =
    /windows nt/i.test(ua)         ? "Windows"
    : /mac os x/i.test(ua)         ? "macOS"
    : /android/i.test(ua)          ? "Android"
    : /iphone|ipad|ipod/i.test(ua) ? "iOS"
    : /linux/i.test(ua)            ? "Linux"
    : /cros/i.test(ua)             ? "ChromeOS"
    : "Other";

  const browser =
    /edg\//i.test(ua)          ? "Edge"
    : /opr\//i.test(ua)        ? "Opera"
    : /chrome/i.test(ua)       ? "Chrome"
    : /firefox/i.test(ua)      ? "Firefox"
    : /safari/i.test(ua)       ? "Safari"
    : /msie|trident/i.test(ua) ? "IE"
    : "Other";

  const versionMatch = ua.match(/(?:Chrome|Firefox|Safari|Edg|OPR)[\/ ]([\d.]+)/i);
  const browserVersion = versionMatch ? versionMatch[1].split(".")[0] : null;

  return { type, os, browser, browserVersion };
}

function parseAcceptLanguage(raw) {
  if (!raw) return [];
  return raw
    .split(",")
    .map((s) => s.trim().split(";")[0])
    .filter(Boolean);
}

exports.handler = async (event) => {
  const cfRecord  = event.Records[0].cf;
  const { request, config } = cfRecord;
  const { headers, uri, method, querystring, clientIp } = request;

  const userAgent = getHeader(headers, "user-agent");
  const referrer  = getHeader(headers, "referer") || getHeader(headers, "referrer");

  const record = {
    timestamp:       new Date().toISOString(),
    requestId:       config.requestId,
    distributionId:  config.distributionId,
    eventType:       config.eventType,
    method,
    uri,
    querystring:     querystring || null,
    host:            getHeader(headers, "host"),
    protocol:        getHeader(headers, "cloudfront-forwarded-proto"),
    clientIp,
    userAgent,
    referrer,
    acceptLanguages: parseAcceptLanguage(getHeader(headers, "accept-language")),
    acceptEncoding:  getHeader(headers, "accept-encoding"),
    geo:             extractGeo(headers),
    device:          detectDevice(userAgent),
    cacheControl:    getHeader(headers, "cache-control"),
    pragma:          getHeader(headers, "pragma"),
  };

  await Promise.race([
    kinesisClient.send(
      new PutRecordCommand({
        StreamName:   STREAM_NAME,
        PartitionKey: clientIp || uri,
        Data:         Buffer.from(JSON.stringify(record)),
      })
    ),
    new Promise((resolve) => setTimeout(resolve, 800)),
  ]).catch((err) => {
    console.error(JSON.stringify({
      level:   "ERROR",
      message: "Kinesis publish failed",
      error:   err.message,
      stream:  STREAM_NAME,
      uri,
    }));
  });

  return request;
};