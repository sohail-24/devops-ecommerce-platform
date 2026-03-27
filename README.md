
## Run your backend bootstrap manually:

```
aws s3 mb s3://sohail-terraform-state-2026-001 --region ap-south-1
```

```
aws dynamodb create-table \
--table-name terraform-lock \
--attribute-definitions AttributeName=LockID,AttributeType=S \
--key-schema AttributeName=LockID,KeyType=HASH \
--billing-mode PAY_PER_REQUEST
```

## Terraform destroy steps:

step1: clone repo : 

```
git clone https://github.com/sohail-24/devops-ecommerce-platform.git
```

step2:

```
cd devops-ecommerce-platform/terraform
```

Ste3: 

```
terraform  init
```
terraform destroy plan 

```
terraform destroy -auto-approve
```
``
