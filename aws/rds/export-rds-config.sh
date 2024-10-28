#!/bin/bash

# List all RDS instances and get their identifiers
instance_ids=$(aws rds describe-db-instances | jq -r '.DBInstances[].DBInstanceIdentifier')

# Check if any instance identifiers were found
if [ -z "$instance_ids" ]; then
  echo "No RDS instances found."
  exit 1
fi

# Loop through each instance identifier and process it
while IFS= read -r instance_id; do
  # Describe the instance and export to a file
  if [[ -n "$instance_id" ]]; then
    aws rds describe-db-instances --db-instance-identifier "$instance_id" > "export-rds-$instance_id.json"
    if [ $? -eq 0 ]; then
      echo "Exported details of $instance_id to export-rds-$instance_id.json"
    else
      echo "Failed to export details of $instance_id"
    fi
  fi
done <<< "$instance_ids"