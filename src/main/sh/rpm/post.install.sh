#!/bin/sh

# Executed by installer at install step end.
echo "### Post-Install"

username=microservice
if ! id "$username" >/dev/null 2>&1; then
    useradd --system $username
fi

SMI_PROVIDER=setmy.info
ln -f -s /opt/${SMI_PROVIDER}/etc/profile.d/setmy-info.sh /etc/profile.d/setmy-info.sh
if command -v systemctl >/dev/null 2>&1; then
    ln -f -s /opt/${SMI_PROVIDER}/etc/systemd/system/example.service /etc/systemd/system/example.service
fi
ln -f -s /opt/${SMI_PROVIDER}/bin/smi-binary /opt/${SMI_PROVIDER}/bin/smi-test
ln -f -s /opt/${SMI_PROVIDER}/bin/smi-binary /opt/${SMI_PROVIDER}/bin/smi-stealer

exit ${?}
