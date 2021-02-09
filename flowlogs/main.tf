resource "ibm_resource_instance" "cos_instance" {
  name              = "${var.name}-cos-instance"
  resource_group_id = var.resource_group
  service           = "cloud-object-storage"
  plan              = "standard"
  location          = "global"
  tags              = concat(var.tags, ["object-storage"])
}

resource "ibm_cos_bucket" "vpc_flow_logs" {
  bucket_name          = "${var.name}-${var.region}-vpc-flowlogs-bucket"
  resource_instance_id = ibm_resource_instance.cos_instance.id
  region_location      = var.region
  storage_class        = "smart"
}

resource "ibm_cos_bucket" "subnet_flow_logs" {
  bucket_name          = "${var.name}-${var.region}-subnet-flowlogs-bucket"
  resource_instance_id = ibm_resource_instance.cos_instance.id
  region_location      = var.region
  storage_class        = "smart"
}

resource "ibm_iam_authorization_policy" "flowlogs_policy" {
  depends_on                  = [ibm_resource_instance.cos_instance]
  source_service_name         = "is"
  source_resource_type        = "flow-log-collector"
  target_service_name         = "cloud-object-storage"
  target_resource_instance_id = ibm_resource_instance.cos_instance.id
  roles                       = ["Reader", "Writer"]
}

resource ibm_is_flow_log vpc_flowlog {
  depends_on     = [ibm_iam_authorization_policy.flowlogs_policy]
  name           = "${var.name}-vpc-flow-log"
  target         = var.vpc_id
  active         = true
  storage_bucket = ibm_cos_bucket.vpc_flow_logs.id
  resource_group = var.resource_group
  tags           = concat(var.tags, ["vpc-flowlogs"])
}

# resource ibm_is_flow_log subnet_flowlog {
#   depends_on     = [ibm_is_flow_log.vpc_flowlog]
#   name           = "${var.name}-subnet-flow-log"
#   target         = var.subnet
#   active         = true
#   storage_bucket = ibm_cos_bucket.subnet_flow_logs.id
#   resource_group = var.resource_group
#   tags           = concat(var.tags, ["subnet-flowlogs"])
# }
