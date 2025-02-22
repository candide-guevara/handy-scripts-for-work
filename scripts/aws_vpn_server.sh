#!/bin/bash

# AWS CLI configuration variables
INSTANCE_TYPE="t2.micro"
SECURITY_GROUP_NAME="openvpn-sg"
REGION="eu-central-1"
CIDR_BLOCK="192.168.0.0/16"
SUBNET_CIDR="192.168.0.0/24"
WORKSTATION_IP="`curl -s ifconfig.me`"
SSH_KEY_NAME="aws_vpn_ssh_key"
EC2_USER="ec2-user"
VPN_CONFIG_DIR="/etc/openvpn/client"

die_if_not_set() {
  for vv in "$@"; do
    if [[ -z "${!vv}" ]]; then
      echo "ERROR variable '$vv' is not set"
      exit 1
    fi
 done
}

read_ssh_key_pair() {
  die_if_not_set SSH_KEY_NAME REGION
  SSH_KEY_PATH="$HOME/.ssh/${SSH_KEY_NAME}.pem"
  SSH_KEY_ID=$(aws ec2 describe-key-pairs \
    --filters="Name=key-name,Values='$SSH_KEY_NAME'" \
    --output=text --query='KeyPairs[].KeyPairId')
  [[ -z "$SSH_KEY_ID" ]] && return 1
  return 0
}
delete_ssh_key_pair() {
  read_ssh_key_pair || return 0
  die_if_not_set REGION SSH_KEY_ID
  echo "Deleting key pair '$SSH_KEY_ID'..."
  aws ec2 delete-key-pair \
    --key-pair-id "$SSH_KEY_ID" \
    --region "$REGION"
}
create_ssh_key_pair() {
  read_ssh_key_pair && return 0
  die_if_not_set REGION SSH_KEY_PATH SSH_KEY_NAME
  echo "Creating key pair '$SSH_KEY_NAME'..."
  aws ec2 create-key-pair \
    --key-name "$SSH_KEY_NAME" \
    --region "$REGION" \
    --query 'KeyMaterial' \
    --output text > "$SSH_KEY_PATH"
  chmod go-rwx "$SSH_KEY_PATH"
}


read_vpc() {
  die_if_not_set CIDR_BLOCK
  VPC_ID=$(aws ec2 describe-vpcs \
    --filters="Name=cidr-block,Values='$CIDR_BLOCK'" \
    --output=text --query "Vpcs[].VpcId")
  [[ -z "$VPC_ID" ]] && return 1
  IGW_ID=$(aws ec2 describe-internet-gateways \
    --filter="Name=attachment.vpc-id,Values='$VPC_ID'" \
    --output=text --query='InternetGateways[].InternetGatewayId')
  [[ -z "$IGW_ID" ]] && return 1
  return 0
}
delete_vpc() {
  read_vpc || return 0
  die_if_not_set REGION
  echo "Deleting VPC..."
  aws ec2 detach-internet-gateway \
    --internet-gateway-id "$IGW_ID" \
    --vpc-id "$VPC_ID" \
    --region "$REGION"
  aws ec2 delete-internet-gateway \
    --internet-gateway-id "$IGW_ID" \
    --region "$REGION"
  aws ec2 delete-vpc \
    --vpc-id "$VPC_ID" \
    --region "$REGION"
}
create_vpc() {
  read_vpc && return 0
  die_if_not_set CIDR_BLOCK REGION
  echo "Creating VPC..."
  VPC_ID=$(aws ec2 create-vpc \
    --cidr-block "$CIDR_BLOCK" \
    --region "$REGION" \
    --output text --query 'Vpc.VpcId')

  # Enable DNS hostname support
  aws ec2 modify-vpc-attribute \
    --vpc-id "$VPC_ID" \
    --enable-dns-hostnames '{"Value":true}'

  # Create internet gateway
  IGW_ID=$(aws ec2 create-internet-gateway \
    --region "$REGION" \
    --output text --query 'InternetGateway.InternetGatewayId')

  # Attach internet gateway to VPC
  aws ec2 attach-internet-gateway \
    --vpc-id "$VPC_ID" \
    --internet-gateway-id "$IGW_ID"
}


