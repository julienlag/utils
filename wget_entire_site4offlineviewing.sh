#!/bin/bash
#wget --wait=5 -r -p --no-parent -U Firefox --convert-links --no-clobber --page-requisites --html-extension --convert-links --restrict-file-names=windows --domains $1 --no-parent $1
wget --wait=5 -r -p --no-parent -U Firefox --convert-links $1 
