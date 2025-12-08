#!/bin/bash

set -e

source ../hybrid-nodes.env

# Color codes for output
NC='\e[0m' # No Color
RED='\e[0;31m' # Red
GREEN='\e[0;32m' # Green

OS=`uname -s | tr '[:upper:]' '[:lower:]'`
OVA="bottlerocket-vmware-k8s-${eks_version}-x86_64-${bottlerocket_version}.ova"
SHA512SUM="4fcb272345fd6adb94d4c04834400548178fecb57407ca79bc2c3d20e0428fc9ed3a82cea268d7f9c667b5803524a4f465acd701a86953d5d732bf6ecb064888"

export GOVC_URL="https://${vsphere_server}/sdk"
export GOVC_USERNAME="${vsphere_user}"
export GOVC_PASSWORD="${vsphere_password}"
export GOVC_INSECURE=true 
export GOVC_DATASTORE="${vsphere_datastore}"
export GOVC_NETWORK="${vsphere_network}"

# Remove download folder if it exists
if [ -d "download" ]; then
    rm -rf download
fi

# Check if cargo is installed
if ! command -v cargo &> /dev/null; then
    echo "Cargo is not installed. Please install Rust and Cargo:"
    echo "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
    echo "source ~/.cargo/env"
    echo "Then run this script again."
    exit 1
fi

# Install tuftool if not already installed
if ! command -v tuftool &> /dev/null; then
    echo "Installing tuftool..."
    cargo install tuftool
fi

printf "${GREEN}>> Downloading the root.json file required to validate metadata downloads${NC}\n"
curl -s -O "https://cache.bottlerocket.aws/root.json"
printf "\n"

if [ "$OS" == "linux" ]; then
    sha512sum -c <<< "$SHA512SUM root.json"
elif [ "$OS" == "darwin" ]; then 
    if ! command -v gsha512sum &> /dev/null; then
        echo "gsha512sum could not be found. Please install coreutils via Homebrew:"
        echo "brew install coreutils"
        exit 1
    else
        printf "${GREEN}>> Validating the root.json file checksum${NC}\n"
        gsha512sum -c <<< "$SHA512SUM  root.json"
        if [ $? -ne 0 ]; then
            printf "\n${RED}[ERROR]: Checksum validation failed! Exiting.${NC}\n"
            exit 1
        else 
            printf "\n${GREEN}>> Checksum validation passed!${NC}\n\n"
        fi
    fi
fi

printf "${GREEN}>> Downloading the Bottlerocket OVA${NC}\n"
tuftool download "$(pwd)/download" --target-name "${OVA}" \
   --root ./root.json \
   --metadata-url "https://updates.bottlerocket.aws/2020-07-07/vmware-k8s-${eks_version}/x86_64/" \
   --targets-url "https://updates.bottlerocket.aws/targets/"

if [ $? -ne 0 ]; then
    printf "\n${RED}[ERROR]: OVA download failed! Exiting.${NC}\n"
    exit 1
else 
    printf "\n${GREEN}>> OVA download completed successfully!${NC}\n\n"
fi

printf "${GREEN}>> Importing the Bottlerocket OVA as a template into vSphere${NC}\n"
govc import.spec "download/${OVA}" > bottlerocket-template-spec.json
govc vm.markastemplate "${bottlerocket_template_name}"
