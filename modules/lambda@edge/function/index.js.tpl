"use strict";

const { KinesisClient, PutRecordCommand } = require("@aws-sdk/client-kinesis");

const STREAM_NAME = "${kinesis_stream_name}";
const STREAM_REGION = "${kinesis_region}";

const kinesisClient = new KinesisClient({ region: STREAM_REGION });

// Simple helper to get header values
function getHeader(headers, name) {
  const entry = headers[name.toLowerCase()];
  return entry && entry.length > 0 ? entry[0].value : null;
}

exports.handler = (event, context, callback) => {
  try {
    const cfRecord = event.Records[0].cf;
    const { request, config } = cfRecord;
    const { headers, uri, clientIp } = request;

    const userAgent = getHeader(headers, "user-agent");

    // Simple user counter record - only essential metadata
    const record = {
      timestamp: new Date().toISOString(),
      requestId: config.requestId,
      distributionId: config.distributionId,
      uri: uri,
      clientIp: clientIp,
      userAgent: userAgent,
      // Basic device type detection
      deviceType: (() => {
        const ua = userAgent || "";
        if (/mobile|android|iphone|ipad|ipod/i.test(ua)) return "mobile";
        if (/tablet|ipad/i.test(ua)) return "tablet";
        return "desktop";
      })(),
      country: getHeader(headers, "cloudfront-viewer-country"),
      // Optional: add these if you want them in Datadog
      method: request.method,
      referrer: getHeader(headers, "referer") || getHeader(headers, "referrer")
    };

    // Fire and forget - send to Kinesis without waiting
    kinesisClient.send(
      new PutRecordCommand({
        StreamName: STREAM_NAME,
        PartitionKey: clientIp || uri,
        Data: Buffer.from(JSON.stringify(record)),
      })
    ).catch((err) => {
      // Log error but don't block the response
      console.error("Kinesis error:", err.message);
    });

    // Tell Lambda not to wait for Kinesis
    context.callbackWaitsForEmptyEventLoop = false;
    
    // Immediately return the request to CloudFront
    callback(null, request);
    
  } catch (error) {
    // If anything fails, still return the request
    console.error('Lambda@Edge error:', error);
    callback(null, event.Records[0].cf.request);
  }
};