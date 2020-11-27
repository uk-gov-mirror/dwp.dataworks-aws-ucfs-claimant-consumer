locals {
  certificate_auth_public_cert_bucket = data.terraform_remote_state.certificate_authority.outputs.public_cert_bucket
  k2hb_data_source_is_ucfs            = data.terraform_remote_state.ingestion.outputs.locals.k2hb_data_source_is_ucfs
  stub_bootstrap_servers              = data.terraform_remote_state.ingestion.outputs.locals.stub_bootstrap_servers
  stub_kafka_broker_port_https        = data.terraform_remote_state.ingestion.outputs.locals.stub_kafka_broker_port_https
  ucfs_ha_broker_prefix               = data.terraform_remote_state.ingestion.outputs.locals.ucfs_ha_broker_prefix
  ucfs_london_domains                 = data.terraform_remote_state.ingestion.outputs.locals.ucfs_london_domains
  uc_kafka_broker_port_https          = data.terraform_remote_state.ingestion.outputs.locals.uc_kafka_broker_port_https

  ingest_internet_proxy = data.terraform_remote_state.ingestion.outputs.internet_proxy
  ingest_no_proxy_list  = data.terraform_remote_state.ingestion.outputs.vpc.vpc.no_proxy_list
  internet_proxy        = local.ingest_internet_proxy.host
  non_proxied_endpoints = join(",", local.ingest_no_proxy_list)

  ucfs_london_current_domain = local.ucfs_london_domains[local.environment]

  ucfs_london_ha_broker_list = [
    "${local.ucfs_ha_broker_prefix}00.${local.ucfs_london_current_domain}",
    "${local.ucfs_ha_broker_prefix}01.${local.ucfs_london_current_domain}",
    "${local.ucfs_ha_broker_prefix}02.${local.ucfs_london_current_domain}"
  ]

  ucfs_london_bootstrap_servers = {
    development = ["n/a"]                          // stubbed only
    qa          = ["n/a"]                          // stubbed only
    integration = local.ucfs_london_ha_broker_list //this exists on UC's end, but we do not use it as the env is stubbed as at Oct 2020
    preprod     = local.ucfs_london_ha_broker_list
    production  = local.ucfs_london_ha_broker_list
  }

  kafka_london_bootstrap_servers = {
    development = local.stub_bootstrap_servers[local.environment] // stubbed
    qa          = local.stub_bootstrap_servers[local.environment] // stubbed
    integration = local.k2hb_data_source_is_ucfs[local.environment] ? local.ucfs_london_bootstrap_servers[local.environment] : local.stub_bootstrap_servers[local.environment]
    preprod     = local.ucfs_london_bootstrap_servers[local.environment] // now on UCFS Staging HA
    production  = local.ucfs_london_bootstrap_servers[local.environment] // now on UCFS Production HA
  }

  kafka_broker_port = {
    development = local.stub_kafka_broker_port_https
    qa          = local.stub_kafka_broker_port_https
    integration = local.k2hb_data_source_is_ucfs[local.environment] ? local.uc_kafka_broker_port_https : local.stub_kafka_broker_port_https
    preprod     = local.uc_kafka_broker_port_https
    production  = local.uc_kafka_broker_port_https
  }

  kafka_consumer_truststore_aliases = {
    development = "ucfs_ca"
    qa          = "ucfs_ca"
    integration = "ucfs_ca"
    preprod     = "ucfs_ca"
    production  = "ucfs_ca"
  }

  kafka_consumer_truststore_certs = {
    development = "s3://${local.certificate_auth_public_cert_bucket.id}/ca_certificates/ucfs/root_ca.pem"
    qa          = "s3://${local.certificate_auth_public_cert_bucket.id}/ca_certificates/ucfs/root_ca.pem"
    integration = "s3://${local.certificate_auth_public_cert_bucket.id}/ca_certificates/ucfs/root_ca.pem"
    preprod     = "s3://${local.certificate_auth_public_cert_bucket.id}/ca_certificates/ucfs/root_ca.pem"
    production  = "s3://${local.certificate_auth_public_cert_bucket.id}/ca_certificates/ucfs/root_ca.pem"
  }

  log_level = {
    development = "DEBUG"
    qa          = "INFO"
    integration = "INFO"
    preprod     = "INFO"
    production  = "INFO"
  }

  kafka_bootstrap_servers = join(
    ",",
    formatlist(
      "%s:%s",
      local.kafka_london_bootstrap_servers[local.environment],
      local.kafka_broker_port[local.environment],
    ),
  )

  kafka_consumer_group = "dataworks-ucfs-claimant-ingest-${local.environment}"

  kafka_fetch_max_bytes = {
    development = 20000000
    qa          = 20000000
    integration = 20000000
    preprod     = 20000000
    production  = 20000000
  }

  kafka_max_partition_fetch_bytes = {
    development = 20000000
    qa          = 20000000
    integration = 20000000
    preprod     = 20000000
    production  = 20000000
  }

  kafka_max_poll_interval_ms = {
    development = 600000
    qa          = 600000
    integration = 600000
    preprod     = 600000
    production  = 1800000
  }

  kafka_max_poll_records = {
    development = 25
    qa          = 50
    integration = 50
    preprod     = 25
    production  = 5000
  }

  kafka_poll_duration_seconds = {
    development = 10
    qa          = 10
    integration = 60
    preprod     = 60
    production  = 120
  }

  kafka_topic_regex = {
    //match any "db.*" collections i.e. db.aa.bb, with only two literal dots allowed
    //DW-4748 & DW-4827 - Allow extra dot in last matcher group for db.crypto.encryptedData.unencrypted
    development = "^(db[.]{1}[-\\\\w]+[.]{1}[-.\\\\w]+)$"
    qa          = "^(db[.]{1}[-\\\\w]+[.]{1}[-.\\\\w]+)$"
    integration = "^(db[.]{1}[-\\\\w]+[.]{1}[-.\\\\w]+)$"
    preprod     = "^(db[.]{1}[-\\\\w]+[.]{1}[-.\\\\w]+)$"
    production  = "^(db[.]{1}[-\\\\w]+[.]{1}[-.\\\\w]+)$"
  }
}