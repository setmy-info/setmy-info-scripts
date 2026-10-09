#!/bin/sh

# Executed by installer at install step end.
echo "### Post-Install"

USER_NAME=microservice
if ! id "${USER_NAME}" >/dev/null 2>&1; then
    # useradd --shell /sbin/nologin --no-create-home ${USER_NAME}
    # useradd --system --shell /sbin/nologin --no-create-home
    useradd --system ${USER_NAME}
fi

DAGU_USER_NAME=dagu
if ! id "${DAGU_USER_NAME}" >/dev/null 2>&1; then
    useradd --system --shell /sbin/nologin --no-create-home ${DAGU_USER_NAME}
fi

DEPLOY_USER_NAME=deploy
if ! id "${DEPLOY_USER_NAME}" >/dev/null 2>&1; then
    # The uploader needs a shell, scp does not work with nologin, and a home for its
    # authorized_keys. The key itself is installed by whoever owns the external system.
    useradd --system --create-home --home-dir /home/${DEPLOY_USER_NAME} --shell /bin/sh ${DEPLOY_USER_NAME}
fi

SMI_PROVIDER=setmy.info
ln -f -s /opt/${SMI_PROVIDER}/etc/profile.d/setmy-info.sh /etc/profile.d/setmy-info.sh
if command -v systemctl >/dev/null 2>&1; then
    ln -f -s /opt/${SMI_PROVIDER}/etc/systemd/system/example.service /etc/systemd/system/example.service
    ln -f -s /opt/${SMI_PROVIDER}/etc/systemd/system/setmy-info-deploy.path /etc/systemd/system/setmy-info-deploy.path
    ln -f -s /opt/${SMI_PROVIDER}/etc/systemd/system/setmy-info-deploy.service /etc/systemd/system/setmy-info-deploy.service
    ln -f -s /opt/${SMI_PROVIDER}/etc/systemd/system/setmy-info-half-past.service /etc/systemd/system/setmy-info-half-past.service
    ln -f -s /opt/${SMI_PROVIDER}/etc/systemd/system/setmy-info-half-past.timer /etc/systemd/system/setmy-info-half-past.timer
    systemctl daemon-reload || true
    systemctl enable --now setmy-info-deploy.path || true
    systemctl enable --now setmy-info-half-past.timer || true
fi
ln -f -s /opt/${SMI_PROVIDER}/bin/smi-binary /opt/${SMI_PROVIDER}/bin/smi-test
ln -f -s /opt/${SMI_PROVIDER}/bin/smi-binary /opt/${SMI_PROVIDER}/bin/smi-stealer
ln -f -s /opt/${SMI_PROVIDER}/bin/smi-extract /opt/${SMI_PROVIDER}/bin/smi-xvzf
ln -f -s /opt/${SMI_PROVIDER}/bin/smi-extract /opt/${SMI_PROVIDER}/bin/smi-xvjf
ln -f -s /opt/${SMI_PROVIDER}/bin/smi-extract /opt/${SMI_PROVIDER}/bin/smi-xvJf
# The external system uploads a package as the deploy user and says what it wants by the
# directory it uploads into, draft or published, so both have to exist and be writable by that
# user when this package is installed. It cannot set an environment variable, which is why the
# directory is the only signal; smi-incoming-deploy turns it into SMI_STAGE for the scriptlets.
mkdir -p /var/opt/${SMI_PROVIDER}
mkdir -p /var/opt/${SMI_PROVIDER}/incoming
mkdir -p /var/opt/${SMI_PROVIDER}/incoming/draft
mkdir -p /var/opt/${SMI_PROVIDER}/failed
mkdir -p /var/opt/${SMI_PROVIDER}/failed/draft
chown ${DEPLOY_USER_NAME}:${DEPLOY_USER_NAME} /var/opt/${SMI_PROVIDER}/incoming /var/opt/${SMI_PROVIDER}/incoming/draft
chmod 0755 /var/opt/${SMI_PROVIDER}/incoming /var/opt/${SMI_PROVIDER}/incoming/draft
if command -v restorecon >/dev/null 2>&1; then
    restorecon -R /var/opt/${SMI_PROVIDER} || true
fi

exit ${?}
