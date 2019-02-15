This terraform project creates our EKS environment.


## terraform init
To init terraform, you need to pass the backend configuration `backend-config.tfvars`. This file was created by running
the terraform bootstrap project and is placed in the root of this git repository.

To init the terraform project, run:
`terraform init -backend-config ../backend-config.tfvars`

## terraform plan/apply
To plan/apply configuration via terraform, you need to pass the configuration `config.tfvars`. This file was created manually by you and is placed in the root of this git

To plan configuration via terraform, run:
`terraform plan -var-file ../config.tfvars`

To apply configuration via terraform, run:
`terraform apply -var-file ../config.tfvars`
