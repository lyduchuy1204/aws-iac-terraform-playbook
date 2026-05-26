# ─── (Tuỳ chọn) Đọc output buổi 10 qua remote state ─────────────────────────
# Nếu muốn tự động hoá (không phải copy/paste vpc_id), bỏ comment block dưới
# và dùng `data.terraform_remote_state.network.outputs.vpc_id` thay cho var.vpc_id.
#
# data "terraform_remote_state" "network" {
#   backend = "s3"
#   config = {
#     bucket = "<YOUR_BUCKET_NAME>"
#     key    = "project1/network/dev/terraform.tfstate"
#     region = "ap-southeast-1"
#   }
# }

module "compute" {
  source = "../../modules/compute"

  name               = "${var.project}-${var.env}"
  vpc_id             = var.vpc_id
  vpc_cidr           = var.vpc_cidr
  private_subnet_ids = var.private_subnet_ids

  instance_type        = "t3.micro"
  asg_min_size         = 1
  asg_max_size         = 3
  asg_desired_capacity = 2
}
