#!/usr/bin/env bash

if [ -n "${JMS_TOKEN}" ]; then
    cd /opt/app || exit 1
    /opt/py3/bin/python main.py
else
    /usr/bin/google-chrome --start-maximized --disable-gpu --ignore-certificate-errors --no-sandbox --disable-dev-shm-usage
fi