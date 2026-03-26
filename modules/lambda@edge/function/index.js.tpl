"use strict";

const { KinesisClient, PutRecordCommand } = require("@aws-sdk/client-kinesis");

const STREAM_NAME = "${kinesis_stream_name}";
const STREAM_REGION = "${kinesis_region}";

const kinesisClient = new KinesisClient({ region: STREAM_REGION });

// Helper to safely get header value
function getHeader(headers, name) {
  const entry = headers[name.toLowerCase()];
  return entry && entry.length > 0 ? entry[0].value : null;
}

exports.handler = (event, context, callback) => {
  try {
    const cf = event.Records[0].cf;
    const { request, response, config } = cf;   // ← changed for Viewer Response

    const headers = request.headers;
    const userAgent = getHeader(headers, "user-agent");

    const record = {
      timestamp: new Date().toISOString(),
      requestId: config.requestId,
      distributionId: config.distributionId,
      uri: request.uri,
      querystring: request.querystring || "",        // ← added
      fullPath: request.uri + (request.querystring ? `?${request.querystring}` : ""),
      clientIp: request.clientIp,
      userAgent: userAgent,
      // Improved device detection (order matters!)
      deviceType: (() => {
        const ua = (userAgent || "").toLowerCase();
        if (/tablet|ipad/i.test(ua)) return "tablet";
        if (/mobile|android|iphone|ipod/i.test(ua)) return "mobile";
        return "desktop";
      })(),
      country: getHeader(headers, "cloudfront-viewer-country"),
      method: request.method,
      referrer: getHeader(headers, "referer") || getHeader(headers, "referrer"),
      // Extra useful fields when using Viewer Response trigger
      statusCode: response.statusCode,
      statusDescription: response.statusDescription || "",
    };

    // Fire-and-forget to Kinesis (no await, no blocking)
    kinesisClient.send(
      new PutRecordCommand({
        StreamName: STREAM_NAME,
        PartitionKey: config.requestId,               // ← better distribution
        Data: Buffer.from(JSON.stringify(record)),
      })
    ).catch((err) => {
      console.error("Kinesis PutRecord failed:", err.message);
      // Do NOT re-throw — we never want to block the response
    });

    // Critical for async logging in Lambda@Edge
    context.callbackWaitsForEmptyEventLoop = false;

    // Return the response immediately (Viewer Response trigger)
    callback(null, response);

  } catch (error) {
    console.error("Lambda@Edge error:", error);
    // Always return the original response so the user never sees an error
    callback(null, event.Records[0].cf.response);
  }
};