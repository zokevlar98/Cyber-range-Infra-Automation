#!/bin/bash

ip=$(cat $(pwd)/ansible/.env)

ssh -i $(pwd)/cyberrange-key.pem -o StrictHostKeyChecking=no ubuntu@$ip "exit"

# sleep(3)
