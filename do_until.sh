#!/bin/bash

until ./build.sh 1; do
    echo " failed,  retrying..."
done

echo " Successfully done."