# Terraform MongoDB replicaset to AWS

Example scripts to create VPC with availability zones, security groups and EC2 intances for MongoDB.
Follows more or less [AWS' own Cloudformation specific quickstart guide](https://docs.aws.amazon.com/quickstart/latest/mongodb/architecture.html)

## Getting started

Create a file for AWS access credentials. E.g. secret.auto.tfvars.
Don't put this to repository. Content of the file should look something like:

`access_key = "xxxxxxxxx"`  
`secret_key = "xxxxxxxxxxxxxxxx"`

After this you can normally run commands since *.auto.tfvars files will be automatically included. E.g.:

`terraform apply staging`

## Folder structure

### modules

Contains reusable modules for all builds. vpc for networking and mongodb for setting up MongoDb replicaset virtual machines and their security groups.

### production & staging

Shows examples of different environments, in this case staging and production but could be different customers etc. 

main.tf file configures environments with different paramters. E.g. production can be confitured with more availability zones, bigger virtual machine images etc.
