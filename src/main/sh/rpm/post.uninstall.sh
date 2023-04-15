#!/bin/sh

# De-install script, executed at uninstall end.
echo "### Post-Uninstall"
SMI_PROVIDER=setmy.info
rm -f /etc/profile.d/setmy-info.sh
rm -f /opt/${SMI_PROVIDER}/bin/smi-test

exit ${?}
