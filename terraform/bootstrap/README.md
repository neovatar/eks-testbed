This terraform project does the following:

- Bootstrap an S3 bucket for keeping terraform state in AWS
- Bootstrap dynamodb for keeping terraform state locks in AWS
- Create ../backend-config.tfvars, that wil be used later by
  our other terraform projects

**Note:**

  Bootstrap state is only kept locally. If you want to share it with your team
  you need to add it to your git repository. Since the terraform statefile can
  contain information that your organisation may consider secret, it is a good
  idea to encrypt the statefile before you commit it to git (e.g. with git-crypt)
