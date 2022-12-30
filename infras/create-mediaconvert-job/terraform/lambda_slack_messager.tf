data "aws_s3_object" "lambda_fucntion_slack_messager_runtime" {
  bucket = var.lambda_fucntion_s3_bucket
  key    = var.lambda_fucntion_s3_slack_messager_runtime
}


resource "aws_lambda_function" "slack_messager" {
  description      = "This lambda function is to create Elemental MediaConvert Job"
  s3_bucket        = var.lambda_fucntion_s3_bucket
  s3_key           = "${var.project_prefix}/slackMessager.zip"
  function_name    = "${var.project_prefix}_slack_messager"
  role             = aws_iam_role.lambda_slack_messager.arn
  handler          = "slackMessager"
  runtime          = "go1.x"
  source_code_hash = data.aws_s3_object.lambda_fucntion_slack_messager_runtime.etag

  environment {
    variables = {
      SLACK_ENDPOINT = ""
    }
  }
}


resource "aws_iam_role" "lambda_slack_messager" {
  name_prefix = "lambda_slack_messager"
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

resource "aws_iam_policy" "lambda_slack_messager_execution" {
  name_prefix = "lambda_slack_messager_execution"
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
        "Action" : "logs:CreateLogGroup",
        "Resource" : "arn:aws:logs:${var.aws_region}:${var.aws_account_id}:*"
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

resource "aws_iam_role_policy_attachment" "attach_lambda_slack_messager_execution" {
  role       = aws_iam_role.lambda_slack_messager.name
  policy_arn = aws_iam_policy.lambda_slack_messager_execution.arn
}
