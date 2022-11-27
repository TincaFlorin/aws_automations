import boto3
from datetime import datetime, timedelta, timezone

def lambda_handler(event, context):
    aws_console = boto3.Session()
    ec2 = aws_console.resource('ec2')
    
    #Filter snapshots by "<NAME OF YOUR SNAPSHOTS" name
    snapshots = ec2.snapshots.filter(Filters=[
            {
                'Name': 'tag:Name',
                'Values': [
                    '<NAME OF YOUR SNAPSHOTS>',
                ]
            },
        ],)
    #Or get all snapshots
    # snapshots = ec2.describe_snapshots()

    #Delete snapshots older than 15 days that have the name tag value: <NAME OF YOUR SNAPSHOTS>
    old_snapshots = datetime.now(timezone.utc) - timedelta(days=15)
    print(old_snapshots)
    for snapshot in snapshots:
        if (old_snapshots > snapshot.start_time) and (snapshot.tags[0]['Value'] == '<NAME OF YOUR SNAPSHOTS>'):
            print(snapshot.delete())
