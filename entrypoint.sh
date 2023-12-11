#!/usr/bin/env bash

ibus-daemon -drx

if [ -n "${JMS_TOKEN}" ]; then
    cd /opt/app || exit 1
    /opt/py3/bin/python main.py
else
    GTK_IM_MODULE=xim /usr/bin/chromium --gtk-version=4 --start-maximized --disable-gpu --ignore-certificate-errors --no-sandbox --disable-dev-shm-usage
fi