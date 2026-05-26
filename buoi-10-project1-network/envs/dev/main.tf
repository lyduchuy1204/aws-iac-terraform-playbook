module "network" {
  source = "../../modules/network"

  name = "${var.project}-${var.env}"
  azs  = var.azs

  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
  single_nat_gateway   = true # dev: tiết kiệm ~$64/tháng
}
