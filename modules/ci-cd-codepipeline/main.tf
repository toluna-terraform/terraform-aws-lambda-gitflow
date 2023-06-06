locals {
  codepipeline_name = "codepipeline-${var.app_name}-${var.env_name}"
}

resource "aws_codepipeline" "codepipeline" {
  name     = local.codepipeline_name
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = var.s3_bucket
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name             = "Download_Merged_Sources"
      category         = "Source"
      owner            = "AWS"
      provider         = "S3"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        S3Bucket             = "${var.s3_bucket}"
        S3ObjectKey          = "${var.env_name}/source_artifacts.zip"
        PollForSourceChanges = false
      }
    }
  }


  stage {
    name = "CI"
    dynamic "action" {
      for_each = var.build_codebuild_projects
      content {
        name             = action.value
        category         = "Build"
        owner            = "AWS"
        provider         = "CodeBuild"
        input_artifacts  = ["source_output"]
        version          = "1"
        output_artifacts = ["ci_output"]

        configuration = {
          ProjectName = action.value
        }

      }

    }
  }


  stage {
    name = "Pre-Deploy"
    dynamic "action" {
      for_each = toset(var.function_list)
      content {
        name             = action.value.function_name
        category         = "Build"
        owner            = "AWS"
        provider         = "CodeBuild"
        input_artifacts  = ["ci_output"]
        version          = "1"
        output_artifacts = var.pipeline_type == "dev" ? ["dev_${action.value.function_name}_output"] : ["cd_${action.value.function_name}_output"]

        configuration = {
          ProjectName = "codebuild-pre-${var.app_name}-${var.env_name}"
          EnvironmentVariables = jsonencode(
            [
              {
                name  = "FUNCTION_NAME"
                type  = "PLAINTEXT"
                value = "${action.value.function_name}"
              }
            ]
          )
        }

      }

    }
  }

  stage {
    name = "Deploy"
    dynamic "action" {
      for_each = toset(var.function_list)
      content {
        name            = action.value.function_name
        category        = "Deploy"
        owner           = "AWS"
        provider        = "CodeDeploy"
        input_artifacts = var.pipeline_type == "dev" ? ["dev_${action.value.function_name}_output"] : ["cd_${action.value.function_name}_output"]
        version         = "1"
        configuration = {
          ApplicationName     = "lambda-deploy-${var.app_name}-${var.env_name}"
          DeploymentGroupName = "lambda-deploy-group-${action.value.function_name}-${var.env_name}"
        }
      }
    }
  }

  stage {
    name = "Post-Deploy"
    dynamic "action" {
      for_each = var.post_codebuild_projects
      content {
        name            = action.value
        category        = "Build"
        owner           = "AWS"
        provider        = "CodeBuild"
        input_artifacts = ["source_output"]
        version         = "1"

        configuration = {
          ProjectName = action.value
        }

      }

    }
  }

}

resource "aws_iam_role" "codepipeline_role" {
  name               = "role-${local.codepipeline_name}"
  assume_role_policy = data.aws_iam_policy_document.codepipeline_assume_role_policy.json
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name   = "policy-${local.codepipeline_name}"
  role   = aws_iam_role.codepipeline_role.id
  policy = data.aws_iam_policy_document.codepipeline_role_policy.json
}

resource "aws_cloudwatch_event_rule" "trigger_pipeline" {
  name        = "${local.codepipeline_name}-trigger"
  description = "Trigger ${local.codepipeline_name}"

  event_pattern = jsonencode({
    "source" : ["aws.s3"],
    "detail-type" : ["AWS API Call via CloudTrail"],
    "detail" : {
      "eventSource" : ["s3.amazonaws.com"],
      "eventName" : ["PutObject", "CompleteMultipartUpload", "CopyObject"],
      "requestParameters" : {
        "bucketName" : ["${var.s3_bucket}"],
        "key" : ["${var.env_name}/source_artifacts.zip"]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "trigger_pipeline" {
  rule      = aws_cloudwatch_event_rule.trigger_pipeline.name
  target_id = "${local.codepipeline_name}"
  arn       = aws_codepipeline.codepipeline.arn
  role_arn = aws_iam_role.codepipeline_role.arn
}

resource "aws_cloudwatch_log_group" "trigger_pipeline" {
  name = aws_cloudwatch_event_rule.trigger_pipeline.name
  retention_in_days = 3
}

resource "aws_cloudtrail" "trigger_pipeline" {
  name = "${local.codepipeline_name}-cloud-trail"
  s3_bucket_name = "${var.s3_bucket}"
  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.trigger_pipeline.arn}:*"
  event_selector {
    read_write_type           = "WriteOnly"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::${var.s3_bucket}/${var.env_name}/source_artifacts.zip"]
    }
  }
}