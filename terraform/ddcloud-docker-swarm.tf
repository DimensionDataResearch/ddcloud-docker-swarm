##############################################
# Docker swarm for Dimension Data CloudControl
##############################################

# See the config module for configuration variables.

variable "cloudcontrol_region"  { default = "AU" }
variable "cloudcontrol_dc"      { default = "AU9" }

variable "osimage_name"         { default = "CentOS 7 64-bit 2 CPU" }

variable "swarm_address_prefix" { default = "10.50.1" }

variable "domain_name"          { default = "tintoy.io" }
variable "subdomain_name"       { default = "au9.swarm" }
variable "aws_hosted_zone_id"   { default = "ZOBD4EJVNNOC4" }

variable "master_count"         { default = 2 }
variable "master_disk_size_gb"  { default = 20 }
variable "master_memory_gb"     { default = 8 }
variable "master_cpu_count"     { default = 2 }
variable "master_address_start" { default = 20 }

variable "worker_count"         { default = 3 }
variable "worker_disk_size_gb"  { default = 20 }
variable "worker_memory_gb"     { default = 8 }
variable "worker_cpu_count"     { default = 2 }
variable "worker_address_start" { default = 40 }

variable "admin_password"       { default = "sn4us4ges!" }
variable "auto_start"           { default = true }

variable "count_format"         { default = "%02d" }

provider "ddcloud" {
    region                 = "${var.cloudcontrol_region}"
}
provider "aws" {
    region = "us-west-1"
}

resource "ddcloud_networkdomain" "swarm_domain" {
	name                   = "Docker Swarm"
	description            = "Network domain for Docker Swarm."

	datacenter	           = "${var.cloudcontrol_dc}"
}

resource "ddcloud_vlan" "swarm_vlan_01" {
	name                   = "Docker Swarm 01"
	description 		   = "VLAN 01 for Docker Swarm."

	ipv4_base_address	   = "10.50.1.0"
	ipv4_prefix_size	   = 24

	networkdomain 		   = "${ddcloud_networkdomain.swarm_domain.id}"
}

# Masters.
resource "ddcloud_server" "swarm_master" {
    count                   = "${var.master_count}"
    name                    = "swarm-master-${format(var.count_format, count.index + 1)}"
    description             = "Master node ${format(var.count_format, count.index + 1)} for Docker Swarm"
    admin_password          = "${var.admin_password}"
    auto_start              = "${var.auto_start}"

    memory_gb               = "${var.master_memory_gb}"
    cpu_count               = "${var.master_cpu_count}"

    # OS disk (/dev/sda) - expand to ${var.master_disk_size_gb}.
    disk {
        scsi_unit_id        = 0
        size_gb             = "${var.master_disk_size_gb}"
        speed               = "STANDARD"
    }

    networkdomain           = "${ddcloud_networkdomain.swarm_domain.id}"
    primary_adapter_vlan    = "${ddcloud_vlan.swarm_vlan_01.id}"
    primary_adapter_ipv4    = "${var.swarm_address_prefix}.${var.master_address_start + count.index}"

    dns_primary             = "8.8.8.8"
    dns_secondary           = "8.8.4.4"

    osimage_name            = "${var.osimage_name}"

    tag {
        name  = "role"
        value = "master"
    }

    tag {
        name  = "consul_dc"
        value = "${lower(var.cloudcontrol_dc)}"
    }
}
resource "ddcloud_nat" "swarm_master" {
    count                   = "${var.master_count}"

    networkdomain           = "${ddcloud_networkdomain.swarm_domain.id}"
    private_ipv4            = "${element(ddcloud_server.swarm_master.*.primary_adapter_ipv4, count.index)}"

    depends_on              = ["ddcloud_vlan.swarm_vlan_01"]
}
resource "aws_route53_record" "dns-swarm-master-node" {
    count                   = "${var.master_count}"
    type                    = "A"
    ttl                     = 60
    zone_id                 = "${var.aws_hosted_zone_id}"

    name                    = "${element(ddcloud_server.swarm_master.*.name, count.index)}.node.${var.subdomain_name}.${var.domain_name}"
    records                 = ["${element(ddcloud_nat.swarm_master.*.public_ipv4, count.index)}"]
}

# Workers.
resource "ddcloud_server" "swarm_worker" {
    count                   = "${var.worker_count}"
    name                    = "swarm-worker-${format(var.count_format, count.index + 1)}"
    description             = "Worker node ${format(var.count_format, count.index + 1)} for Docker Swarm"
    admin_password          = "${var.admin_password}"
    auto_start              = "${var.auto_start}"

    memory_gb               = "${var.worker_memory_gb}"
    cpu_count               = "${var.worker_cpu_count}"

    # OS disk (/dev/sda) - expand to ${var.worker_disk_size_gb}.
    disk {
        scsi_unit_id        = 0
        size_gb             = "${var.worker_disk_size_gb}"
        speed               = "STANDARD"
    }

    networkdomain           = "${ddcloud_networkdomain.swarm_domain.id}"
    primary_adapter_vlan    = "${ddcloud_vlan.swarm_vlan_01.id}"
    primary_adapter_ipv4    = "${var.swarm_address_prefix}.${var.worker_address_start + count.index}"

    dns_primary             = "8.8.8.8"
    dns_secondary           = "8.8.4.4"

    osimage_name            = "${var.osimage_name}"

    tag {
        name  = "role"
        value = "worker"
    }

    tag {
        name  = "consul_dc"
        value = "${lower(var.cloudcontrol_dc)}"
    }
}
resource "ddcloud_nat" "swarm_worker" {
    count                   = "${var.worker_count}"

    networkdomain           = "${ddcloud_networkdomain.swarm_domain.id}"
    private_ipv4            = "${element(ddcloud_server.swarm_worker.*.primary_adapter_ipv4, count.index)}"

    depends_on              = ["ddcloud_vlan.swarm_vlan_01"]
}
resource "aws_route53_record" "dns-swarm-worker-node" {
    count                   = "${var.worker_count}"
    type                    = "A"
    ttl                     = 60
    zone_id                 = "${var.aws_hosted_zone_id}"

    name                    = "${element(ddcloud_server.swarm_worker.*.name, count.index)}.node.${var.subdomain_name}.${var.domain_name}"
    records                 = ["${element(ddcloud_nat.swarm_worker.*.public_ipv4, count.index)}"]
}

# Wildcard group.
resource "aws_route53_record" "dns-group-wildcard" {
    type    = "A"
    ttl     = 60
    zone_id = "${var.aws_hosted_zone_id}"

    name    = "*.${var.subdomain_name}.${var.domain_name}"
    records = [
        "${ddcloud_nat.swarm_master.*.public_ipv4}",
        "${ddcloud_nat.swarm_worker.*.public_ipv4}"
    ]
}
