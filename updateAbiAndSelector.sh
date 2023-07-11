# ABI
forge inspect D4AClaimer abi >deployed-contracts-info/frontend-abi/D4AClaimer.json
forge inspect D4ACreateProjectProxy abi >deployed-contracts-info/frontend-abi/D4ACreateProjectProxy.json
forge inspect D4AProtocolReadable abi >deployed-contracts-info/frontend-abi/D4AProtocolReadable.json
forge inspect D4AProtocolSetter abi >deployed-contracts-info/frontend-abi/D4AProtocolSetter.json
forge inspect D4AProtocol abi >deployed-contracts-info/frontend-abi/D4AProtocol.json
forge inspect PermissionControl abi >deployed-contracts-info/frontend-abi/PermissionControl.json

# event selector
echo "{}" >deployed-contracts-info/selector.json
# DRB
forge inspect D4ADrb events | jq --slurpfile existing deployed-contracts-info/selector.json '. + $existing[0]' >temp.json && mv temp.json deployed-contracts-info/selector.json
# Protocol
forge inspect D4AProtocolSetter events | jq --slurpfile existing deployed-contracts-info/selector.json '. + $existing[0]' >temp.json && mv temp.json deployed-contracts-info/selector.json
forge inspect D4AProtocol events | jq --slurpfile existing deployed-contracts-info/selector.json '. + $existing[0]' >temp.json && mv temp.json deployed-contracts-info/selector.json
forge inspect D4AProtocolReadable events | jq --slurpfile existing deployed-contracts-info/selector.json '. + $existing[0]' >temp.json && mv temp.json deployed-contracts-info/selector.json
forge inspect D4ADiamond events | jq --slurpfile existing deployed-contracts-info/selector.json '. + $existing[0]' >temp.json && mv temp.json deployed-contracts-info/selector.json
forge inspect D4ASettings events | jq --slurpfile existing deployed-contracts-info/selector.json '. + $existing[0]' >temp.json && mv temp.json deployed-contracts-info/selector.json
# Permission Control
forge inspect PermissionControl events | jq --slurpfile existing deployed-contracts-info/selector.json '. + $existing[0]' >temp.json && mv temp.json deployed-contracts-info/selector.json
# Create Project Proxy
forge inspect D4ACreateProjectProxy events | jq --slurpfile existing deployed-contracts-info/selector.json '. + $existing[0]' >temp.json && mv temp.json deployed-contracts-info/selector.json
# Naive Owner
forge inspect NaiveOwner events | jq --slurpfile existing deployed-contracts-info/selector.json '. + $existing[0]' >temp.json && mv temp.json deployed-contracts-info/selector.json
# Roayalty Splitter
forge inspect D4ARoyaltySplitterFactory events | jq --slurpfile existing deployed-contracts-info/selector.json '. + $existing[0]' >temp.json && mv temp.json deployed-contracts-info/selector.json
forge inspect D4ARoyaltySplitter events | jq --slurpfile existing deployed-contracts-info/selector.json '. + $existing[0]' >temp.json && mv temp.json deployed-contracts-info/selector.json
# D4A Token
forge inspect D4AERC20 events | jq --slurpfile existing deployed-contracts-info/selector.json '. + $existing[0]' >temp.json && mv temp.json deployed-contracts-info/selector.json
forge inspect D4AERC721WithFilter events | jq --slurpfile existing deployed-contracts-info/selector.json '. + $existing[0]' >temp.json && mv temp.json deployed-contracts-info/selector.json
