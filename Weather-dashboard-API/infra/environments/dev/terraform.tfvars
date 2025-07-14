# This file is used to provide values for the variables defined in variables.tf.
# It is ignored by git to prevent sensitive data from being committed.

# Bastion Host Configuration
bastion_allowed_cidr_blocks = ["189.128.81.59/32"]

# Pipeline Configuration
enable_pipeline_webhook = false # Set to true to enable automatic triggers

# You can add other sensitive variables here, for example:
# db_username = "admin"
# db_password = "your-secret-password"
