#!/bin/sh

# Executed by installer at install step end.
echo "### Post-Install"
useradd --system microservice
SMI_PROVIDER=setmy.info
ln -f -s /opt/${SMI_PROVIDER}/etc/profile.d/setmy-info.sh /etc/profile.d/setmy-info.sh
ln -f -s /opt/${SMI_PROVIDER}/etc/systemd/system/example.service /etc/systemd/system/example.service
ln -f -s /opt/${SMI_PROVIDER}/bin/smi-binary /opt/${SMI_PROVIDER}/bin/smi-test
ln -f -s /opt/${SMI_PROVIDER}/bin/smi-binary /opt/${SMI_PROVIDER}/bin/smi-stealer

exit ${?}
