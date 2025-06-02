# To organize the SQS queues, I started by building a mapping between each main queue and its corresponding dead-letter queue (DLQ). 
locals {
  # Link each main queue to its DLQ by appending '-dlq' to the name
  queues_with_dlq = {
    for queue in var.queue_names :
    queue => "${queue}-dlq"
  }
}
# DLQs,I chose a two-week retention period.
resource "aws_sqs_queue" "dlqs" {
  for_each = local.queues_with_dlq

  name                     = each.value
  message_retention_seconds = 1209600  # 14 days
  tags                     = var.tags
}
# I created the main queues, each with a redrive policy routing unprocessable messages to its DLQ, and set the main queue retention to 4 days for typical scenarios
resource "aws_sqs_queue" "main_queues" {
  for_each = local.queues_with_dlq

  name                     = each.key
  message_retention_seconds = 345600  # 4 days
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlqs[each.key].arn
    maxReceiveCount     = 5
  })
  tags = var.tags

}
#To make permissions easier to manage, I gathered the ARNs for all the queues (both main and DLQs) into a single list:
locals {
  all_queue_arns = concat(
    [for q in aws_sqs_queue.main_queues : q.arn],
    [for q in aws_sqs_queue.dlqs : q.arn]
  )
}

# IAM Policies for first, I created a policy that allows consuming messages from all queues, which includes receiving and deleting messages.
data "aws_iam_policy_document" "consume_policy_doc" {
  statement {
    effect = "Allow"
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage"
    ]
    resources = local.all_queue_arns
  }
}

resource "aws_iam_policy" "consume_policy" {
  name        = "sqs-consume-policy-${substr(join("-", var.queue_names), 0, 50)}"
  description = "Lets you receive and delete messages from all queues created by this module"
  policy      = data.aws_iam_policy_document.consume_policy_doc.json
}
#Second policy allows sending messages to the main queues only. 
data "aws_iam_policy_document" "write_policy_doc" {
  statement {
    effect = "Allow"
    actions = [
      "sqs:SendMessage"
    ]
    resources = [for q in aws_sqs_queue.main_queues : q.arn]
  }
}

resource "aws_iam_policy" "write_policy" {
  name        = "sqs-write-policy-${substr(join("-", var.queue_names), 0, 50)}"
  description = "Allows sending messages to main SQS queues created by this module"
  policy      = data.aws_iam_policy_document.write_policy_doc.json
}

# Conditional IAM Roles
data "aws_caller_identity" "current" {}

resource "aws_iam_role" "consume_role" {
  count = var.create_roles ? 1 : 0

  name = "sqs-consume-role-${substr(join("-", var.queue_names), 0, 50)}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "consume_attach" {
  count      = var.create_roles ? 1 : 0
  role       = aws_iam_role.consume_role[0].name
  policy_arn = aws_iam_policy.consume_policy.arn
}

resource "aws_iam_role" "write_role" {
  count = var.create_roles ? 1 : 0

  name = "sqs-write-role-${substr(join("-", var.queue_names), 0, 50)}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "write_attach" {
  count      = var.create_roles ? 1 : 0
  role       = aws_iam_role.write_role[0].name
  policy_arn = aws_iam_policy.write_policy.arn
}
