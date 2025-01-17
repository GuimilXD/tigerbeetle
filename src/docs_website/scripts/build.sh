#!/usr/bin/env bash

# Disable shellcheck for this script: it is rather complex, and the proper here would be to
# get rit of it altogether, but it is not completely obvious what the end state we want here yet.
# shellcheck disable=all

set -eu

repo="https://github.com/tigerbeetle/tigerbeetle"
root="$(pwd)"
rm -rf pages
cp -r ../../docs pages

# Rewrite links to clients
mkdir pages/clients
clients="go java dotnet node python"
for client in $clients; do
    # READMEs are rewritten to a local path since they will be on the docs site.
    for page in $(find pages -type f); do
        # Need a relative path for the link checker to work.
        readme="$root/pages/clients/$client.md"
        relpath="$(realpath --relative-to="$(dirname $root/$page)" "$readme")"
        sed -i "s@/src/clients/$client/README.md@$relpath@g" "$page"
    done

    cp ../../src/clients/$client/README.md pages/clients/$client.md
done
echo '{ "label": "Client Libraries", "position": 5 }' >> pages/clients/_category_.json

# Everything else will be rewritten as a link into GitHub.
find pages -type f | xargs -I {} sed -i "s@/src/clients/@$repo/blob/main/src/clients/@g" {}

for page in $(ls pages/*.md); do
    if ! [[ "$page" == "pages/README.md" ]] && \
       ! [[ "$page" == "pages/quick-start.md" ]]; then
        rm "$page"
    fi
done

# Validate links
npx remark --use remark-validate-links --frail pages

# Build the site
rm -rf build
npx docusaurus build
