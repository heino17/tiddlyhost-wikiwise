#!/bin/bash

(
  echo "date: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
  echo sha: $( git log -n1 --format=%H )
  echo build_number: $( git rev-list --count $( git describe --tags --abbrev=0 )..HEAD )
  echo commit: "\"$( git log -n1 --format=%s | sed 's/"/\\"/g')\""
  echo branch: $( git rev-parse --abbrev-ref HEAD )
)
