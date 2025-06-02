variable "queue_names" {
  description = "These are the names of the SQS queues I want to spin up."
  type        = list(string)
}

variable "create_roles" {
  description = "Set this to true if you need Terraform to make IAM roles for your policies."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Any tags you want added to all resources can go here."
  type        = map(string)
  default     = {}
}

