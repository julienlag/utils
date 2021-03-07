#!/bin/bash

#set -e
source ~jlagarde/.bashrc
bkpFile=~jlagarde/.bash_history_bkp/`date +%Y%m%d%H%M%S`.bash_history.bkp
mv -f ~jlagarde/.bash_history $bkpFile
touch ~jlagarde/.bash_history # to avoid trying to back up a non-existent file the next time around
chmod a-r-x $bkpFile
chmod u+r+w $bkpFile
#echo  "$bkpFile XXdoneXX"
