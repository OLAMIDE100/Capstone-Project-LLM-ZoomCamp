



echo 'yes' | terraform -chdir=infrastructure/terraform init  -backend-config="./backend.config"
echo 'yes' | terraform -chdir=infrastructure/terraform plan 
echo 'yes' | terraform -chdir=infrastructure/terraform destroy


