
read -p "image_tag : " image_tag



export TF_VAR_db_password=$(aws secretsmanager get-secret-value --secret-id postgres-secret   --query SecretString --output text |  jq -r '."postgrespassword"')


echo 'yes' | terraform -chdir=infrastructure/terraform init  -backend-config="./backend.config"
echo 'yes' | terraform -chdir=infrastructure/terraform plan 
echo 'yes' | terraform -chdir=infrastructure/terraform apply 



hostname=$(aws rds describe-db-instances --db-instance-identifier llm-eks  --query "DBInstances[0].Endpoint.Address" --output text)




aws secretsmanager put-secret-value --secret-id postgres-secret --secret-string "{\"hostname\": \"${hostname}\",\"postgrespassword\": \"${TF_VAR_db_password}\"}"