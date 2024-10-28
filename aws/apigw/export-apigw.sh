#!/bin/bash

# Get the list of all REST APIs
apis=$(aws apigateway get-rest-apis --output json)

# Check if any APIs were found
if [ -z "$apis" ]; then
  echo "No REST API Gateway instances found."
  exit 1
fi

# Loop through each API and process it
echo "$apis" | jq -c '.items[]' | while IFS= read -r api; do
  api_id=$(echo "$api" | jq -r '.id')
  api_name=$(echo "$api" | jq -r '.name')

  # Sanitize the API name to be filesystem-friendly
  sanitized_name=$(echo "$api_name" | tr -dc 'a-zA-Z0-9_-')

  # Describe the API and export details
  if [ -n "$api_id" ] && [ -n "$sanitized_name" ]; then
    # Export API details as JSON
    aws apigateway get-rest-api --rest-api-id "$api_id" > "export-apigw-$sanitized_name.json"
    if [ $? -eq 0 ]; then
      echo "Exported details of $api_name (ID: $api_id) to export-apigw-$sanitized_name.json"
    else
      echo "Failed to export details of $api_name (ID: $api_id)"
    fi
    
    # Export API as Swagger (OpenAPI) JSON
    aws apigateway get-export --rest-api-id "$api_id" --stage-name "prod" --export-type "swagger" "swagger-$sanitized_name.json"
    if [ $? -eq 0 ]; then
      echo "Exported Swagger (OpenAPI) definition of $api_name (ID: $api_id) to swagger-$sanitized_name.json"
    else
      echo "Failed to export Swagger definition of $api_name (ID: $api_id)"
    fi
  fi
done