#!/bin/bash

# Variables
APPLICATION_NAME="twitter-chatbot-scraper"
ENVIRONMENT_NAME="twitter-chatbot-scraper-env"
S3_BUCKET_NAME="twitter-chatbot-scraper-bucket"
REGION="us-east-1"
ROLE_NAME="ElasticBeanstalkInstanceProfileRole"
INSTANCE_PROFILE_NAME="ElasticBeanstalkInstanceProfile"
S3_KEY="final.zip"

# Terminate the Elastic Beanstalk environment
aws elasticbeanstalk terminate-environment \
    --environment-name "$ENVIRONMENT_NAME" \
    --region "$REGION"

# Wait for the environment to terminate
aws elasticbeanstalk wait environment-terminated \
    --environment-name "$ENVIRONMENT_NAME" \
    --region "$REGION"


# Delete the Elastic Beanstalk application version
aws elasticbeanstalk delete-application-version \
    --application-name "$APPLICATION_NAME" \
    --version-label "v1" \
    --delete-source-bundle \
    --region "$REGION"

# Delete the Elastic Beanstalk application
aws elasticbeanstalk delete-application \
    --application-name "$APPLICATION_NAME" \
    --region "$REGION"

# Delete the IAM role policies
aws iam detach-role-policy \
    --role-name "$ROLE_NAME" \
    --policy-arn arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier

aws iam detach-role-policy \
    --role-name "$ROLE_NAME" \
    --policy-arn arn:aws:iam::aws:policy/AWSElasticBeanstalkMulticontainerDocker

aws iam detach-role-policy \
    --role-name "$ROLE_NAME" \
    --policy-arn arn:aws:iam::aws:policy/AWSElasticBeanstalkWorkerTier

# Delete the IAM instance profile
aws iam remove-role-from-instance-profile \
    --instance-profile-name "$INSTANCE_PROFILE_NAME" \
    --role-name "$ROLE_NAME"

aws iam delete-instance-profile \
    --instance-profile-name "$INSTANCE_PROFILE_NAME"

# Delete the IAM role
aws iam delete-role \
    --role-name "$ROLE_NAME"

# Delete the S3 bucket objects and the bucket
aws s3 rm "s3://$S3_BUCKET_NAME/$S3_KEY"
aws s3 rm "s3://$S3_BUCKET_NAME/bot-icon.png"
aws s3 rb "s3://$S3_BUCKET_NAME" --force

