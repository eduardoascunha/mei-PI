#!/bin/bash

DIR=$(pwd)

export DSS_CONFIG="$DIR"
export DSS_QUERY="$DSS_CONFIG/queries"

mkdir -p output-files
export DSS_PATH="$DIR/output-files"

echo "DSS_CONFIG=$DSS_CONFIG"
echo "DSS_QUERY=$DSS_QUERY"
echo "DSS_PATH=$DSS_PATH"
