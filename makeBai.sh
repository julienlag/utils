#!/bin/bash

set -e

source ~/julien_utils/check_pipe_exit.sh

file=$1

echo "$file
" >&2
new=`dirname $file`/`basename $file`.bai

if [ ! -f $new ];
then
echo "Making BAI..." >&2
uuid=`uuidgen`
# make temporary BAI first, so we don't end up with a truncated BAI if the process crashes
samtools index $file tmp.$uuid
#ls -l tmp.$uuid
\mv tmp.$uuid $new
echo "done. Output in $new ." >&2
else
echo "$new already exists. Skipped." >&2
fi

echoerr "XXdoneXX"
exit 0;