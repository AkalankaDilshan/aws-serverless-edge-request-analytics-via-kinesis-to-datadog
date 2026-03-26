"use strict";

const { KinesisClient, PutRecordCommand } = require("@aws-sdk/client-kinesis");

const STREAM_NAME = "${kinesis_stream_name}";
const STREAM_REGION = "${kinesis_region}";

const kinesisClient = new KinesisClient({ region: STREAM_REGION });

function getHeader(headers, name) {
  const entry = headers[name.toLowerCase()];
  return entry && entry.length > 0 ? entry[0].value : null;
}

exports.handler = (event, context, callback) => {
  try {
    const cf = event.Records[0].cf;
    const { request, response, config } = cf;

    const headers = request.headers;
    const userAgent = getHeader(headers, "user-agent");

    const record = {
      timestamp: new Date().toISOString(),
      requestId: config.requestId,
      distributionId: config.distributionId,
      uri: request.uri,
      querystring: request.querystring || "",
      fullPath: request.uri + (request.querystring ? `?$${request.querystring}` : ""),
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
      statusCode: response.statusCode,
      statusDescription: response.statusDescription || "",
    };

    kinesisClient.send(
      new PutRecordCommand({
        StreamName: STREAM_NAME,
        PartitionKey: config.requestId,
        Data: Buffer.from(JSON.stringify(record)),
      })
    ).catch((err) => {
      console.error("Kinesis PutRecord failed:", err.message);
    });

    context.callbackWaitsForEmptyEventLoop = false;
    callback(null, response);

  } catch (error) {
    console.error("Lambda@Edge error:", error);
    callback(null, event.Records[0].cf.response);
  }
};