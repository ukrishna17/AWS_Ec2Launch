#!/bin/bash
# create-aws-vpc
# variables used in script:

availabilityZone1="us-east-1a"
name="Test"
vpcName="$name VPC"
PubsubnetName="$name PubSubnet"
PrisubnetName="$name PriSubnet"
gatewayName="$name Gateway"
routeTableName="$name Route Table"
securityGroupName="$name VPC_SG"

vpcCidrBlock="10.0.0.0/16"

PubsubNet="10.0.1.0/24"
PrisubNet="10.0.2.0/24"

port22CidrBlock="0.0.0.0/0"
destinationCidrBlock="0.0.0.0/0"

echo "Creating VPC..."

#create vpc with cidr block /16
vpcId=$(aws ec2 create-vpc \
 --cidr-block "$vpcCidrBlock" \
 --query 'Vpc.{VpcId:VpcId}' \
 --output text)

#name the vpc
aws ec2 create-tags \
  --resources "$vpcId" \
  --tags Key=Name,Value="$vpcName"

#add dns support
modify_response=$(aws ec2 modify-vpc-attribute \
 --vpc-id "$vpcId" \
 --enable-dns-support "{\"Value\":true}")

#add dns hostnames
modify_response=$(aws ec2 modify-vpc-attribute \
  --vpc-id "$vpcId" \
  --enable-dns-hostnames "{\"Value\":true}")

#create Public subnet for vpc with /24 cidr block
PubsubnetId=$(aws ec2 create-subnet \
 --cidr-block "$PubsubNet" \
 --availability-zone "$availabilityZone1" \
 --vpc-id "$vpcId" \
 --query 'Subnet.{SubnetId:SubnetId}' \
 --output text)

#name the subnet
aws ec2 create-tags \
  --resources "$PubsubnetId" \
  --tags Key=Name,Value="$PubsubnetName"

#enable public ip on public subnet
modify_response=$(aws ec2 modify-subnet-attribute \
 --subnet-id "$PubsubnetId" \
 --map-public-ip-on-launch)

#create Private subnet for vpc with /24 cidr block
PrisubnetId=$(aws ec2 create-subnet \
 --cidr-block "$PrisubNet" \
 --availability-zone "$availabilityZone1" \
 --vpc-id "$vpcId" \
 --query 'Subnet.{SubnetId:SubnetId}' \
 --output text)

#name the subnet
aws ec2 create-tags \
  --resources "$PrisubnetId" \
  --tags Key=Name,Value="$PrisubnetName"

#enable public ip on private subnet
modify_response=$(aws ec2 modify-subnet-attribute \
 --subnet-id "$PrisubnetId" \
 --map-public-ip-on-launch)

#create internet gateway
gatewayId=$(aws ec2 create-internet-gateway \
 --query 'InternetGateway.{InternetGatewayId:InternetGatewayId}' \
 --output text)

#name the internet gateway
aws ec2 create-tags \
  --resources "$gatewayId" \
  --tags Key=Name,Value="$gatewayName"

#attach gateway to vpc
attach_response=$(aws ec2 attach-internet-gateway \
 --internet-gateway-id "$gatewayId"  \
 --vpc-id "$vpcId")

#create route table for vpc
routeTableId=$(aws ec2 create-route-table \
 --vpc-id "$vpcId" \
 --query 'RouteTable.{RouteTableId:RouteTableId}' \
 --output text)

#name the route table
aws ec2 create-tags \
  --resources "$routeTableId" \
  --tags Key=Name,Value="$routeTableName"

#add route for the internet gateway
route_response=$(aws ec2 create-route \
 --route-table-id "$routeTableId" \
 --destination-cidr-block "$destinationCidrBlock" \
 --gateway-id "$gatewayId")

#create route table asscoation for vpc
route_table_response=$(aws ec2 associate-route-table \
 --subnet-id "$PubsubnetId" \
 --route-table-id "$routeTableId" \
 --output text)

groupId=$(aws ec2 create-security-group \
--vpc-id $vpcId \
--group-name "$securityGroupName" \
--description 'Test VPC non default security group' \
--output text)

#groupId=$(aws ec2 describe-security-groups \
#--filters "Name=vpc-id,Values=$vpcid" \
#--group-name "myvpc-SG" \
#--query SecurityGroups[0].GroupId \
#--output text)

aws ec2 create-tags \
--resources $groupId \
--tags "Key=Name,Value=testvpc_sg"

aws ec2 authorize-security-group-ingress \
--group-id $groupId \
--ip-permissions IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges='[{CidrIp=0.0.0.0/0,Description="Allow SSH"}]' &&
aws ec2 authorize-security-group-ingress \
--group-id $groupId \
--ip-permissions IpProtocol=tcp,FromPort=80,ToPort=80,IpRanges='[{CidrIp=0.0.0.0/0,Description="Allow SSH"}]'

aws ec2 create-key-pair \
--key-name myvpc-keypair \
--query 'KeyMaterial' \
--output text > myvpc-keypair.pem

instanceId=$(aws ec2 run-instances \
        --image-id ami-0ac80df6eff0e70b5 \
        --region us-east-1 \
        --count 1 \
        --instance-type t2.micro \
        --key-name myvpc-keypair \
        --security-group-ids $groupId \
        --subnet-id $PubsubnetId \
        --user-data file://launchwebsite.sh \
        --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=testec2}]' \
        --query 'Instances[0].InstanceId')

echo "Instance created is $instanceId"

# end of create-aws-vpc
