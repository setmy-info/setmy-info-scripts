#!/bin/sh

# De-install script, executed at uninstall end.
echo "### Post-Uninstall"

# Only on a real removal. On an upgrade rpm runs this script of the OLD package after the %post
# of the new one, with $1 set to the number of instances that stay, so without this guard every
# upgrade deleted what the new package had just created: the /etc/profile.d link, which is what
# puts /opt/setmy.info/bin on PATH, the command links, and the systemd units, which it also
# disabled. $1 is 0 only when the package is really going away.
if [ "${1:-0}" != 0 ]; then
    echo "Upgrade, keeping the installation of the new package"
    exit 0
fi

SMI_PROVIDER=setmy.info
rm -f /etc/profile.d/setmy-info.sh
rm -f /opt/${SMI_PROVIDER}/bin/smi-test
rm -f /opt/${SMI_PROVIDER}/bin/smi-xvzf
rm -f /opt/${SMI_PROVIDER}/bin/smi-xvjf
rm -f /opt/${SMI_PROVIDER}/bin/smi-xvJf
if command -v systemctl >/dev/null 2>&1; then
    systemctl disable --now setmy-info-deploy.path || true
    systemctl disable --now setmy-info-half-past.timer || true
fi
rm -f /etc/systemd/system/example.service
rm -f /etc/systemd/system/setmy-info-deploy.path
rm -f /etc/systemd/system/setmy-info-deploy.service
rm -f /etc/systemd/system/setmy-info-half-past.service
rm -f /etc/systemd/system/setmy-info-half-past.timer
if command -v systemctl >/dev/null 2>&1; then
    systemctl daemon-reload || true
fi

exit ${?}