read_vpc_routetable() {
  die_if_not_set VPC_ID REGION
  ROUTE_TABLE_ID=$(aws ec2 describe-route-tables \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --query 'RouteTables[?Associations[0].Main != `true`].RouteTableId' \
    --output text \
    --region "$REGION")
  [[ -z "$ROUTE_TABLE_ID" ]] && return 1
  return 0
}
delete_vpc_routetable() {
  read_vpc_routetable || return 0
  die_if_not_set REGION
  echo "Deleting route table..."
  for RT_ID in $ROUTE_TABLE_ID; do
    aws ec2 delete-route-table \
      --route-table-id "$RT_ID" \
      --region "$REGION"
  done
}
create_vpc_routetable() {
  read_vpc_routetable && return 0
  die_if_not_set VPC_ID REGION IGW_ID
  echo "Creating route table..."
  ROUTE_TABLE_ID=$(aws ec2 create-route-table \
    --vpc-id "$VPC_ID" \
    --region "$REGION" \
    --output text --query 'RouteTable.RouteTableId')

  # Create route to Internet Gateway
  aws ec2 create-route \
    --route-table-id "$ROUTE_TABLE_ID" \
    --destination-cidr-block "0.0.0.0/0" \
    --gateway-id "$IGW_ID"
}


read_vpc_subnet() {
  die_if_not_set VPC_ID REGION
  SUBNET_ID=$(aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --query 'Subnets[*].SubnetId' \
    --output text)
  [[ -z "$SUBNET_ID" ]] && return 1
  return 0
}
delete_vpc_subnet() {
  read_vpc_subnet || return 0
  die_if_not_set REGION
  echo "Deleting subnet..."
  aws ec2 delete-subnet \
    --subnet-id "$SUBNET_ID" \
    --region "$REGION"
}
create_vpc_subnet() {
  read_vpc_subnet && return 0
  die_if_not_set VPC_ID SUBNET_CIDR REGION ROUTE_TABLE_ID
  echo "Creating subnet..."
  SUBNET_ID=$(aws ec2 create-subnet \
    --vpc-id "$VPC_ID" \
    --cidr-block "$SUBNET_CIDR" \
    --region "$REGION" \
    --output text --query 'Subnet.SubnetId')

  # Enable auto-assign public IP on subnet
  aws ec2 modify-subnet-attribute \
    --subnet-id "$SUBNET_ID" \
    --map-public-ip-on-launch

  # Associate route table with subnet
  aws ec2 associate-route-table \
    --subnet-id "$SUBNET_ID" \
    --route-table-id "$ROUTE_TABLE_ID" > /dev/null
}


read_security_group() {
  die_if_not_set VPC_ID SECURITY_GROUP_NAME
  SECURITY_GROUP_ID=$(aws ec2 describe-security-groups \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --query "SecurityGroups[?GroupName==\`$SECURITY_GROUP_NAME\`].GroupId" \
    --output text)
  [[ -z "$SECURITY_GROUP_ID" ]] && return 1
  return 0
}
delete_security_group() {
  read_security_group || return 0
  die_if_not_set REGION
  echo "Deleting security group..."
  aws ec2 delete-security-group \
    --group-id "$SECURITY_GROUP_ID" \
    --region "$REGION"
}
create_security_group() {
 read_security_group && return 0
 die_if_not_set SECURITY_GROUP_NAME VPC_ID WORKSTATION_IP
 echo "Creating security group..."
 SECURITY_GROUP_ID=$(aws ec2 create-security-group \
   --group-name "$SECURITY_GROUP_NAME" \
   --description "Security group for OpenVPN server" \
   --vpc-id "$VPC_ID" \
   --output text --query 'GroupId')

 # Configure security group rules
 aws ec2 authorize-security-group-ingress \
   --group-id "$SECURITY_GROUP_ID" \
   --protocol tcp \
   --port 22 \
   --cidr "${WORKSTATION_IP}/32" > /dev/null

 aws ec2 authorize-security-group-ingress \
   --group-id "$SECURITY_GROUP_ID" \
   --protocol udp \
   --port 1194 \
   --cidr "${WORKSTATION_IP}/32" > /dev/null
}


get_latest_linux_image() {
  AMI_ID=$(aws ec2 describe-images --owners amazon \
    --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" \
    --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
    --output text)
}


