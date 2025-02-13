locals {
  # If any keys contain name_suffix, then use a null label to get the label prefix, and create
  # the appropriate input for the upstream module.
  cloudwatch_forwarder_log_groups = {
    for k, v in var.cloudwatch_forwarder_log_groups :
    k => {
      name : lookup(v, "name_suffix", null) != null ? format(
        "%s%s%s%s",
        lookup(v, "name_prefix", "/aws/"),
        module.log_group_prefix.id,
        module.log_group_prefix.delimiter,
        lookup(v, "name_suffix")
      ) : lookup(v, "name")
      filter_pattern : lookup(v, "filter_pattern", "")
    }
  }

  # Only return context tags that are specified
  # NOTE: Tags are lowercased automatically by Datadog
  # See https://docs.datadoghq.com/developers/guide/what-best-practices-are-recommended-for-naming-metrics-and-tags/#rules-and-best-practices-for-naming-tags
  context_tags = var.context_tags_enabled ? {
    for k, v in module.this.tags :
    k => v
    if contains(var.context_tags, lower(k))
  } : {}

  dd_tags_map = merge(var.dd_tags_map, local.context_tags)
}

module "log_group_prefix" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  label_order = ["namespace", "tenant", "environment", "stage"]

  context = module.this.context
}

module "datadog_lambda_forwarder" {
  source  = "cloudposse/datadog-lambda-forwarder/aws"
  version = "0.12.0"

  cloudwatch_forwarder_log_groups       = local.cloudwatch_forwarder_log_groups
  dd_api_key_kms_ciphertext_blob        = var.dd_api_key_kms_ciphertext_blob
  dd_api_key_source                     = var.dd_api_key_source
  dd_artifact_filename                  = var.dd_artifact_filename
  dd_forwarder_version                  = var.dd_forwarder_version
  dd_module_name                        = var.dd_module_name
  dd_tags_map                           = local.dd_tags_map
  forwarder_lambda_datadog_host         = var.forwarder_lambda_datadog_host
  forwarder_lambda_debug_enabled        = var.forwarder_lambda_debug_enabled
  forwarder_log_artifact_url            = var.forwarder_log_artifact_url
  forwarder_log_enabled                 = var.forwarder_log_enabled
  forwarder_log_layers                  = var.forwarder_log_layers
  forwarder_log_retention_days          = var.forwarder_log_retention_days
  forwarder_rds_artifact_url            = var.forwarder_rds_artifact_url
  forwarder_rds_enabled                 = var.forwarder_rds_enabled
  forwarder_rds_filter_pattern          = var.forwarder_rds_filter_pattern
  forwarder_rds_layers                  = var.forwarder_rds_layers
  forwarder_vpc_logs_artifact_url       = var.forwarder_vpc_logs_artifact_url
  forwarder_vpc_logs_enabled            = var.forwarder_vpc_logs_enabled
  forwarder_vpc_logs_layers             = var.forwarder_vpc_logs_layers
  forwarder_vpclogs_filter_pattern      = var.forwarder_vpclogs_filter_pattern
  kms_key_id                            = var.kms_key_id
  lambda_policy_source_json             = var.lambda_policy_source_json
  lambda_reserved_concurrent_executions = var.lambda_reserved_concurrent_executions
  lambda_runtime                        = var.lambda_runtime
  s3_bucket_kms_arns                    = var.s3_bucket_kms_arns
  s3_buckets                            = var.s3_buckets
  security_group_ids                    = var.security_group_ids
  subnet_ids                            = var.subnet_ids
  tracing_config_mode                   = var.tracing_config_mode
  vpclogs_cloudwatch_log_group          = var.vpclogs_cloudwatch_log_group

  context = module.this.context
}
