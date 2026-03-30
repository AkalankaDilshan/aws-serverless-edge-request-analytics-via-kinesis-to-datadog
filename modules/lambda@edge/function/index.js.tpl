"use strict";

const { KinesisClient, PutRecordCommand } = require("@aws-sdk/client-kinesis");

const STREAM_NAME   = "${kinesis_stream_name}";
const STREAM_REGION = "${kinesis_region}";

const kinesisClient = new KinesisClient({ region: STREAM_REGION})

exports.handler = async(event) => {
    const cfRecord = event.Records[0].cf;
    const { request } = cfRecord;
    const { uri, clientIp } = request;

    try {
        await kinesisClient.send(
            new PutRecordCommand({
                StreamName: STREAM_NAME,
                PartitionKey: clientIp || uri,
                Data: Buffer.from(JSON.stringify(request)),
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