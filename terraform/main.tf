module "networking" {
  source = "./modules/networking"

  project_name         = "infra-as-code-pipeline"
  vpc_cidr             = "10.0.0.0/16"
  availability_zones   = ["ap-south-1a", "ap-south-1b"]
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
}
module "security" {
  source = "./modules/security"

  project_name   = "infra-as-code-pipeline"
  vpc_id         = module.networking.vpc_id
  container_port = 5000
}
module "compute" {
  source = "./modules/compute"

  project_name = "infra-as-code-pipeline"
  aws_region   = var.aws_region

  vpc_id = module.networking.vpc_id

  public_subnet_ids  = module.networking.public_subnet_ids
  private_subnet_ids = module.networking.private_subnet_ids

  alb_security_group_id = module.security.alb_security_group_id
  ecs_security_group_id = module.security.ecs_security_group_id

  container_port  = 5000
  container_image = "public.ecr.aws/docker/library/python:3.12-alpine"
}
module "monitoring" {
  source = "./modules/monitoring"

  project_name     = "infra-as-code-pipeline"
  ecs_cluster_name = module.compute.ecs_cluster_name
  ecs_service_name = module.compute.ecs_service_name
}