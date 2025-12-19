#! /bin/bash


AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-08671a7014cce6627"
ZONE_ID="Z0883062RHMIRSI7AY3N"
DOMAIN_NAME="dawsdevops86.fun"
for instance in $@ # mongodb redis mysql
do
    INSTANCE_ID=$(aws ec2 run-instances --image-id $AMI_ID --instance-type t3.micro --security-group-ids $SG_ID --tag-specifications "ResourceType=instance,Tags=[{key-Name,Value=$instance}]" --query 'Instances[0].InstanceId' --output text)


     # Get Private IP 
     if [ $instance != "frontend" ];then
         IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].privateIPAddress' --output text)
         RECORD_NAME="$instance.$DOMAIN_NAME" # mongodb.dawsdevops86.fun

     else
         IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instance[0].publicIPAddress' --output text)
         RECORD_NAME= "$instance.$DOMAIN_NAME" # dawsdevops86.fun

     fi

     echo "$instance:$IP"
         

    aws route53 change-resource-record-sets \
  --hosted-zone-id $ZONE_ID \
  --change-batch '
  {
    "Comment": "updating record set"
    ,"Changes": [{
      "Action"              : "UPSERT"
      ,"ResourceRecordSet"  : {
        "Name"              : "'$RECORD_NAME'"
        ,"Type"             : "A"
        ,"TTL"              : 1
        ,"ResourceRecords"  : [{
            "Value"         : "'$IP'"
        }]
      }
    }]
  }
  '
done