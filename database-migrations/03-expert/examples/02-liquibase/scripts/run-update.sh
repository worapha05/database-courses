#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

liquibase --defaults-file=liquibase.properties updateSQL | tee /tmp/liquibase-update.sql
liquibase --defaults-file=liquibase.properties update
liquibase --defaults-file=liquibase.properties status
