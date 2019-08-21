#!/bin/bash

TYPE="https"

if [ "$1" == "http" ]; then
	TYPE="http"
fi

for i in {0..20000}; do
	curl -k ${TYPE}://195.251.251.27:3000
done
