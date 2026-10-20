#!/bin/sh
set -eu

rc alias set rustfs "$RUSTFS_URI" "$RUSTFS_ACCESS_KEY" "$RUSTFS_SECRET_KEY"

tr -d '\r' < "$BUCKETS_LIST" | while read -r bucket || [ -n "$bucket" ]; do
  [ -z "$bucket" ] && continue
  rc bucket create -p "rustfs/$bucket"
done

echo "end init"