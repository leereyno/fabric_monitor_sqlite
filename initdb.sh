#!/bin/bash

set -e # exit on first error

/bin/rm -f database.db

sqlite3 -batch database.db < schema.sql

sqlite3 -batch database.db < views.sql

sqlite3 -batch database.db < firmware.sql
