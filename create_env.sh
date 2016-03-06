#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

mkdir -p $DIR/local/share
cat << EOF > $DIR/local/share/config.site
CFLAGS="-I$DIR/local/include"
CPPFLAGS="-I$DIR/local/include"
LDFLAGS="-L$DIR/local/lib"
EOF
