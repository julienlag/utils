#!/bin/bash
cat *.jobShOutErr.tsv |jobs_exit.sh - | awk '$4==0 || $5==1'
