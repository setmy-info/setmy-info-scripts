#!/bin/sh

# Copyright (C) 2026 Imre Tabur <imre.tabur@mail.ee>

# The deploying itself is smi-deploy, a command of this toolset, so that every project deploys
# the same way and no project writes its own scp and ssh again. This file stays as the name the
# build of this project calls, and asks the toolset where its commands are, with the same
# location helper every other script of ours uses.
#
# Usage: deploy.sh upload|handover|deploy PACKAGE

exec "$(smi-bin-location)/smi-deploy" "$@"
