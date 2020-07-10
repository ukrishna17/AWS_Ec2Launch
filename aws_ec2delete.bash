#instanceId=$(aws ec2 describe-instances \
#--filters Name=tag:Name,Values=testec2 Name=instance-state-code,Values=16 \
#--query 'Reservations[*].Instances[*].{Instance:InstanceId}' \
#--output text)

#aws ec2 terminate-instances --instance-id $instanceId

#aws ec2 delete-key-pair --key-name myvpc-keypair

vpc_id=$(aws ec2 describe-vpcs \
--filters "Name=tag:Name,Values=Test VPC" \
--query Vpcs[*].VpcId \
--output text)

for i in 'aws ec2 describe-internet-gateways --filters 'Name=attachment.vpc-id,Values=$vpc_id' | grep InternetGatewayId'
do 
  aws ec2 delete-internet-gateway --internet-gateway-id=$i
done


#aws ec2 delete-vpc --all-dependencies --vpc-id $vpc_id
