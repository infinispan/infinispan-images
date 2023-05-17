#!/bin/bash
set -e

# Add tzdata packages https://access.redhat.com/solutions/5616681
microdnf update tzdata -y
microdnf reinstall tzdata -y
