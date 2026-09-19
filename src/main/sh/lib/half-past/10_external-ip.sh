#!/bin/sh

# Copyright (C) 2026 Imre Tabur <imre.tabur@mail.ee>

VAR_DIR=$(smi-var-location)
if [ -z "${VAR_DIR}" ]; then
    echo "10_external-ip.sh: setmy.info var directory not found" >&2
    exit 1
fi

exec smi-external-ip "${VAR_DIR}/ip.txt"
