resource "aws_kinesis_firehose_delivery_stream" "this" {
  name        = var.delivery_stream_name
  destination = "http_endpoint"

  # source
  kinesis_source_configuration {
    kinesis_stream_arn = var.kinesis_stream_arn
    role_arn           = var.firehose_iam_role_arn
  }

  #destination : dd
  http_endpoint_configuration {
    name               = "Datadog"
    url                = var.datadog_url
    access_key         = var.datadog_api_key
    buffering_size     = 4
    buffering_interval = 60
    role_arn           = var.firehose_iam_role_arn
    retry_duration     = 300 # 300s
    s3_backup_mode     = "FailedDataOnly"

    request_configuration {
      common_attributes {
        name  = "dd_source"
        value = "aws-lambda-edge"
      }
      common_attributes {
        name  = "dd_service"
        value = var.delivery_stream_name
      }
    }

    s3_configuration {
      role_arn           = var.firehose_iam_role_arn
      bucket_arn         = var.s3_backup_arn
      buffering_size     = 128
      buffering_interval = 300

      # Partition logs by date/hour for easy Athena querying:
      # edge-logs/2026/03/08/10/firehose-1-2026-03-08-10-00-00.gz
      prefix              = "edge-logs/!{timestamp:yyyy}/!{timestamp:MM}/!{timestamp:dd}/!{timestamp:HH}/"
      error_output_prefix = "edge-logs-errors/!{firehose:error-output-type}/!{timestamp:yyyy}/!{timestamp:MM}/!{timestamp:dd}/"

      compression_format = "GZIP"
    }
  }
}