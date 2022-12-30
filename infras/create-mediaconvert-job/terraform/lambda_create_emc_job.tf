data "aws_s3_object" "lambda_fucntion_create_emc_job_runtime" {
  bucket = var.lambda_fucntion_s3_bucket
  key    = var.lambda_fucntion_s3_create_emc_job_runtime
}


resource "aws_lambda_function" "create_emc_job" {
  description      = "This lambda function is to create Elemental MediaConvert Job"
  s3_bucket        = var.lambda_fucntion_s3_bucket
  s3_key           = "${var.project_prefix}/createEMCJob.zip"
  function_name    = "${var.project_prefix}-emc-create-job"
  role             = aws_iam_role.lambda_create_emc_job.arn
  handler          = "createEMCJob"
  runtime          = "go1.x"
  source_code_hash = data.aws_s3_object.lambda_fucntion_create_emc_job_runtime.etag

  environment {
    variables = {
      DYNAMODB_STATE_TABLE_NAME = aws_dynamodb_table.video_job_progress.name
      EMC_ROLE                  = aws_iam_role.mediaconvert_execution.arn
      EMC_QUEUE                 = aws_media_convert_queue.vod_pipeline.id
      EMC_ENDPOINT              = var.mediaconvert_endpoint
    }
  }
}


resource "aws_iam_role" "lambda_create_emc_job" {
  name_prefix = "lambda_create_emc_job"
  tags        = local.default_tags
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

resource "aws_iam_policy" "lambda_create_emc_job_execution" {
  name_prefix = "lambda_create_emc_job_execution"
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
        "Resource" : "${aws_cloudwatch_log_group.lambda_emc_create_job.arn}:*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
        ],
        "Resource" : [
          "${aws_dynamodb_table.video_job_progress.arn}"
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

resource "aws_iam_role_policy_attachment" "attach_lambda_create_emc_job_execution" {
  role       = aws_iam_role.lambda_create_emc_job.name
  policy_arn = aws_iam_policy.lambda_create_emc_job_execution.arn
}
