#!/bin/sh

# De-install script, executed at uninstall end.
echo "### Post-Uninstall"
SMI_PROVIDER=setmy.info
rm -f /etc/profile.d/setmy-info.sh
rm -f /opt/${SMI_PROVIDER}/bin/smi-test
if command -v systemctl >/dev/null 2>&1; then
    systemctl disable --now setmy-info-deploy.path || true
fi
rm -f /etc/systemd/system/example.service
rm -f /etc/systemd/system/setmy-info-deploy.path
rm -f /etc/systemd/system/setmy-info-deploy.service
if command -v systemctl >/dev/null 2>&1; then
    systemctl daemon-reload || true
fi

exit ${?}
