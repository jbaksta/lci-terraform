#!/bin/bash

# Which Student
student="student99"

# Image ID
IMG='ami-f2b8d18a'

if [ ! -d  $student ];
then
	echo "Make the student directory first!" 1>&2
	exit 1
else
	cd $student
fi

if [ ! -f vpc_finished_configured ]; then
	touch vpc_finished_configured

	aws ec2 create-vpc \
		--cidr-block 10.0.0.0/28 \
		| jq -r '.Vpc.VpcId' \
		| tee vpc.txt

	aws ec2 create-tags \
		--resources $(cat vpc.txt) \
		--tags Key=Name,Value=${student}-vpc
	
	aws ec2 create-subnet \
		--vpc-id $(cat vpc.txt) \
		--cidr-block 10.0.0.0/28 \
		| grep -oE 'subnet-[a-f0-9]+' \
		| tee subnet-private.txt
	
	aws ec2 create-internet-gateway \
		| grep -oE 'igw-[a-f0-9]+' \
		| tee gateway.txt
	
	aws ec2 attach-internet-gateway \
		--vpc-id $(cat vpc.txt) \
		--internet-gateway-id $(cat gateway.txt)
	
	aws ec2 create-route-table \
		--vpc-id $(cat vpc.txt) \
		| grep -oE 'rtb-[a-f0-9]+' \
		| tee route.txt
	
	aws ec2 create-route \
		--route-table-id $(cat route.txt) \
		--destination-cidr-block 0.0.0.0/0 \
		--gateway-id $(cat gateway.txt)
	
	aws ec2 describe-route-tables \
		--route-table-id $(cat route.txt)
	
	aws ec2 describe-subnets \
		--filters "Name=vpc-id,Values=$(cat vpc.txt)" \
		--query 'Subnets[*].{ID:SubnetId,CIDR:CidrBlock}'
	
	aws ec2 associate-route-table  \
		--route-table-id $(cat route.txt) \
		--subnet-id $(cat subnet-private.txt)
	
	#aws ec2 modify-subnet-attribute --subnet-id $(cat subnet-private.txt) --map-public-ip-on-launch
	
	aws ec2 create-security-group \
		--group-name ssh_${student} \
		--description "Security group for SSH access" \
		--vpc-id $(cat vpc.txt) \
		| grep -oE 'sg-[a-f0-9]+' \
		| tee ssh_sg.txt
	
	aws ec2 authorize-security-group-ingress \
		--group-id $(cat ssh_sg.txt) \
		--protocol tcp \
		--port 22 \
		--cidr 0.0.0.0/0

	aws ec2 create-security-group \
		--group-name ${student}_private \
		--description "Backend Private Network" \
		--vpc-id $(cat vpc.txt) \
		| grep -oE 'sg-[1-f0-9]+' \
		| tee backend_sg.txt
	
	aws ec2 authorize-security-group-ingress \
		--group-id $(cat backend_sg.txt)  \
		--protocol tcp \
		--port 1-65535 \
		--source-group $(cat backend_sg.txt)
	
	aws ec2 authorize-security-group-ingress \
		--group-id $(cat backend_sg.txt)  \
		--protocol udp \
		--port 1-65535 \
		--source-group $(cat backend_sg.txt)
	
	aws ec2 authorize-security-group-ingress \
		--group-id $(cat backend_sg.txt) \
		--protocol icmp \
		--port -1 \
		--source-group $(cat backend_sg.txt)
	
	#aws ec2 modify-subnet-attribute --subnet-id $(cat subnet-private.txt) --no-map-public-ip-on-launch
	
	aws ec2 modify-subnet-attribute \
		--subnet-id $(cat subnet-private.txt) \
		--map-public-ip-on-launch

	# Head Node
	aws ec2 run-instances \
		--image-id ${IMG} \
		--count 1 \
		--instance-type t2.micro \
		--key-name $student \
		--security-group-ids $(cat backend_sg.txt) $(cat ssh_sg.txt) \
		--subnet-id $(cat subnet-private.txt) \
		--private-ip-address 10.0.0.4
	
	# Cluster Nodes
	for i in {5..8}
	do

	aws ec2 run-instances \
		--image-id ${IMG} \
		--count 1 \
		--instance-type t2.micro \
		--key-name $student \
		--security-group-ids $(cat backend_sg.txt) \
		--subnet-id $(cat subnet-private.txt) \
		--private-ip-address 10.0.0.$i
	done

else
	echo vpc already configures for $(cat studentKey.txt)
fi
cd -
