#!/bin/bash

last_tag=$( git describe --tags --abbrev=0 2>/dev/null || true )

(
  echo "date: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
  echo sha: $( git log -n1 --format=%H )
  echo build_number: $( [ -n "$last_tag" ] && git rev-list --count "$last_tag"..HEAD || git rev-list --count HEAD )
  echo tag: ${last_tag}
  echo commit: "\"$( git log -n1 --format=%s | sed 's/"/\\"/g')\""
  echo branch: $( git rev-parse --abbrev-ref HEAD )
)
