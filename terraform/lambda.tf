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
  name_prefix = "lambda_create_emc_job_exe"
  tags        = local.default_tags
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : "logs:CreateLogGroup",
        "Resource" : "arn:aws:logs:ap-northeast-1:${var.aws_account_id}:*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : [
          "arn:aws:logs:ap-northeast-1:${var.aws_account_id}:log-group:/aws/lambda/create-emc-job:*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
        ],
        "Resource" : [
          "${aws_dynamodb_table.video_encoding_status_tracking.arn}"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "mediaconvert:*",
          "s3:ListAllMyBuckets",
          "s3:ListBucket"
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
