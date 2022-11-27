import boto3
#Create ec2 snapshots and label them
def lambda_handler(event, context):
    boto3.Session()
    ec2 = boto3.resource('ec2')
    instances = ec2.instances.all()

    #Create snapshots for every instance
    for instance in instances:
            for device in instance.block_device_mappings:
                ec2.create_snapshot(
                        Description='<ENTER YOUR DESCRIPTION>',
                        VolumeId=device.get('Ebs').get('VolumeId'),
                        TagSpecifications=[
                            {
                                'ResourceType': 'snapshot',
                                'Tags': [
                                    {
                                        'Key': 'Name',
                                        'Value': '<ENTER NAME FOR YOUR SNAPSHOTS>'
                                    },
                                ]
                            },
                        ]
                )
