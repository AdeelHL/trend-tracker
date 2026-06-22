# dynamodb.tf — the time-series table that stores ISS position readings.

resource "aws_dynamodb_table" "data" {
  name = "${var.project_name}-data"

  # PAY_PER_REQUEST = on-demand pricing. No capacity to manage, and you only
  # pay per read/write. Stays in the free tier at hobby volume.
  billing_mode = "PAY_PER_REQUEST"

  hash_key  = "series_id" # partition key — groups all readings for one series
  range_key = "ts"        # sort key — ISO timestamp, keeps rows time-ordered

  # You only declare the attributes used in keys; everything else is schemaless.
  attribute {
    name = "series_id"
    type = "S" # String
  }
  attribute {
    name = "ts"
    type = "S" # String
  }
}
