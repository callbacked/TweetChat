#!/bin/bash

# Variables
APPLICATION_NAME="twitter-chatbot-scraper"
ENVIRONMENT_NAME="twitter-chatbot-scraper-env"
S3_BUCKET_NAME="twitter-chatbot-scraper-bucket"
REGION="us-east-1"
ROLE_NAME="ElasticBeanstalkInstanceProfileRole"
INSTANCE_PROFILE_NAME="ElasticBeanstalkInstanceProfile"
S3_KEY="final.zip"

echo -e "\033[33mInitiating deletion of Beanstalk environment\033[0m"


aws elasticbeanstalk terminate-environment \
    --environment-name "$ENVIRONMENT_NAME" \
    --region "$REGION"

echo -e "\033[33mWaiting for termination to complete, standby..\033[0m"
aws elasticbeanstalk wait environment-terminated \
    --environment-name "$ENVIRONMENT_NAME" \
    --region "$REGION"

echo -e "\033[32mBeanstalk environment deletion success [✓] \033[0m"


echo -e "\033[33mInitiating deletion of Beanstalk application\033[0m"

aws elasticbeanstalk delete-application-version \
    --application-name "$APPLICATION_NAME" \
    --version-label "v1" \
    --delete-source-bundle \
    --region "$REGION"


aws elasticbeanstalk delete-application \
    --application-name "$APPLICATION_NAME" \
    --region "$REGION"
echo -e "\033[32mBeanstalk application deletion success [✓] \033[0m"

echo -e "\033[33mRemoving IAM role policies and instance profiles..\033[0m"
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
echo -e "\033[32mIAM roles and instance profiles successfully removed [✓] \033[0m"

echo -e "\033[33mInitiating deletion of S3 Bucket and its contents\033[0m"
aws s3 rm "s3://$S3_BUCKET_NAME/$S3_KEY"
aws s3 rm "s3://$S3_BUCKET_NAME/bot-icon.png"
aws s3 rb "s3://$S3_BUCKET_NAME" --force
echo -e "\033[32mS3 Bucket successfully removed [✓] \033[0m"


echo -e "\033[32mDeployment cleanup success [✓] \033[0m"