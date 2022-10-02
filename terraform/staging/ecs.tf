module "ecs_cluster" {
  source             = "../modules/ecs_cluster"
  name               = "duelyst-staging"
  ssh_public_key     = var.ssh_public_key
  security_group_ids = [module.internal_security_group.id]
  subnets = [
    module.first_subnet.id,
    module.second_subnet.id,
    module.third_subnet.id,
  ]
}

module "ecs_service_api" {
  source            = "../modules/ecs_service"
  name              = "duelyst-api-staging"
  cluster           = module.ecs_cluster.id
  capacity_provider = module.ecs_cluster.capacity_provider
  task_role         = module.ecs_cluster.task_role
  ecr_registry      = var.ecr_registry_id
  ecr_repository    = module.ecr_repository_api.id
  deployed_version  = "latest"
  container_count   = 0
  container_cpu     = 1
  container_mem     = 32
  service_port      = 3000
  alb_target_group  = module.staging_load_balancer.api_target_group_arn

  environment_variables = []
  secrets               = []
}

module "ecs_service_sp" {
  source            = "../modules/ecs_service"
  name              = "duelyst-sp-staging"
  cluster           = module.ecs_cluster.id
  capacity_provider = module.ecs_cluster.capacity_provider
  task_role         = module.ecs_cluster.task_role
  ecr_registry      = var.ecr_registry_id
  ecr_repository    = module.ecr_repository_sp.id
  deployed_version  = "1.97.0"
  container_count   = 1
  container_cpu     = 1
  container_mem     = 500
  service_port      = 8000
  alb_target_group  = module.staging_load_balancer.sp_target_group_arn

  environment_variables = [
    {
      name  = "NODE_ENV"
      value = "staging"
    },
    {
      name  = "REDIS_HOST"
      value = module.redis.instance_dns
    },
    {
      name  = "FIREBASE_URL"
      value = var.firebase_url
    }
  ]

  secrets = [
    {
      name      = "FIREBASE_LEGACY_TOKEN"
      valueFrom = "/duelyst/staging/firebase/legacy-token"
    }
  ]
}
