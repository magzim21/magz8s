module "efs" {
  source  = "cloudposse/efs/aws"
  version = "0.32.7"
  # insert the 18 required variables here

  # namespace = "static-assets"
  # stage     = "prod"
  name    = "production"
  region  = data.aws_region.current.id
  vpc_id  = module.vpc.vpc_id
  subnets = concat(module.vpc.public_subnets, module.vpc.private_subnets)
  # zone_id   = [var.aws_route53_dns_zone_id]

  allowed_security_group_ids = [data.aws_security_group.default.id]

  access_points = {
    # "" means / root path
    "" = {
      posix_user = {
        gid            = "0"
        uid            = "0"
        secondary_gids = "1001,1002,1003"
      }
      creation_info = {
        gid         = "0"
        uid         = "0"
        permissions = "0755"
      }
    }
  }
  # tags

}
