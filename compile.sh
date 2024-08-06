#!/bin/bash
rm -rf $(dirname "$0")/compile
rm $(dirname "$0")/attrition.vpk || true
mkdir $(dirname "$0")/compile
cp -r $(dirname "$0")/modes $(dirname "$0")/compile
cp -r $(dirname "$0")/scripts $(dirname "$0")/compile
cp $(dirname "$0")/addoninfo.txt $(dirname "$0")/compile/addoninfo.txt
/home/ratchet/envs/callisto/bin/python -m vpk.cli attrition.vpk -cv=1 -c $(dirname "$0")/compile