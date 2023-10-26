#!/bin/bash

# Function to prompt the user for input
prompt() {
  read -p "$1: " value
  echo "$value"
}

# Function to list example EC2 instance types
list_example_instance_types() {
  echo "Example EC2 instance types:"
  echo "1. t2.micro"
  echo "2. t2.small"
  echo "3. m5.large"
  echo "4. c5.xlarge"
  echo "5. Custom (Enter your own instance type)"
}

# Step 1: List AWS regions and prompt the user for region selection
clear
echo "Select the region to create the EC2 instance:"
aws ec2 describe-regions --query "Regions[].{Name:RegionName}" --output text | nl
selected_region_number=$(prompt "Enter the region number")
selected_region=$(aws ec2 describe-regions --query "Regions[$((selected_region_number-1))].RegionName" --output text)

# Step 2: List example EC2 instance types and let the user enter one or enter a custom type
echo  # Add a blank line
list_example_instance_types
custom_instance_type_option="5. Custom (Enter your own instance type)"
selected_instance_type_number=$(prompt "Enter the number for your desired instance type (e.g., 1 for t2.micro, 5 for custom)")

case $selected_instance_type_number in
  1)
    selected_instance_type="t2.micro"
    ;;
  2)
    selected_instance_type="t2.small"
    ;;
  3)
    selected_instance_type="m5.large"
    ;;
  4)
    selected_instance_type="c5.xlarge"
    ;;
  5)
    selected_instance_type=$(prompt "Enter your custom EC2 instance type")
    ;;
  *)
    echo "Invalid instance type selection."
    exit 1
    ;;
esac

# Step 3: Manually enter the AMI ID
echo  # Add a blank line
echo "Select your Amazon Machine Image ID from AWS Console."
selected_ami_id=$(prompt "Enter the AMI ID for your EC2 instance")

# Step 4: List available key pairs in the selected region
echo  # Add a blank line
key_pairs=$(aws ec2 describe-key-pairs --region $selected_region --query "KeyPairs[].{Name:KeyName}" --output text)
if [ -z "$key_pairs" ]; then
  echo "Warning: No key pairs are listed in the selected region. You might not be able to connect to the EC2 instance after launch."
  selected_key_pair="None"
else
  echo "Select a key pair:"
  echo "$key_pairs" | nl
  selected_key_pair_number=$(prompt "Enter the key pair number")
  selected_key_pair=$(echo "$key_pairs" | sed -n "${selected_key_pair_number}p")
fi

# Step 5: List available security groups in the selected region
echo  # Add a blank line
echo "Select a security group:"
aws ec2 describe-security-groups --region $selected_region --query "SecurityGroups[].{Name:GroupName}" --output text | nl
selected_security_group_number=$(prompt "Enter the security group number")
selected_security_group=$(aws ec2 describe-security-groups --region $selected_region --query "SecurityGroups[$((selected_security_group_number-1))].GroupName" --output text)

# Step 6: Prompt the user for the "Name" tag value
echo  # Add a blank line
name_tag_value=$(prompt "Enter the 'Name' tag value")

# Create the EC2 instance with the "Name" tag and selected key pair
if [ "$selected_key_pair" == "None" ]; then
  instance_id=$(aws ec2 run-instances --image-id "$selected_ami_id" --instance-type "$selected_instance_type" --security-group-ids "$selected_security_group" --region "$selected_region" --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$name_tag_value}]" --query "Instances[0].InstanceId" --output text)
else
  instance_id=$(aws ec2 run-instances --image-id "$selected_ami_id" --instance-type "$selected_instance_type" --key-name "$selected_key_pair" --security-group-ids "$selected_security_group" --region "$selected_region" --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$name_tag_value}]" --query "Instances[0].InstanceId" --output text)
fi

echo  # Add a blank line

if [ -n "$instance_id" ]; then
  echo "EC2 instance created successfully! Instance ID: $instance_id"
else
  echo "EC2 creation failed."
fi
