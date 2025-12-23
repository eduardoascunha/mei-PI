#!/bin/bash

echo "Start"

for val in {1..22}; do
    name="q${val}.sql"
    ./qgen -s 1 $val > "$name"
    echo "$name done"
done

echo "Finish"
