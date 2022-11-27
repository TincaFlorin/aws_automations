#!/bin/bash
#This script needs a EC2 IAM-ROLE for EC2 read and write access

# --tag-specifications 'ResourceType=snapshot,Tags=[{Key=Name,Value=PeriodicSnapshot}]'
#Create snapshot
createSnapshot() {
    aws ec2 create-snapshots --region ${region} --description ${current_snapshot_description} --instance-specification InstanceId=${instance_id},ExcludeBootVolume=false;
}

#Set counter file
counterfile=/root/.requiredfiles/counterfile
if [[ -f "${counterfile}" ]]; then
    echo "${counterfile} exists!" 
else
    mkdir /root/.requiredfiles
    echo "1" > $counterfile
fi

#Create snapshots file
snapshotFile=/root/.requiredfiles/snapshots
if [[ -f "${snapshotFile}" ]]; then
    echo "${snapshotFile} exists!" 
else
    touch ${snapshotFile}
fi


#Set counter
backup_counter=$(cat ${counterfile})
#Set hostname
hostname=$(hostname)

#Get current instance id and store it in a variable then wait 1 second
instance_id=$(curl http://169.254.169.254/1.0/meta-data/instance-id)
sleep 1

#Get and set instance name
instance_name=$(aws ec2 describe-instances --region eu-west-3 --filters Name=instance-id,Values=${instance_id} --query 'Reservations[*].Instances[*].{Name:Tags[?Key==`Name`]|[0].Value}' --output text)


#Get current region and store it in a variable then wait 1 second
region=$(curl http://169.254.169.254/2022-09-24/meta-data/placement/region)
sleep 1


#Format snapshot name from "OPS-20009" ticket +  current date and time
current_date=$(date -u +%d.%m.%y -u)
current_time=$(date -u +%H:%M)
current_snapshot_description=${instance_name}-$current_date-$current_time-UTC

#Record snapshot name in snapshotFile
#If file has snapshotFile row number is smaller than backup_counter append a backup descruption to file
if [[ $(cat ${snapshotFile}| wc -l) -lt $backup_counter ]]
then
    echo $current_snapshot_description >> $snapshotFile
    #Create snapshot 
    createSnapshot
else
    #Else replace the old snapshot with the new one in in snapshotFile
    old_snapshot_description_at_current_counter=$(sed -n "${backup_counter}p" ${snapshotFile})
    sed -i "s/${old_snapshot_description_at_current_counter}/${current_snapshot_description}/g" $snapshotFile
    #Create snapshot
    createSnapshot
    #Delete old snapshots
    for old_snapshot_id in $(aws ec2 describe-snapshots --region ${region} --output text --filters Name=description,Values=${old_snapshot_description_at_current_counter} | awk '{print $6}')
    do
        aws ec2 delete-snapshot --region ${region} --snapshot-id $old_snapshot_id
    done
fi

#Increment counter
backup_counter=$((backup_counter+1))
echo $backup_counter > ${counterfile}

#Reset counter if value is grater than 3
if [[ $(cat ${counterfile}) -gt 3 ]]; 
then
echo "1" > ${counterfile}
fi

