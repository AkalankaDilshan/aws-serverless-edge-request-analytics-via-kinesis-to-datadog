output "stream_arn" {
  description = "full arn of the kinesis data stream"
  value = aws_kinesis_stream.this.arn
}

output "stream_name" {
  description = "name of kinesis data stream"
  value = aws_kinesis_stream.this.name
}