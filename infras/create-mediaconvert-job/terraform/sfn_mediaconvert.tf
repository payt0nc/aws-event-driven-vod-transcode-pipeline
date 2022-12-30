resource "aws_sfn_state_machine" "vod_encoding_mediaconvert_job" {
  name     = "vod-encoding-mediaconvert-job"
  role_arn = aws_iam_role.stepfunctions_emc_encoding_pipeline.arn
  tags     = local.default_tags


  logging_configuration {
    log_destination        = "${aws_cloudwatch_log_group.sfn_vod_encoding_mediaconvert_job.arn}:*"
    include_execution_data = true
    level                  = "ALL"
  }

  definition = jsonencode(
    {
      "Comment" : "- createMediaConvertJob is an async step. It's need to be resume by external eventbridge to trigger.",
      "StartAt" : "createMediaConvertJob",
      "States" : {
        "createMediaConvertJob" : {
          "Next" : "Parallel",
          "Parameters" : {
            "FunctionName" : "${aws_lambda_function.create_emc_job.arn}:$LATEST",
            "Payload" : {
              "sfnInfo" : {
                "token.$" : "$$.Task.Token"
              },
              "task" : {
                "bucket.$" : "$.detail.bucket.name",
                "object.$" : "$.detail.object.key"
              }
            }
          },
          "Resource" : "arn:aws:states:::lambda:invoke.waitForTaskToken",
          "Retry" : [
            {
              "BackoffRate" : 2,
              "ErrorEquals" : [
                "Lambda.ServiceException",
                "Lambda.AWSLambdaException",
                "Lambda.SdkClientException",
                "Lambda.TooManyRequestsException"
              ],
              "IntervalSeconds" : 2,
              "MaxAttempts" : 6
            }
          ],
          "Type" : "Task"
        },
        "Parallel" : {
          "Type" : "Parallel",
          "Branches" : [
            {
              "StartAt" : "publishMediaConvertStatus",
              "States" : {
                "publishMediaConvertStatus" : {
                  "Type" : "Task",
                  "Resource" : "arn:aws:states:::sns:publish",
                  "Parameters" : {
                    "Message.$" : "$",
                    "TopicArn" : "${aws_sns_topic.pipeline_job_status.arn}"
                  },
                  "End" : true
                }
              }
            },
            {
              "StartAt" : "checkMediaConvertStatus",
              "States" : {
                "checkMediaConvertStatus" : {
                  "Type" : "Choice",
                  "Choices" : [
                    {
                      "Variable" : "$.status",
                      "StringEquals" : "COMPLETE",
                      "Next" : "Success"
                    }
                  ],
                  "Default" : "Fail"
                },
                "Success" : {
                  "Type" : "Succeed"
                },
                "Fail" : {
                  "Type" : "Fail"
                }
              }
            }
          ],
          "End" : true
        }
      }
    }
  )
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
            "aws:SourceArn" : "arn:aws:states:${var.aws_region}:${var.aws_account_id}:stateMachine:*"
          }
        }
      }
    ]
  })

  tags = local.default_tags
}

resource "aws_iam_role_policy_attachment" "add_cloudwatch" {
  role       = aws_iam_role.stepfunctions_emc_encoding_pipeline.name
  policy_arn = aws_iam_policy.cloudwatchlogs_delivery_fullaccess.arn
}


resource "aws_iam_role_policy_attachment" "add_xray" {
  role       = aws_iam_role.stepfunctions_emc_encoding_pipeline.name
  policy_arn = aws_iam_policy.xray_access_policy.arn
}

resource "aws_iam_role_policy_attachment" "add_lamdba" {
  role       = aws_iam_role.stepfunctions_emc_encoding_pipeline.name
  policy_arn = aws_iam_policy.lambda_invoke.arn
}

resource "aws_iam_role_policy_attachment" "add_sns" {
  role       = aws_iam_role.stepfunctions_emc_encoding_pipeline.name
  policy_arn = aws_iam_policy.sns_publish.arn
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
          "${aws_lambda_function.create_emc_job.arn}:*"
        ],
      }
    ]
  })
}

resource "aws_iam_policy" "sns_publish" {
  # Ref: https://docs.amazonaws.cn/en_us/step-functions/latest/dg/lambda-iam.html
  name_prefix = local.iam_naming_prefix
  tags        = local.default_tags
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : [
          "SNS:Publish"
        ],
        "Resource" : [
          "${aws_sns_topic.pipeline_job_status.arn}"
        ],
      }
    ]
  })
}