read_ec2_instance() {
  die_if_not_set VPC_ID REGION
  INSTANCE_ID=$(aws ec2 describe-instances \
    --filter="Name=vpc-id,Values='$VPC_ID'" \
    --query 'Reservations[].Instances[].InstanceId' \
    --output text \
    --region "$REGION"
  )
  [[ -z "$INSTANCE_ID" ]] && return 1
  return 0
}
delete_ec2_instance() {
  read_ec2_instance || return 0
  die_if_not_set REGION
  echo "Deleting EC2 instance..."
  aws ec2 terminate-instances \
    --instance-ids "$INSTANCE_ID" \
    --region "$REGION"
  aws ec2 wait instance-terminated \
    --instance-ids "$INSTANCE_ID" \
    --region "$REGION"
}
create_ec2_instance() {
  read_ec2_instance && return 0
  die_if_not_set AMI_ID INSTANCE_TYPE SUBNET_ID SECURITY_GROUP_ID SSH_KEY_NAME REGION
  echo "Creating EC2 instance..."
  INSTANCE_ID=$(aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --instance-type "$INSTANCE_TYPE" \
    --key-name "$SSH_KEY_NAME" \
    --subnet-id "$SUBNET_ID" \
    --security-group-ids "$SECURITY_GROUP_ID" \
    --region "$REGION" \
    --user-data '#!/bin/bash
      yum update -y
      yum install -y amazon-linux-extras
      amazon-linux-extras install epel -y
      yum install -y polkit
      systemctl start polkit
      systemctl enable polkit
      yum install -y openvpn easy-rsa
 
      # Initialize PKI
      mkdir /etc/openvpn/easy-rsa
      cp -r /usr/share/easy-rsa/3.0/* /etc/openvpn/easy-rsa/
      cd /etc/openvpn/easy-rsa
 
      # Configure vars
      cat > vars <<EOF
export KEY_COUNTRY="US"
export KEY_PROVINCE="CA"
export KEY_CITY="SanFrancisco"
export KEY_ORG="MyOrganization"
export KEY_EMAIL="admin@example.com"
export KEY_CN="OpenVPN-Server"
export KEY_NAME="server"
export KEY_OU="MyOrganizationalUnit"
EOF
 
      # Initialize PKI and create CA
      ./easyrsa init-pki
      ./easyrsa --batch build-ca nopass
      ./easyrsa build-server-full server nopass
      ./easyrsa gen-dh
      ./easyrsa build-client-full client1 nopass
 
      # Copy certificates to OpenVPN directory
      cp pki/ca.crt /etc/openvpn/
      cp pki/issued/server.crt /etc/openvpn/
      cp pki/private/server.key /etc/openvpn/
      cp pki/dh.pem /etc/openvpn/
 
      cat > /etc/openvpn/server.conf <<EOF
port 1194
proto udp
dev tun
ca ca.crt
cert server.crt
key server.key
dh dh.pem
server 10.8.0.0 255.255.255.0
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 8.8.4.4"
keepalive 10 120
cipher AES-256-CBC
user nobody
group nobody
persist-key
persist-tun
status openvpn-status.log
verb 3
EOF
 
      yum install -y iptables-services
      echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
      sysctl -p
 
      iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE
      iptables -A INPUT -p udp --dport 1194 -j ACCEPT
      iptables -A INPUT -i tun+ -j ACCEPT
      iptables -A FORWARD -i tun+ -j ACCEPT
      iptables -A FORWARD -i tun+ -o eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT
      iptables -A FORWARD -i eth0 -o tun+ -m state --state RELATED,ESTABLISHED -j ACCEPT
      service iptables save
 
      systemctl enable openvpn@server
      systemctl start openvpn@server' \
    --output text --query 'Instances[0].InstanceId')
 
  # Wait for instance to be running
  echo "Waiting for instance to be running..."
  aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"
}


get_instance_ipaddr() {
  die_if_not_set INSTANCE_ID
  INSTANCE_IP=$(aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)
}


read_all() {
  read_vpc
  read_vpc_routetable
  read_vpc_subnet
  read_security_group
  read_ssh_key_pair
  get_latest_linux_image
  read_ec2_instance
  get_instance_ipaddr
  echo "
  INSTANCE_TYPE='$INSTANCE_TYPE'
  SECURITY_GROUP_NAME='$SECURITY_GROUP_NAME'
  REGION='$REGION'
  CIDR_BLOCK='$CIDR_BLOCK'
  SUBNET_CIDR='$SUBNET_CIDR'
  WORKSTATION_IP='$WORKSTATION_IP'
  SSH_KEY_NAME='$SSH_KEY_NAME'
  EC2_USER='$EC2_USER'
  VPN_CONFIG_DIR='$VPN_CONFIG_DIR'
  VPC_ID='$VPC_ID'
  IGW_ID='$IGW_ID'
  ROUTE_TABLE_ID='$ROUTE_TABLE_ID'
  SUBNET_ID='$SUBNET_ID'
  SECURITY_GROUP_ID='$SECURITY_GROUP_ID'
  AMI_ID='$AMI_ID'
  SSH_KEY_ID='$SSH_KEY_ID'
  INSTANCE_ID='$INSTANCE_ID'
  INSTANCE_IP='$INSTANCE_IP'

  ssh -i '$SSH_KEY_PATH' ${EC2_USER}@$INSTANCE_IP
  "
}
delete_all() {
  read_vpc
  delete_ec2_instance
  delete_ssh_key_pair
  delete_security_group
  delete_vpc_subnet
  delete_vpc_routetable
  delete_vpc
}
create_all() {
  create_vpc
  create_vpc_routetable
  create_vpc_subnet
  create_security_group
  create_ssh_key_pair
  get_latest_linux_image
  create_ec2_instance
}

###################### MAIN ###########################################
#read_all
#create_all
delete_all

