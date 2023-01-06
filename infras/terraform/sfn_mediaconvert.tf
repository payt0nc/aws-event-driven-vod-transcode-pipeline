resource "aws_sfn_state_machine" "vod_encoding_mediaconvert_job" {
  name     = "vod-encoding-mediaconvert-job"
  role_arn = aws_iam_role.sfn_emc_encoding_pipeline.arn
  tags     = local.default_tags


  logging_configuration {
    log_destination        = "${aws_cloudwatch_log_group.sfn_vod_pipeline_job.arn}:*"
    include_execution_data = true
    level                  = "ALL"
  }

  definition = jsonencode(
    {
      "StartAt" : "createMediaConvertJob",
      "States" : {
        "Parallel" : {
          "Branches" : [
            {
              "StartAt" : "publishMediaConvertStatus",
              "States" : {
                "publishMediaConvertStatus" : {
                  "End" : true,
                  "Parameters" : {
                    "Message.$" : "$",
                    "TopicArn" : "${aws_sns_topic.pipeline_job_status.arn}"
                  },
                  "Resource" : "arn:aws:states:::sns:publish",
                  "Type" : "Task"
                }
              }
            },
            {
              "StartAt" : "checkMediaConvertStatus",
              "States" : {
                "CreateAsset" : {
                  "Next" : "Parallel (1)",
                  "Parameters" : {
                    "Id.$" : "$.task.id",
                    "PackagingGroupId.$" : "$.task.packagingGroupId",
                    "SourceArn.$" : "$.task.sourceArn",
                    "SourceRoleArn.$" : "$.task.sourceRoleArn"
                  },
                  "Resource" : "arn:aws:states:::aws-sdk:mediapackagevod:createAsset",
                  "Type" : "Task"
                },
                "Parallel (1)" : {
                  "Branches" : [
                    {
                      "StartAt" : "publishMediaPackageStatus",
                      "States" : {
                        "publishMediaPackageStatus" : {
                          "End" : true,
                          "Parameters" : {
                            "Message.$" : "$",
                            "TopicArn" : "${aws_sns_topic.pipeline_job_status.arn}"
                          },
                          "Resource" : "arn:aws:states:::sns:publish",
                          "Type" : "Task"
                        }
                      }
                    },
                    {
                      "StartAt" : "waitForCreateAsset",
                      "States" : {
                        "waitForCreateAsset" : {
                          "Type" : "Wait",
                          "Seconds" : 30,
                          "Next" : "DescribeAsset"
                        },
                        "DescribeAsset" : {
                          "Next" : "Map",
                          "Parameters" : {
                            "Id.$" : "$.Id"
                          },
                          "Resource" : "arn:aws:states:::aws-sdk:mediapackagevod:describeAsset",
                          "Type" : "Task"
                        },
                        "Map" : {
                          "ItemProcessor" : {
                            "ProcessorConfig" : {
                              "Mode" : "INLINE"
                            },
                            "StartAt" : "checkStreamPlayable",
                            "States" : {
                              "Fail" : {
                                "Type" : "Fail"
                              },
                              "Success" : {
                                "Type" : "Succeed"
                              },
                              "checkStreamPlayable" : {
                                "Choices" : [
                                  {
                                    "Variable" : "$.EgressEndpoint.Status",
                                    "StringEquals" : "FAILED",
                                    "Next" : "Fail"
                                  },
                                  {
                                    "Variable" : "$.EgressEndpoint.Status",
                                    "StringEquals" : "PLAYABLE",
                                    "Next" : "publishPlayableStream"
                                  }
                                ],
                                "Default" : "Pass",
                                "Type" : "Choice"
                              },
                              "Pass" : {
                                "Type" : "Pass",
                                "End" : true,
                                "Result" : {
                                  "Id.$" : "$.Id"
                                }
                              },
                              "publishPlayableStream" : {
                                "Next" : "Success",
                                "Parameters" : {
                                  "Message.$" : "$",
                                  "TopicArn" : "${aws_sns_topic.pipeline_job_status.arn}"
                                },
                                "Resource" : "arn:aws:states:::sns:publish",
                                "Type" : "Task"
                              }
                            }
                          },
                          "Next" : "waitForCreateAsset",
                          "Type" : "Map",
                          "ItemSelector" : {
                            "Id.$" : "$.Id",
                            "EgressEndpoint.$" : "$$.Map.Item.Value"
                          },
                          "ItemsPath" : "$.EgressEndpoints"
                        }
                      }
                    }
                  ],
                  "End" : true,
                  "Type" : "Parallel"
                },
                "checkMediaConvertStatus" : {
                  "Choices" : [
                    {
                      "Next" : "CreateAsset",
                      "StringEquals" : "COMPLETE",
                      "Variable" : "$.status"
                    }
                  ],
                  "Default" : "failureOnMediaConvert",
                  "Type" : "Choice"
                },
                "failureOnMediaConvert" : {
                  "Type" : "Fail"
                }
              }
            }
          ],
          "End" : true,
          "Type" : "Parallel"
        },
        "createMediaConvertJob" : {
          "Next" : "Parallel",
          "Parameters" : {
            "FunctionName" : "${aws_lambda_function.create_encoding_job.arn}:$LATEST",
            "Payload" : {
              "sfnName.$" : "$$.Execution.Name",
              "sfnToken.$" : "$$.Task.Token",
              "srcBucket.$" : "$.detail.bucket.name",
              "srcObject.$" : "$.detail.object.key"
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
        }
      }
    }
  )
}

resource "aws_iam_role" "sfn_emc_encoding_pipeline" {
  name = "sfn-emc-encoding-pipeline"

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
  role       = aws_iam_role.sfn_emc_encoding_pipeline.name
  policy_arn = aws_iam_policy.cloudwatchlogs_delivery_fullaccess.arn
}


resource "aws_iam_role_policy_attachment" "add_xray" {
  role       = aws_iam_role.sfn_emc_encoding_pipeline.name
  policy_arn = aws_iam_policy.xray_access_policy.arn
}

resource "aws_iam_role_policy_attachment" "add_lamdba" {
  role       = aws_iam_role.sfn_emc_encoding_pipeline.name
  policy_arn = aws_iam_policy.lambda_invoke.arn
}

resource "aws_iam_role_policy_attachment" "add_sns" {
  role       = aws_iam_role.sfn_emc_encoding_pipeline.name
  policy_arn = aws_iam_policy.sns_publish.arn
}

resource "aws_iam_role_policy_attachment" "add_mediapackage" {
  role       = aws_iam_role.sfn_emc_encoding_pipeline.name
  policy_arn = aws_iam_policy.trigger_mediapackage.arn
}

resource "aws_iam_policy" "cloudwatchlogs_delivery_fullaccess" {
  name_prefix = var.project_prefix
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
  name_prefix = var.project_prefix
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
  name_prefix = var.project_prefix
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
          "${aws_lambda_function.create_encoding_job.arn}:*",
          "${aws_lambda_function.callback_create_encoding_job.arn}:*"
        ],
      }
    ]
  })
}

resource "aws_iam_policy" "sns_publish" {
  name_prefix = var.project_prefix
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

resource "aws_iam_policy" "trigger_mediapackage" {
  name_prefix = var.project_prefix
  tags        = local.default_tags
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : [
          "mediapackage-vod:CreateAsset",
          "mediapackage-vod:DescribeAsset"
        ],
        "Resource" : [
          "*"
        ],
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
              "mediapackage-vod.amazonaws.com"
            ]
          }
        }
      }
    ]
  })
}

resource "aws_iam_role" "mediapackage_segmentor" {
  name = "mediapackage_segmentor"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "mediapackage.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })

}

resource "aws_iam_policy" "mediapackage_access_s3" {
  name_prefix = "mediapackage_segmentor"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "s3:GetObject",
          "s3:GetBucketLocation",
          "s3:GetBucketRequestPayment",
          "s3:ListBucket",
          "s3:PutObject"
        ],
        "Resource" : [
          "${aws_s3_bucket.video_output.arn}/*",
          "${aws_s3_bucket.video_output.arn}",
        ],
        "Effect" : "Allow"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "add_policy" {
  role       = aws_iam_role.mediapackage_segmentor.name
  policy_arn = aws_iam_policy.mediapackage_access_s3.arn
}
