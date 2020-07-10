instanceId = $(aws ec2 describe-instances \
--filters Name=tag:Name,Values=testec2 Name=instance-state-code,Values=16 \
--query 'Reservations[*].Instances[*].{Instance:InstanceId}' \
--output text)

aws ec2 delete-instance --instance-id $instanceId

aws ec2 delete-key-pair --key-name myvpc-keypair

vpc_id =$(aws ec2 describe-vpcs \
--filters "Name=tag:Name,Values=Test VPC" \
--query Vpcs[*].VpcId \
--output text)

aws ec2 delete-vpc --vpc-id $vpc_id