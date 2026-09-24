# PLACEHOLDER-BEGIN #
MESSAGE("-- base var.cmake")

# /var is not packaged. The right path is /var/opt/setmy.info, what smi-var-location prints, and
# the rpm post.install.sh and deb postinst create it with its incoming directory. It cannot be an
# install rule: a relative DESTINATION goes under the package prefix, which made the unused
# /opt/setmy.info/var/opt/setmy.info, and an absolute one is not redirected by the CPack staging
# install, which then writes into the real /var of the build machine.

# PLACEHOLDER-END #
