#!/bin/sh
set -e

if supervisorctl -c "/etc/supervisor/supervisord.conf" status | grep -v "RUNNING"; then
    exit 1
else
    exit 0
fi