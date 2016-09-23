Docker Swarm on CloudControl
============================

This repository contains Terraform and Ansible scripts to deploy a Docker Swarm cluster on on Dimension Data CloudControl.

Bits and pieces have been borrowed from the excellent `Mantl <https://github.com/CiscoCloud/Mantl>`_ project.

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
* `sshpass <https://gist.github.com/arunoda/7790979>`_ if you want to deploy everything with a single command (sorry, see Known Issues section below).
* SSH keypair stored in ``~/.ssh/id_rsa``.

Getting started
---------------

You'll want to customise `<terraform/ddcloud-docker-swarm.tf>`_ and `<ddcloud-docker-swarm.yml>`_ with the correct values for your configuration.

Then:

``./create-cluster``

Once the process completes (the "upgrade packages" step can take quite a while), you're now ready to swarm.

Known issues
------------

Usage of ``sshpass`` is ugly; we have since worked out `how to deploy SSH keys to DD CloudControl <https://github.com/DimensionDataResearch/glider-gun/blob/master/docker-images/glider-gun-template-multi-cloud/root/ddcloud/web/ssh.tf>`_ (and will back-port this functionality at some point).
