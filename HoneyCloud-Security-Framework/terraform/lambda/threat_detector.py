import json
import boto3

sns = boto3.client('sns')

TOPIC_ARN = "REPLACE_WITH_SNS_TOPIC_ARN"

SUSPICIOUS_COMMANDS = [
    "wget",
    "curl",
    "nc",
    "nmap",
    "cat /etc/passwd",
    "uname -a"
]

def lambda_handler(event, context):

    logs = str(event)

    for cmd in SUSPICIOUS_COMMANDS:
        if cmd in logs:
            sns.publish(
                TopicArn=TOPIC_ARN,
                Subject="Threat Detected",
                Message=f"Suspicious command detected: {cmd}"
            )

    return {
        'statusCode': 200,
        'body': json.dumps('Threat analysis completed')
    }