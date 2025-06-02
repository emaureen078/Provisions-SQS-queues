# SQS Queue Message Counter

This is a simple Python script for checking how many messages are sitting in your AWS SQS queues—and, if they have dead letter queues (DLQs), how many are stuck there too. It’s handy when you want to keep an eye on your queues or debug issues.

---

## What This Script Does

- **Counts messages** in one or more SQS queues you specify.
- **Automatically finds and counts messages** in each queue’s DLQ (if it has one).
- **Works from the command line** (or you can import it in your own Python code).
- **Optional JSON output** if you want to use the results in other scripts.
- **Python 3.8+ and boto3 1.16+** are required.

---

## Requirements

- Python 3.8 or newer
- `boto3` library (`pip install boto3`)
- AWS credentials set up (via environment variables, AWS config, or IAM role)

---

## How To Use

### From the Command Line

Just run the script and pass in the names of the queues you want to check:

python sqs_queues.py queue-1 queue-2 queue-3

**Example output:**

Queue: queue-1
Messages: 10
Dead Letter Queue: queue-1-dlq
Messages: 2

Queue: queue-2
Messages: 0
Dead Letter Queue: None

If you want the results as JSON (for scripting or automation):
python sqs_queues.py queue-1 queue-2 --json

### As a Module

You can also run it as a module:
python -m sqs_queues queue-1 queue-2


### Import in Your Own Python Code

If you want to use the logic in your own script:

from sqs_queues import count_messages

queues = ["queue-1", "queue-2"]
results = count_messages(queues)
print(results)


The function returns a dictionary like this:

{
"queue-1": {
"messages": 10,
"dead_letter_queue": "queue-1-dlq",
"dlq_messages": 2
},
"queue-2": {
"messages": 0,
"dead_letter_queue": None,
"dlq_messages": None
}
}


---

## Notes

- **Don’t pass DLQ names yourself**—the script figures them out automatically.
- If a queue doesn’t exist or you don’t have permission, you’ll see an error in the terminal.
- Make sure your AWS credentials have permission to access SQS.

---

## Development & Testing

- You can use the `moto` library to mock AWS services for testing.
- Make sure you’re using at least boto3 version 1.16.

---

## License

MIT License

---

**Extra Info:**  
- The script uses boto3 to talk to AWS SQS.
- It looks up the `ApproximateNumberOfMessages` for each queue.
- To find a DLQ, it checks the `RedrivePolicy` attribute and extracts the queue name from the ARN.
- Errors are printed to stderr so they don’t mess up your output.
- Works as a CLI tool, as a Python module, or via `python -m`.
- Use `--json` if you want machine-readable output.
