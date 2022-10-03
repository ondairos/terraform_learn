#Create SNS Topic
resource "aws_sns_topic" "aws_topic"{
    name = "myapp-topic"
}

#SQS Primary service
resource "aws_sqs_queue" "myapp_queue" {
    name = "myapp-updates-queue"
    redrive_policy = "{\"deadLetterTargetArn\":\"${aws_sqs_queue.myapp_dl_queue.arn}\",\"maxReceiveCount\":5}"
    visibility_timeout_seconds = 300

    #change later to variable
    tags = {
        Enviroment = "dev"
    }
}

#SQS dead letter queue
resource "aws_sqs_queue" "myapp_dl_queue" {
    name = "myapp-updates-dl-queue"
}

#SNS Topic subscribe
resource "aws_sns_topic_subscription" "myapp_updates_sqs_target" {
    topic_arn = aws_sns_topic.aws_topic.arn
    protocol = "sqs"
    endpoint = aws_sqs_queue.myapp_queue.arn
}

#SQS Policy
resource "aws_sqs_queue_policy" "myapp_updates_sqs_policy"{
   
  queue_url = aws_sqs_queue.myapp_queue.id

    policy = <<POLICY
    {
    "Version": "2012-10-17",
    "Id": "sqspolicy",
    "Statement": [
        {
        "Sid": "First",
        "Effect": "Allow",
        "Principal": "*",
        "Action": "sqs:SendMessage",
        "Resource": "${aws_sqs_queue.myapp_queue.arn}",
        "Condition": {
            "ArnEquals": {
            "aws:SourceArn": "${aws_sns_topic.aws_topic.arn}"
            }
        }
        }
    ]
    }
    POLICY
}
