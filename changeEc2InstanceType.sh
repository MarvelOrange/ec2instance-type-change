####### Change EC2 instance type with reboot
####### Ben Prudence

## Functions
# Usage function
usage() {
  echo -e "Usage: $0 [-i INSTANCE_ID] [-t NEW_INSTANCE_TYPE] [-e ENVIRONMENT] [-a (Switch for Auto Stopping and Starting Instance)]" 1>&2; exit 1;
}

# Success echo message function
success() {
  echo -e "\033[0;32m$1\033[0;0m"
}

# Error echo message and exit function
error() {
  echo -e "\033[0;31m$1\033[0;0m"
  exit 1
}

## Args
# Organise args
while getopts "i:t:e:stopstart" opt; do
  case ${opt} in
    i)
      instanceId=$OPTARG
    ;;
    t)
      instanceType=$OPTARG
    ;;
    e)
      environment=$OPTARG
    ;;
    a)
      auto='True'
    ;;
    ?)
      usage
    ;;
  esac
done
shift $((OPTIND -1))

# Exit if no InstanceId is set
if [ -z ${instanceId} ]; then
  usage
fi

# Exit if no New Instance Type is set
if [ -z ${instanceType} ]; then
  usage
fi

# Default profile
if [ -z ${environment} ]; then
  environment='default'
fi

# Set auto to False is not set
if [[ $auto != 'True' ]]; then
  auto='False'
fi

## Script
# Get Instance
instance=$(aws ec2 describe-instances --instance-ids $instanceId --profile $environment > /dev/null 2>&1)
instanceResult=$?
if [ $instanceResult == 0 ]
then
  success "$instanceId found in $environment"
else
  error "$instanceId not found in $environment!"
  usage
fi

# Check instance type is different
if [[ $(aws ec2 describe-instances --instance-ids $instanceId --query 'Reservations[].Instances[].InstanceType' --output text --profile $environment) = $instanceType ]]
then
  error "Instance type is currently $instanceType. No change to be made."
fi

# Stop Instance if running
if [[ $(aws ec2 describe-instances --instance-ids $instanceId --query 'Reservations[].Instances[].State[].Name' --output text --profile $environment) = "running" ]]
then
  if [[ $auto == 'True' ]]
  then
    success "Stopping $instanceId in $environment..."
    aws ec2 stop-instances --instance-ids $instanceId --profile $environment > /dev/null 2>&1
    aws ec2 wait instance-stopped --instance-ids $instanceId --profile $environment
  else
    error "The instance $instanceId is running. Stop instance before trying to change instance type.\nYou can run this script again with '-a' to stop the instance as part of the script."
  fi
fi

# Change instance type when stopped
if [[ $(aws ec2 describe-instances --instance-ids $instanceId --query 'Reservations[].Instances[].State[].Name' --output text --profile $environment) = "stopped" ]]
then
  success "$instanceId is stopped"
  success "Changing $instanceId to $instanceType..."
  aws ec2 modify-instance-attribute --instance-id $instanceId --instance-type "{\"Value\": \"$instanceType\"}" --profile $environment > /dev/null 2>&1
fi

# Check instance type has changed
until [[ $instanceTypeChanged == $instanceType ]]
do
  instanceTypeChanged=$(aws ec2 describe-instances --instance-ids $instanceId --query 'Reservations[].Instances[].InstanceType' --output text --profile $environment)
  sleep 1
done
success "$instanceId has been changed to $instanceType"

# Start instance if auto is set
if [[ $auto == 'True' ]]
then
  success "Starting $instanceId in $environment..."
  aws ec2 start-instances --instance-ids $instanceId --profile $environment > /dev/null 2>&1
  aws ec2 wait instance-status-ok --instance-ids $instanceId --profile $environment
  success "$instanceId is now started with the new type of $instanceType and ready to use."
else
  success "$instanceId now has an instance type of $instanceType.\nThe instance has not been started due to the auto flag not being set at runtime '-a'"
fi
