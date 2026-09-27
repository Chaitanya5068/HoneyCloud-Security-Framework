resource "aws_cloudtrail" "trail" {
  name           = "honeycloud-trail"
  s3_bucket_name = aws_s3_bucket.logs.id

  include_global_service_events = true
  is_multi_region_trail         = true
  enable_logging                = true
}