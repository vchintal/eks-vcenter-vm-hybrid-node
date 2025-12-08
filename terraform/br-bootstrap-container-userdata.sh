#!/usr/bin/env sh
set -euo pipefail

eks-hybrid-ssm-setup --activation-id=${activation_id} --activation-code=${activation_code} --region=${aws_region}

echo "User-data script executed."