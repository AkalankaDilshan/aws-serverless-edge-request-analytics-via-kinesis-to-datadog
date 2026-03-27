"use strict";

const { KinesisClient, PutRecordCommand } = require("@aws-sdk/client-kinesis");

const STREAM_NAME = "${kinesis_stream_name}";
const STREAM_REGION = "${kinesis_region}";

const kinesisClient = new KinesisClient({ region: STREAM_REGION });

function getHeader(headers, name) {
  if (!headers) return null;
  const entry = headers[name.toLowerCase()];
  return entry && entry.length > 0 ? entry[0].value : null;
}

exports.handler = (event, context, callback) => {
  // Always log entry for debugging
  console.log("Edge analytics invoked for request");

  try {
    const cf = event.Records[0].cf;
    const request = cf.request;
    const response = cf.response; // undefined in Viewer Request

    const headers = request.headers || {};
    const userAgent = getHeader(headers, "user-agent");

    const record = {
      timestamp: new Date().toISOString(),
      requestId: cf.config.requestId,
      distributionId: cf.config.distributionId,
      uri: request.uri,
      querystring: request.querystring || "",
      clientIp: request.clientIp,
      userAgent: userAgent,
      deviceType: (() => {
        const ua = (userAgent || "").toLowerCase();
        if (/tablet|ipad/i.test(ua)) return "tablet";
        if (/mobile|android|iphone|ipod/i.test(ua)) return "mobile";
        return "desktop";
      })(),
      country: getHeader(headers, "cloudfront-viewer-country"),
      method: request.method,
      referrer: getHeader(headers, "referer") || getHeader(headers, "referrer"),
      statusCode: response ? response.statusCode : null,
    };

    // Fire and forget
    kinesisClient.send(
      new PutRecordCommand({
        StreamName: STREAM_NAME,
        PartitionKey: cf.config.requestId || request.clientIp || "default",
        Data: Buffer.from(JSON.stringify(record)),
      })
    ).catch(err => {
      console.error("Kinesis PutRecord failed:", err.message);
    });

    context.callbackWaitsForEmptyEventLoop = false;

    // Safe return - works for both Viewer Request and Viewer Response
    callback(null, response || request);

  } catch (error) {
    console.error("Lambda@Edge CRITICAL ERROR:", error.message);
    if (error.stack) console.error("Stack:", error.stack);
    
    // Never let our code break the response
    const fallback = event.Records && event.Records[0] && event.Records[0].cf 
      ? (event.Records[0].cf.response || event.Records[0].cf.request)
      : {};
    callback(null, fallback);
  }
};