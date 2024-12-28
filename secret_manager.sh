


aws eks update-kubeconfig --name eks
eksctl utils associate-iam-oidc-provider --cluster eks --approve
OIDC_PROVIDER=$(aws eks describe-cluster --name eks --region eu-central-1 --query "cluster.identity.oidc.issuer" --output text | sed -e "s/^https:\/\///")
SERVICE_ACCOUNT="secret-accessor"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)




aws iam create-role \
    --role-name aws-eks-secret-role \
    --assume-role-policy-document "{
        \"Version\": \"2012-10-17\",
        \"Statement\": [
            {
                \"Effect\": \"Allow\",
                \"Principal\": {
                    \"Federated\": \"arn:aws:iam::${ACCOUNT_ID}:oidc-provider/${OIDC_PROVIDER}\"
                },
                \"Action\": \"sts:AssumeRoleWithWebIdentity\",
                \"Condition\": {
                    \"StringEquals\": {
                        \"${OIDC_PROVIDER}:aud\": \"sts.amazonaws.com\",
                        \"${OIDC_PROVIDER}:sub\": \"system:serviceaccount:default:${SERVICE_ACCOUNT}\"
                    }
                }
            }
        ]
    }"



aws iam attach-role-policy \
--role-name aws-eks-secret-role \
--policy-arn arn:aws:iam::aws:policy/SecretsManagerReadWrite