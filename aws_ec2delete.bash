#!/bin/bash
instanceId=$(aws ec2 describe-instances \
--filters Name=tag:Name,Values=testec2 Name=instance-state-code,Values=16 \
--query 'Reservations[*].Instances[*].{Instance:InstanceId}' \
--output text)

aws ec2 terminate-instances --instance-id $instanceId

aws ec2 delete-key-pair --key-name myvpc-keypair

vpc_id=$(aws ec2 describe-vpcs \
--filters "Name=tag:Name,Values=Test VPC" \
--query Vpcs[*].VpcId \
--output text)

SG1=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$vpc_id" --query SecurityGroups[0].GroupId --output text)
SG2=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$vpc_id" --query SecurityGroups[1].GroupId --output text)

aws ec2 delete-security-group --group-id $SG1
aws ec2 delete-security-group --group-id $SG2


subnet1=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$vpc_id" --query Subnets[0].SubnetId --output text)
subnet2=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$vpc_id" --query Subnets[1].SubnetId --output text)

aws ec2 delete-subnet --subnet-id $subnet1
aws ec2 delete-subnet --subnet-id $subnet2

routetable1=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$vpc_id" --query RouteTables[0].RouteTableId --output text)
routetable2=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$vpc_id" --query RouteTables[1].RouteTableId --output text)

aws ec2 delete-route-table --route-table-id $routetable1
aws ec2 delete-route-table --route-table-id $routetable2


internetgateway=$(aws ec2 describe-internet-gateways \
--filters "Name=attachment.vpc-id,Values=$vpc_id" \
--query InternetGateways[*].InternetGatewayId \
--output text)

aws ec2 detach-internet-gateway --internet-gateway-id $internetgateway --vpc-id $vpc_id
aws ec2 delete-internet-gateway --internet-gateway-id $internetgateway

aws ec2 delete-vpc --vpc-id $vpc_id



#aws ec2 delete-vpc --all-dependencies --vpc-id $vpc_id
