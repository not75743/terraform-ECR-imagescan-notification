terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.65.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"
}

variable "mail-address" {
  type = string
}

resource "aws_ecr_repository" "test-repo" {
  name = "test-repo"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_sns_topic" "test-topic" {
  name = "test-topic"
}

resource "aws_sns_topic_policy" "test-topic-policy" {
  arn    = aws_sns_topic.test-topic.arn
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowPublishFromEventBridge",
      "Effect": "Allow",
      "Principal": {
        "Service": "events.amazonaws.com"
      },
      "Action": "sns:Publish",
      "Resource": "${aws_sns_topic.test-topic.arn}"
    }
  ]
}
EOF
}

resource "aws_sns_topic_subscription" "test-subscription" {
  topic_arn = aws_sns_topic.test-topic.arn
  protocol  = "email"
  endpoint  = var.mail-address
}

resource "aws_cloudwatch_event_rule" "test-event-rule" {
  name           = "test-event-rule"
  event_bus_name = "default"

  tags = {
    Name = "test-event-rule"
  }

  event_pattern = <<EOF
  {
  "source": ["aws.inspector2"],
  "detail-type": ["Inspector2 Finding"]
  }
EOF
}

resource "aws_cloudwatch_event_target" "sns" {
  rule = aws_cloudwatch_event_rule.test-event-rule.name
  arn  = aws_sns_topic.test-topic.arn
}