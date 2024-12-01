#!/bin/bash

# Set AWS dynamically
export id=$(grep id $(pwd)/.aws/.env | awk '{print $3}')
export key=$(grep key $(pwd)/.aws/.env | awk '{print $3}')
export AWS_DEFAULT_REGION="eu-west-3"

# AWS CLI Configuration

aws configure set id "$id"
aws configure set key "$key"
aws configure set default.region "$AWS_DEFAULT_REGION"
aws configure set default.output json

