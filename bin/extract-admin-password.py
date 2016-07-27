#!/usr/bin/env python2

from __future__ import unicode_literals, print_function

import os
import re

root = os.path.normpath(
    os.path.dirname(os.path.abspath(__file__)) + "/.."
)
terraform_script_file = os.path.join(root, "terraform/ddcloud-docker-swarm.tf")

terraform_script = open(terraform_script_file, mode='r')
with terraform_script:
    script_lines = terraform_script.readlines()

found = False
variable_matcher = r'variable "admin_password"\s+\{\s+default\s+=\s+"(.*)"\s+\}'
for script_line in script_lines:
    match = re.match(variable_matcher, script_line)
    if not match:
        continue

    print(match.group(1))
    found = True

    break

if not found:
    raise "Failed to find variable 'admin_password' in terraform script."
