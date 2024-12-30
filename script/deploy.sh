
#export TF_VAR_image_tag=${GITHUB_RUN_NUMBER}-${GITHUB_RUN_ATTEMPT}
export TF_VAR_image_tag=1
export TF_VAR_db_password=$(aws secretsmanager get-secret-value --secret-id postgres-secret   --query SecretString --output text |  jq -r '."postgrespassword"')



terraform -chdir=infrastructure/terraform init  -backend-config="./backend.config"
terraform -chdir=infrastructure/terraform plan 
terraform -chdir=infrastructure/terraform apply  -input=false -auto-approve



hostname=$(aws rds describe-db-instances --db-instance-identifier llm-eks  --query "DBInstances[0].Endpoint.Address" --output text)

aws secretsmanager put-secret-value --secret-id postgres-secret --secret-string "{\"hostname\": \"${hostname}\",\"postgrespassword\": \"${TF_VAR_db_password}\"}"