#!/bin/bash
 cd $1
 md5sum * > md5sums.txt
 cd ..