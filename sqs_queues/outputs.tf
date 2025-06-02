output "queue_arns" {
  description = "All the ARNs for the queues I just created (main queues and their DLQs)."
  value       = local.all_queue_arns
}

output "consume_policy_arn" {
  description = "This is the ARN for the IAM policy that lets you receive and delete messages from any of the queues."
  value       = aws_iam_policy.consume_policy.arn
}

output "write_policy_arn" {
  description = "Here’s the ARN for the policy that allows sending messages to the main queues."
  value       = aws_iam_policy.write_policy.arn
}

output "consume_role_arn" {
  description = "If I ended up creating a role for consuming messages, this will be its ARN. Otherwise, it’s just blank."
  value       = var.create_roles ? aws_iam_role.consume_role[0].arn : ""
  condition   = var.create_roles
}

output "write_role_arn" {
  description = "Same idea as above, but for the role that can send messages. You’ll only see a value here if roles were created."
  value       = var.create_roles ? aws_iam_role.write_role[0].arn : ""
  condition   = var.create_roles
}
