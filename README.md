# ec2instance-type-change
Change the instance type of an EC2 instance in 1 script using the AWSCLI

## Dependancies
- awscli (configured)
- IAM permissions

## Arguements
```
-i = Instance ID
-t = New Instance Type
-e = AWS Profile name
-a = No value, this is a switch to auto stop and start the instance
```

## Usage
This script by default will change a stopped instance type.
If you utilise the '-a' switch at runtime the script will stop the instance, change the instance type and then start the instance and print when its ready to use. 
