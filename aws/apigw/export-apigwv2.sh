#!/bin/bash

# Get the list of all APIs
apis=$(aws apigatewayv2 get-apis --output json)

# Check if any APIs were found
if [ -z "$apis" ]; then
  echo "No API Gateway instances found."
  exit 1
fi

# Loop through each API and process it
echo "$apis" | jq -c '.Items[]' | while IFS= read -r api; do
  api_id=$(echo "$api" | jq -r '.ApiId')
  api_name=$(echo "$api" | jq -r '.Name')
  api_protocol_type=$(echo "$api" | jq -r '.ProtocolType')

  # Sanitize the API name to be filesystem-friendly
  sanitized_name=$(echo "$api_name" | tr -dc 'a-zA-Z0-9_-')
  
  # Describe the API and export details
  if [ -n "$api_id" ] && [ -n "$sanitized_name" ]; then
    aws apigatewayv2 get-api --api-id "$api_id" > "export-apigw-$sanitized_name.json"
    if [ $? -eq 0 ]; then
      echo "Exported details of $api_name (ID: $api_id, Type: $api_protocol_type) to export-apigw-$sanitized_name.json"
    else
      echo "Failed to export details of $api_name (ID: $api_id, Type: $api_protocol_type)"
    fi
  fi
done