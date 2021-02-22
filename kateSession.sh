#!/bin/bash
cd /users/rg/jlagarde/READMEs/
for file in `find . -type f | grep -vP "~$"| grep -vP "/\."`; do kate -u $file; done
sleep 5
cd /users/rg/jlagarde/julien_utils/
for file in `find . -type f | grep -vP "~$"| grep -vP "/\." | grep -vP ".tgz"`; do kate -u $file& done
