#!/usr/bin/env python3
import sys
import boto3
import botocore
import argparse
import json

def fetch_queue_url(client, name):
    """Get the URL for a given SQS queue name."""
    try:
        return client.get_queue_url(QueueName=name)['QueueUrl']
    except botocore.exceptions.ClientError as err:
        print(f"Couldn’t get URL for queue '{name}': {err.response['Error']['Message']}", file=sys.stderr)
        return None

def fetch_queue_attrs(client, url, attrs):
    """Grab specific attributes for a queue by URL."""
    try:
        resp = client.get_queue_attributes(QueueUrl=url, AttributeNames=attrs)
        return resp.get('Attributes', {})
    except botocore.exceptions.ClientError as err:
        print(f"Couldn’t get attributes for queue '{url}': {err.response['Error']['Message']}", file=sys.stderr)
        return None

def find_dlq_name(client, url):
    """Figure out if a queue has a DLQ, and return its name if it does."""
    attrs = fetch_queue_attrs(client, url, ['RedrivePolicy'])
    if not attrs or 'RedrivePolicy' not in attrs:
        return None
    try:
        policy = json.loads(attrs['RedrivePolicy'])
        arn = policy.get('deadLetterTargetArn')
        if not arn:
            return None
        # ARN format: arn:aws:sqs:region:account:queue_name
        return arn.split(':')[-1]
    except Exception as err:
        print(f"Couldn’t parse RedrivePolicy for '{url}': {err}", file=sys.stderr)
        return None

def get_queue_counts(queue_names, as_json=False):
    """
    For each queue, show how many messages are waiting, and do the same for its DLQ if it has one.
    """
    client = boto3.client('sqs')
    summary = {}

    for name in queue_names:
        url = fetch_queue_url(client, name)
        if not url:
            continue  # Error already printed

        attrs = fetch_queue_attrs(client, url, ['ApproximateNumberOfMessages'])
        if not attrs:
            continue

        main_count = int(attrs.get('ApproximateNumberOfMessages', 0))
        dlq_name = find_dlq_name(client, url)
        dlq_count = None

        if dlq_name:
            dlq_url = fetch_queue_url(client, dlq_name)
            if dlq_url:
                dlq_attrs = fetch_queue_attrs(client, dlq_url, ['ApproximateNumberOfMessages'])
                if dlq_attrs:
                    dlq_count = int(dlq_attrs.get('ApproximateNumberOfMessages', 0))

        summary[name] = {
            "messages": main_count,
            "dead_letter_queue": dlq_name,
            "dlq_messages": dlq_count
        }

    if as_json:
        print(json.dumps(summary, indent=2))
    return summary

def main():
    parser = argparse.ArgumentParser(
        description="Show how many messages are in your SQS queues and their DLQs."
    )
    parser.add_argument('queues', nargs='+', help='Names of SQS queues to check')
    parser.add_argument('--json', action='store_true', help='Print results as JSON')

    args = parser.parse_args()
    results = get_queue_counts(args.queues, as_json=args.json)

    if not args.json:
        for q, info in results.items():
            print(f"Queue: {q}")
            print(f"  Messages: {info['messages']}")
            if info['dead_letter_queue']:
                print(f"  Dead Letter Queue: {info['dead_letter_queue']}")
                print(f"    Messages: {info['dlq_messages']}")
            else:
                print("  Dead Letter Queue: None")
            print()

if __name__ == '__main__':
    main()
