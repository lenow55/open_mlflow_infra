#! /bin/sh
set -eu

# RustFS CLI client (rc) is S3-compatible, so it works natively against RustFS.
rc alias set rustfs "$RUSTFS_URI" "$RUSTFS_ACCESS_KEY" "$RUSTFS_SECRET_KEY"

while read -r bucket || [ -n "$bucket" ]; do
  [ -z "$bucket" ] && continue
  rc bucket create -p "rustfs/$bucket"
done <"$BUCKETS_LIST"

echo "end init"
