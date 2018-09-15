terraform {
  backend "local" {
    path = "./terraform-bootstrap.tfstate"
  }
}
