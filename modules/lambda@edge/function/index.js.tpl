"use strict";

const { KinesisClient, PutRecordCommand } = require("@aws-sdk/client-kinesis");

const STREAM_NAME   = "${kinesis_stream_name}";
const STREAM_REGION = "${kinesis_region}";

const kinesisClient = new KinesisClient({ region: STREAM_REGION});

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

exports.handler = async(event) => {
    const cfRecord = event.Records[0].cf;
    const { request, config } = cfRecord;
    const { headers, uri, method, querystring, clientIp } = request;

    // data record body
    const record = {
        timestamp: new Date().toISOString(),
        clientIp,
        geo: extractGeo(headers),
        requestId: config.requestId,
        distributionId: config.distributionId,
        eventType: config.eventType,
        method,
        uri,
        querystring: querystring || null,
        host: getHeader(headers, "host"),
        protocol: getHeader(headers, "cloudfront-forwarded-proto"),

    }

    try {
        await kinesisClient.send(
            new PutRecordCommand({
                StreamName: STREAM_NAME,
                PartitionKey: clientIp || uri,
                Data: Buffer.from(JSON.stringify(record)),
            })
        );
    } catch(err) {
            console.error(
                JSON.stringify({
                    level:   "ERROR",
                    message: "Kinesis publish failed",
                    error:   err.message,
                    stream:  STREAM_NAME,
                    uri,
                })
            );
        };
        
    return request;

}; 