#!/bin/sh
matlab_exec=matlab
X="${1}(${2},${3},${4},${5})"
echo ${X} > matlab_command_${2}.m
#cat matlab_command_${2}.m
( ${matlab_exec} -nojvm -nodisplay -nosplash < matlab_command_${2}.m ) > out
rm matlab_command_${2}.m