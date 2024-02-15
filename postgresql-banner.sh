#!/bin/bash
# Script name: postgresql-banner.sh
# Description: This small script shows some basic information about the PostgreSQL database. Should be placed at location /etc/profile.d/ with 644 permissions
# Version: 1.0

PGDATALOC=$(systemctl cat postgresql.service | grep "Environment=PGDATA=" | awk -F'=' '{print $3}')
PGREADY=5432

echo ""
echo "########################################################"
echo "     This is a PostgreSQL database server!"
echo "########################################################"
echo ""
echo "postgresql.service: $(systemctl is-active postgresql.service)"
echo "PGDATA: ${PGDATALOC}"
echo "Port: ${PGREADY}"
echo ""
