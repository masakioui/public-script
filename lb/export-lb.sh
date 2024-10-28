#!/bin/bash

# Verify if jq is installed
if ! command -v jq &> /dev/null
then
    echo "'jq' could not be found, please install it"
    exit
fi

# Get the list of all load balancers
load_balancers=$(aws elbv2 describe-load-balancers --query "LoadBalancers[*].[LoadBalancerName, LoadBalancerArn, Type]" --output json)

# Check if any load balancers were found
if [ -z "$load_balancers" ]; then
  echo "No load balancers found."
  exit 1
fi

# Loop through each load balancer
echo "$load_balancers" | jq -c '.[]' | while IFS= read -r lb; do
  lb_name=$(echo "$lb" | jq -r '.[0]')
  lb_arn=$(echo "$lb" | jq -r '.[1]')
  lb_type=$(echo "$lb" | jq -r '.[2]')

  # Sanitize the load balancer name to be filesystem-friendly
  sanitized_name=$(echo "$lb_name" | tr -dc 'a-zA-Z0-9_-')

  # Describe the load balancer and export details
  if [ -n "$lb_arn" ] && [ -n "$sanitized_name" ]; then
    lb_detail_file="export-${lb_type}-$sanitized_name.json"
    aws elbv2 describe-load-balancers --load-balancer-arns "$lb_arn" > "$lb_detail_file"
    if [ $? -eq 0 ]; then
      echo "Exported details of $lb_name (ARN: $lb_arn, Type: $lb_type) to $lb_detail_file"
    else
      echo "Failed to export details of $lb_name (ARN: $lb_arn, Type: $lb_type)"
    fi

    # Describe the listeners for the load balancer
    listeners=$(aws elbv2 describe-listeners --load-balancer-arn "$lb_arn" --query "Listeners[*].ListenerArn" --output text)

    # Loop through each listener and export details
    for listener_arn in $listeners; do
      listener_detail_file="export-listener-$(basename $listener_arn).json"
      aws elbv2 describe-listeners --listener-arns "$listener_arn" > "$listener_detail_file"
      if [ $? -eq 0 ]; then
        echo "Exported details of listener $listener_arn to $listener_detail_file"
      else
        echo "Failed to export details of listener $listener_arn"
      fi
    done

    # Describe the target groups associated with the load balancer
    target_groups=$(aws elbv2 describe-target-groups --load-balancer-arn "$lb_arn" --query "TargetGroups[*].TargetGroupArn" --output text)

    # Loop through each target group and export details
    for tg_arn in $target_groups; do
      tg_detail_file="export-tg-$(basename $tg_arn).json"
      aws elbv2 describe-target-groups --target-group-arns "$tg_arn" > "$tg_detail_file"
      if [ $? -eq 0 ]; then
        echo "Exported details of target group $tg_arn to $tg_detail_file"
      else
        echo "Failed to export details of target group $tg_arn"
      fi
    done
  fi
done