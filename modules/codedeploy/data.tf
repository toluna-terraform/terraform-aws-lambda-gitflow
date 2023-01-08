data "aws_s3_bucket" "codepipeline_bucket" {
  bucket = var.s3_bucket
}
data "aws_iam_policy_document" "codedeploy_role_policy" {
  statement {
    actions = [
      "iam:*",
      "logs:*",
      "apigateway:*",
      "cloudformation:*",
      "s3:*",
      "ec2:*",
      "ssm:*",
      "lambda:*",
      "codedeploy:*",
      "serverlessrepo:*",
      "sqs:*"
    ]
    resources = ["*"]
  }
}
