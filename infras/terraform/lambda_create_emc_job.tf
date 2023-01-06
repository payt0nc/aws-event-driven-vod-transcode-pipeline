data "aws_s3_object" "lambda_fucntion_create_encoding_job_runtime" {
  bucket = var.lambda_fucntion_s3_bucket
  key    = var.lambda_fucntion_s3_create_encoding_job_runtime
}


resource "aws_lambda_function" "create_encoding_job" {
  description      = "This lambda function is to create Elemental MediaConvert Job"
  s3_bucket        = var.lambda_fucntion_s3_bucket
  s3_key           = var.lambda_fucntion_s3_create_encoding_job_runtime
  function_name    = "${var.project_prefix}-create-encoding-job"
  role             = aws_iam_role.lambda_create_encoding_job.arn
  handler          = "createEncodingJob"
  runtime          = "go1.x"
  source_code_hash = data.aws_s3_object.lambda_fucntion_create_encoding_job_runtime.etag
  tags             = local.default_tags

  environment {
    variables = {
      DYNAMODB_SFN_TOKEN_TABLE_NAME = aws_dynamodb_table.sfn_token.name
      EMC_ROLE                      = aws_iam_role.mediaconvert_execution.arn
      EMC_QUEUE                     = aws_media_convert_queue.vod_pipeline.id
      EMC_ENDPOINT                  = var.mediaconvert_endpoint
      EMC_OUTPUT_BUCKET             = aws_s3_bucket.video_output.bucket
    }
  }
}


resource "aws_iam_role" "lambda_create_encoding_job" {
  name = "lambda-create-encoding-job"
  tags = local.default_tags
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "lambda.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_create_encoding_job_execution" {
  name_prefix = "lambda-create-encoding-job"
  tags        = local.default_tags
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : "${aws_cloudwatch_log_group.lambda_create_encoding_job.arn}:*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
        ],
        "Resource" : [
          "${aws_dynamodb_table.sfn_token.arn}"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:ListAllMyBuckets",
          "s3:ListBucket"
        ],
        "Resource" : "${aws_s3_bucket.video_origin.arn}"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "mediaconvert:CreateJob",
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "iam:PassRole"
        ],
        "Resource" : "*",
        "Condition" : {
          "StringLike" : {
            "iam:PassedToService" : [
              "mediaconvert.amazonaws.com"
            ]
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_lambda_create_encoding_job_execution" {
  role       = aws_iam_role.lambda_create_encoding_job.name
  policy_arn = aws_iam_policy.lambda_create_encoding_job_execution.arn
}
