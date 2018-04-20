if [ ! -f vpc_finished_configured ]; then
touch vpc_finished_configured
aws ec2 create-vpc --cidr-block 10.0.0.0/16 | grep -oE 'vpc-[a-f0-9]+' | tee vpc.txt
aws ec2 create-subnet --vpc-id `cat vpc.txt` --cidr-block 10.0.0.0/28 | grep -oE 'subnet-[a-f0-9]+' | tee subnet-private.txt
aws ec2 create-subnet --vpc-id `cat vpc.txt` --cidr-block 10.0.1.0/28 | grep -oE 'subnet-[a-f0-9]+' | tee subnet-public.txt
aws ec2 create-internet-gateway | grep -oE 'igw-[a-f0-9]+' | tee gateway.txt
aws ec2 attach-internet-gateway --vpc-id `cat vpc.txt` --internet-gateway-id `cat gateway.txt`
aws ec2 create-route-table --vpc-id `cat vpc.txt` | grep -oE 'rtb-[a-f0-9]+' | tee route.txt
aws ec2 create-route --route-table-id `cat route.txt` --destination-cidr-block 0.0.0.0/0 --gateway-id `cat gateway.txt`
aws ec2 describe-route-tables --route-table-id `cat route.txt`
aws ec2 describe-subnets --filters "Name=vpc-id,Values=`cat vpc.txt`" --query 'Subnets[*].{ID:SubnetId,CIDR:CidrBlock}'
aws ec2 associate-route-table  --subnet-id `cat subnet-private.txt`  --route-table-id `cat route.txt`
#aws ec2 modify-subnet-attribute --subnet-id `cat subnet-private.txt` --map-public-ip-on-launch
aws ec2 create-security-group --group-name ssh_`cat studentKey.txt` --description "Security group for SSH access" --vpc-id `cat vpc.txt` | grep -oE 'sg-[a-f0-9]+' | tee security.txt
aws ec2 authorize-security-group-ingress --group-id `cat security.txt` --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id `cat security.txt`  --protocol tcp --port 1-65535 --source-group `cat security.txt`
aws ec2 authorize-security-group-ingress --group-id `cat security.txt`  --protocol udp --port 1-65535 --source-group `cat security.txt`
aws ec2 authorize-security-group-ingress --group-id `cat security.txt`  --protocol icmp --port -1 --source-group `cat security.txt`
#aws ec2 modify-subnet-attribute --subnet-id `cat subnet-private.txt` --no-map-public-ip-on-launch
aws ec2 modify-subnet-attribute --subnet-id `cat subnet-private.txt` --map-public-ip-on-launch
else
echo vpc already configures for `cat studentKey.txt`
fi

#aws ec2 run-instances --image-id `cat imageId.txt` --count 1 --instance-type t2.micro --key-name `cat studentKey.txt` --security-group-ids `cat security.txt` --subnet-id `cat subnet-private.txt` --private-ip-address 10.0.0.5
#aws ec2 run-instances --image-id `cat imageId.txt` --count 1 --instance-type t2.micro --key-name `cat studentKey.txt` --security-group-ids `cat security.txt` --subnet-id `cat subnet-private.txt` --private-ip-address 10.0.0.6
#aws ec2 run-instances --image-id `cat imageId.txt` --count 1 --instance-type t2.micro --key-name `cat studentKey.txt` --security-group-ids `cat security.txt` --subnet-id `cat subnet-private.txt` --private-ip-address 10.0.0.7
#aws ec2 run-instances --image-id `cat imageId.txt` --count 1 --instance-type t2.micro --key-name `cat studentKey.txt` --security-group-ids `cat security.txt` --subnet-id `cat subnet-private.txt` --private-ip-address 10.0.0.8
#aws ec2 modify-subnet-attribute --subnet-id `cat subnet-private.txt` --map-public-ip-on-launch
#aws ec2 run-instances --image-id `cat imageId.txt` --count 1 --instance-type t2.micro --key-name `cat studentKey.txt` --security-group-ids `cat security.txt` --subnet-id `cat subnet-private.txt` --private-ip-address 10.0.0.4
