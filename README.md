# Provisions-SQS-queues
# sqs_queues Terraform Module

# SQS Queues Terraform Module

This Terraform module helps you set up AWS SQS queues with dead letter queues (DLQs) and the necessary IAM policies for sending and receiving messages. It’s designed to save you time and keep your queue setup consistent and reliable.

---

## Features

- **Creates SQS queues and DLQs:** For every queue you specify, the module automatically creates a matching DLQ (with `-dlq` added to the name).
- **Redrive policy:** Each main queue is linked to its DLQ, so failed messages are handled safely.
- **IAM policies:**  
  - One policy for consuming messages (`sqs:ReceiveMessage`, `sqs:DeleteMessage`) from any queue.
  - Another policy for sending messages (`sqs:SendMessage`) to main queues.
- **Optional IAM roles:** You can have the module create IAM roles and attach the above policies.
- **Outputs:** Exposes ARNs for all queues and any created IAM policies or roles.

---

## Requirements

- **Terraform:** 1.0.0 or newer
- **AWS Provider:** 3.48.0 or newer
- **AWS Credentials:** Make sure your credentials are configured before running this module.

---

## Usage

Here’s a quick example of how to use this module in your Terraform code:

module "sqs_queues" {
source = "./sqs_queues" # Update this path if needed
queue_names = ["priority-10", "priority-100"]

Optional settings:
create_roles = true
tags = {
Environment = "dev"
Project = "myproject"
}
}

text
After you run `terraform apply`, you’ll have your main queues, their DLQs, and all the IAM policies and roles you need (if you opted in).

---

## Inputs

| Name         | Description                                   | Type         | Default | Required |
|--------------|-----------------------------------------------|--------------|---------|----------|
| queue_names  | List of SQS queue names to create             | list(string) | n/a     | yes      |
| create_roles | Whether to create IAM roles for the policies  | bool         | false   | no       |
| tags         | Tags to apply to all created resources        | map(string)  | {}      | no       |

---

## Outputs

| Name               | Description                                                  |
|--------------------|-------------------------------------------------------------|
| queue_arns         | List of ARNs for all created queues (main + DLQs)           |
| consume_policy_arn | ARN of the IAM policy for consuming messages                |
| write_policy_arn   | ARN of the IAM policy for sending messages                  |
| consume_role_arn   | ARN of the IAM role for consuming messages (if created)     |
| write_role_arn     | ARN of the IAM role for sending messages (if created)       |

---

## Notes

- DLQs are created and attached automatically—no extra steps needed.
- IAM roles are only created if you set `create_roles = true`.
- The redrive policy’s `maxReceiveCount` is set to 5 by default.
- Message retention: 4 days for main queues, 14 days for DLQs.

---

## License

MIT License

---

## Packaging Instructions

If you want to package this module and version it with git:

1. Place all module files in a folder named `sqs_queues`.
2. Initialize a git repository inside that folder:

cd sqs_queues
git init
git add .
git commit -m "Initial commit: SQS queues module with DLQs and IAM policies"

3. To create a tarball (including the `.git` folder):
cd ..
tar czvf sqs_queues_module.tar.gz sqs_queues