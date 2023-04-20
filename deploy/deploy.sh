APPLICATION_NAME="twitter-chatbot-scraper"
ENVIRONMENT_NAME="twitter-chatbot-scraper-env"
ENVIRONMENT_URL=$(aws elasticbeanstalk describe-environments --application-name "$APPLICATION_NAME" --environment-names "$ENVIRONMENT_NAME" --query "Environments[0].CNAME" --output text)
S3_BUCKET_NAME="twitter-chatbot-scraper-bucket"
S3_KEY="final.zip"
REGION="us-east-1"
PLATFORM_VERSION="64bit Amazon Linux 2 v3.5.1 running Python 3.8"
INSTANCE_PROFILE_NAME="ElasticBeanstalkInstanceProfile"
ROLE_NAME="ElasticBeanstalkInstanceProfileRole"

echo -e "\033[33mCreating S3 Bucket and uploading contents\033[0m"
if [ "$REGION" == "us-east-1" ]; then
  aws s3api create-bucket --bucket "$S3_BUCKET_NAME" --region "$REGION"
else
  aws s3api create-bucket --bucket "$S3_BUCKET_NAME" --region "$REGION" --create-bucket-configuration LocationConstraint="$REGION"
fi

aws s3api put-bucket-policy --bucket "$S3_BUCKET_NAME" --policy '{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::'"$S3_BUCKET_NAME"'/*"
    }
  ]
}'

aws s3 cp "./final.zip" "s3://$S3_BUCKET_NAME/$S3_KEY"
aws s3 cp "./assets/bot-icon.png" "s3://twitter-chatbot-scraper-bucket"

echo -e "\033[32mS3 Bucket creation and content upload success [✓] \033[0m"

echo -e "\033[33mCreating Beanstalk application\033[0m"
aws elasticbeanstalk create-application --application-name "$APPLICATION_NAME" --region "$REGION"
echo -e "\033[32mBeanstalk application creation success [✓] \033[0m"

echo -e "\033[33mCreating IAM role and instance profile\033[0m"
aws iam create-role --role-name "$ROLE_NAME" --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"ec2.amazonaws.com"},"Action":"sts:AssumeRole"}]}'
aws iam create-instance-profile --instance-profile-name "$INSTANCE_PROFILE_NAME"
aws iam add-role-to-instance-profile --role-name "$ROLE_NAME" --instance-profile-name "$INSTANCE_PROFILE_NAME"
echo -e "\033[32mIAM role creation and instance profile success [✓] \033[0m"

echo -e "\033[33mAttaching policies\033[0m"
aws iam attach-role-policy --role-name "$ROLE_NAME" --policy-arn arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier
aws iam attach-role-policy --role-name "$ROLE_NAME" --policy-arn arn:aws:iam::aws:policy/AWSElasticBeanstalkMulticontainerDocker
aws iam attach-role-policy --role-name "$ROLE_NAME" --policy-arn arn:aws:iam::aws:policy/AWSElasticBeanstalkWorkerTier
echo -e "\033[32mPolicies attached[✓] \033[0m"


echo -e "\033[33mFinalizing Beanstalk environment\033[0m"
aws elasticbeanstalk create-application-version \
  --application-name "$APPLICATION_NAME" \
  --version-label "v1" \
  --source-bundle S3Bucket="$S3_BUCKET_NAME",S3Key="$S3_KEY" \
  --region "$REGION"

aws elasticbeanstalk create-environment \
  --application-name "$APPLICATION_NAME" \
  --environment-name "$ENVIRONMENT_NAME" \
  --region "$REGION" \
  --solution-stack-name "$PLATFORM_VERSION" \
  --version-label "v1" \
  --option-settings Namespace=aws:elasticbeanstalk:application:environment,OptionName=PYTHON_ENV,Value=python3.8 \
                    Namespace=aws:autoscaling:launchconfiguration,OptionName=IamInstanceProfile,Value="$INSTANCE_PROFILE_NAME"

echo -e "\033[33mWaiting for environment to finish launching\033[0m"

while true; do
    ENVIRONMENT_STATUS=$(aws elasticbeanstalk describe-environments --application-name "$APPLICATION_NAME" --environment-names "$ENVIRONMENT_NAME" --query "Environments[0].Status" --output text --region "$REGION")
    
    if [[ "$ENVIRONMENT_STATUS" == "Ready" ]]; then
        break
    elif [[ "$ENVIRONMENT_STATUS" == "Terminated" ]]; then
        echo -e "\033[31mEnvironment launch failed. Please check your configuration.\033[0m"
        exit 1
    else
        echo -e "\033[33mEnvironment status: $ENVIRONMENT_STATUS. Waiting...\033[0m"
        sleep 20
    fi
done

echo -e "\033[33mRetrieving Beanstalk URL\033[0m"
BEANSTALK_URL=$(aws elasticbeanstalk describe-environments --application-name "$APPLICATION_NAME" --environment-names "$ENVIRONMENT_NAME" --query "Environments[0].CNAME" --output text --region "$REGION")
echo -e "\033[32mBeanstalk URL: https://$BEANSTALK_URL [✓] \033[0m"
echo -e "\033[32mDeployment success[✓] \033[0m"