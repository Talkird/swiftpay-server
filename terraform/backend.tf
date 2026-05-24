terraform {
  backend "s3" {
    bucket         = "swiftpay-terraform-server-state"
    key            = "swiftpay-server/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }
}
