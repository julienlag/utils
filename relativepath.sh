#!/bin/bash

set -e

source=$PWD # needs fullpath
fullpath=$1 

common_part=$source
back=
while [ "${fullpath#$common_part}" = "${fullpath}" ]; do
  common_part=$(dirname $common_part)
  back="../${back}"
done

relative="${back}${fullpath#$common_part/}"

echo $relative;
