locals {
  iam_naming_prefix = "emc-encoding-pipeline-sfn"
}

resource "aws_iam_role" "stepfunctions_emc_encoding_pipeline" {
  name = "stepfunctions-emc-encoding-pipeline"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "states.amazonaws.com"
        },
        "Action" : "sts:AssumeRole",
        "Condition" : {
          "StringEquals" : {
            "aws:SourceAccount" : "${var.aws_account_id}"
          },
          "ArnLike" : {
            "aws:SourceArn" : "arn:aws:states:ap-northeast-1:${var.aws_account_id}:stateMachine:*"
          }
        }
      }
    ]
  })

  tags = local.default_tags
}

resource "aws_iam_policy" "cloudwatchlogs_delivery_fullaccess" {
  name_prefix = local.iam_naming_prefix
  tags        = local.default_tags
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogDelivery",
          "logs:GetLogDelivery",
          "logs:UpdateLogDelivery",
          "logs:DeleteLogDelivery",
          "logs:ListLogDeliveries",
          "logs:PutResourcePolicy",
          "logs:DescribeResourcePolicies",
          "logs:DescribeLogGroups"
        ],
        "Resource" : "*"
      }
    ]
  })

}

resource "aws_iam_policy" "s3listbucket_fullaccess" {
  name_prefix = local.iam_naming_prefix
  tags        = local.default_tags
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:ListBucket"
        ],
        "Resource" : [
          "arn:aws:s3:::hpchan-poc-video-origin"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "snspublishscoped_access" {
  name_prefix = local.iam_naming_prefix
  tags        = local.default_tags
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : [
          "sns:Publish"
        ],
        "Resource" : [
          "arn:aws:sns:ap-northeast-1:${var.aws_account_id}:video-pipeline-origin-upload-events"
        ],
        "Condition" : {
          "StringEquals" : {
            "aws:SourceAccount" : "${var.aws_account_id}"
          },
        }
      }
    ]
  })
}

resource "aws_iam_policy" "stepfunctions_start_execution_management_scoped_access" {
  name_prefix = local.iam_naming_prefix
  tags        = local.default_tags
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : [
          "states:StartExecution"
        ],
        "Resource" : [
          "arn:aws:states:ap-northeast-1:${var.aws_account_id}:stateMachine:EMC-Encoding-Pipeline"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "states:DescribeExecution",
          "states:StopExecution"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "events:PutTargets",
          "events:PutRule",
          "events:DescribeRule"
        ],
        "Resource" : [
          "arn:aws:events:ap-northeast-1:${var.aws_account_id}:rule/StepFunctionsGetEventsForStepFunctionsExecutionRule"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "xray_access_policy" {
  name_prefix = local.iam_naming_prefix
  tags        = local.default_tags
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords",
          "xray:GetSamplingRules",
          "xray:GetSamplingTargets"
        ],
        "Resource" : [
          "*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "mediaconvert_execution" {
  name_prefix = local.iam_naming_prefix
  tags        = local.default_tags
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
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
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:Get*",
          "s3:List*"
        ],
        "Resource" : [
          "arn:aws:s3:::hpchan-poc-video-origin/*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:Put*"
        ],
        "Resource" : [
          "arn:aws:s3:::hpchan-poc-video-output/*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_invoke" {
  # Ref: https://docs.amazonaws.cn/en_us/step-functions/latest/dg/lambda-iam.html
  name_prefix = local.iam_naming_prefix
  tags        = local.default_tags
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : [
          "lambda:InvokeFunction"
        ],
        "Resource" : [
          "arn:aws:lambda:ap-northeast-1:${var.aws_account_id}:function:create-emc-job:*"
        ],
      }
    ]
  })
}

resource "aws_iam_policy" "dynamodb" {
  # Ref: https://docs.amazonaws.cn/en_us/step-functions/latest/dg/lambda-iam.html
  name_prefix = local.iam_naming_prefix
  tags        = local.default_tags
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : [
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
        ],
        "Resource" : [
          "${aws_dynamodb_table.video_encoding_status_tracking.arn}"
        ],
        "Condition" : {
          "ArnLike" : {
            "aws:SourceArn" : "arn:aws:states:ap-northeast-1:${var.aws_account_id}:stateMachine:*"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "add_cloudwatch" {
  role       = aws_iam_role.stepfunctions_emc_encoding_pipeline.name
  policy_arn = aws_iam_policy.cloudwatchlogs_delivery_fullaccess.arn
}

resource "aws_iam_role_policy_attachment" "add_s3" {
  role       = aws_iam_role.stepfunctions_emc_encoding_pipeline.name
  policy_arn = aws_iam_policy.s3listbucket_fullaccess.arn
}

resource "aws_iam_role_policy_attachment" "add_sns" {
  role       = aws_iam_role.stepfunctions_emc_encoding_pipeline.name
  policy_arn = aws_iam_policy.snspublishscoped_access.arn
}

resource "aws_iam_role_policy_attachment" "add_sfn" {
  role       = aws_iam_role.stepfunctions_emc_encoding_pipeline.name
  policy_arn = aws_iam_policy.stepfunctions_start_execution_management_scoped_access.arn
}

resource "aws_iam_role_policy_attachment" "add_xray" {
  role       = aws_iam_role.stepfunctions_emc_encoding_pipeline.name
  policy_arn = aws_iam_policy.xray_access_policy.arn
}

resource "aws_iam_role_policy_attachment" "add_mediaconvert" {
  role       = aws_iam_role.stepfunctions_emc_encoding_pipeline.name
  policy_arn = aws_iam_policy.mediaconvert_execution.arn
}

resource "aws_iam_role_policy_attachment" "add_lamdba" {
  role       = aws_iam_role.stepfunctions_emc_encoding_pipeline.name
  policy_arn = aws_iam_policy.lambda_invoke.arn
}

resource "aws_iam_role_policy_attachment" "add_dynamodb" {
  role       = aws_iam_role.stepfunctions_emc_encoding_pipeline.name
  policy_arn = aws_iam_policy.dynamodb.arn
}


// Slack Messager Role

resource "aws_iam_role" "slackMessager" {
  name = "slack_messager"
  tags = local.default_tags
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "lambda.amazonaws.com"
        },
        "Action" : "sts:AssumeRole",
      }
    ]
  })
}

resource "aws_iam_policy" "slack_messager_cloudwatch_log" {
  name_prefix = "slack_messager"
  tags        = local.default_tags
  policy = jsonencode({
    Version = "2012-10-17",
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
          "arn:aws:logs:ap-northeast-1:${var.aws_account_id}:log-group:/aws/lambda/slackMessager:*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "add_cloudwatch_to_slackMessage" {
  role       = aws_iam_role.slackMessager.name
  policy_arn = aws_iam_policy.slack_messager_cloudwatch_log.arn
}
