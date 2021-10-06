#!/bin/bash

set -e # exit on first error

sqlite3 -init settings.init database.db
