variable "kinesis_stream_name" {
  type = string
  description = "name of the Kinesis Data Stream that the edge function will publish metadata records to" # like cloudfront-edge-events
  
  # this part recommend for cloudcode AI
  validation {
    condition = length(var.kinesis_stream_name) > 0 && length(var.kinesis_stream_name) <= 128
    error_message = "kinesis_stream_name must be between 1 & 128 chars "
    }
}

variable "kinesis_stream_arn" {
  type = string
  description = "full ARN of the kinesis data stream" # Example: "arn:aws:kinesis:us-east-1:123456789012:stream/cloudfront-edge-events"
  validation {
    condition = can(regex("^arn:aws:kinesis:", var.kinesis_stream_arn))
    error_message = "kinesis_stream_arn must be valid Kinesis ARN starting with arn:aws:kinesis:"
  }
}

variable "kinesis_region" {
  type = string
  description = "AWS region where the Kinesis Data Stream is deployed."
}

variable "function_name" {
  type = string
  description = "name of the Lambda function" # like cloudfront-edge-metadata
}