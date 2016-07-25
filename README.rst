Docker Swarm on CloudControl
============================

This repository contains Terraform and Ansible scripts to deploy a Docker Swarm cluster on on Dimension Data CloudControl.

This is a work-in-progress.

Client Requirements
-------------------

* Linux or OSX only (sorry, but I haven't had time to build cross-platform scripts yet).
* Python 2.7
* Ansible 1.8 or higher (run ``pip install -r requirements.txt``).
* Terraform 0.7-rc2 or higher.
* The `ddcloud provider <http://https://github.com/DimensionDataResearch/dd-cloud-compute-terraform>`_ for Terraform.
* An AWS hosted DNS zone.
* AWS credentials that can manage entries in that zone.
* CloudControl credentials.
* SSH keypair stored in ``~/.ssh/id_rsa``.

Getting started
---------------

You'll want to customise `<terraform/ddcloud-docker-swarm.tf>`_ and `<ddcloud-docker-swarm.yml>`_ with the correct values for your configuration.

Then:

* `pushd ./terraform`
	* `terraform apply`
	* `terraform refresh` (required by inventory plugin to pick up public IP addresses for cluster machines)
* `popd`
* `./enable-ssh` (configure the cluster machines to trust your SSH key)
* `ansible all -u root -m ping' (you should see a response from each machine in the cluster, once they have rebooted)
* `ansible all -u root -m ping' (you should see a response from each machine in the cluster, once they have rebooted)
* `ansible-playbook -u root ./playbooks/upgrade-packages.yml`
* `ansible-playbook -u root ./playbooks/reboot-servers.yml` (if this command hangs, after 30 seconds just hit Ctrl-C, and proceed to the next step)
* `ansible-playbook -u root ./playbooks/check-requirements.yml` (you should see no warnings or errors)
* `ansible-playbook -u root ./ddcloud-docker-swarm.yml` (you should see no warnings or errors)

You're now ready to swarm.
