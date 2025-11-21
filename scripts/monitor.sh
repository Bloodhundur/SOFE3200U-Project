#!/bin/bash

base_dir="$(dirname "$(realpath "$0")")/.."
log_dir="${base_dir}/logs"
mkdir -p "$log_dir"

timestamp="$(date +"%Y-%m-%d-%H-%M-%S")"
top -bn1 > "${log_dir}/top_${timestamp}.txt"

