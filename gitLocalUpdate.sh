#!/bin/bash

cd

source .bashrc

now=`now`
for dir in `cat julien_utils_private/my_git_repositories.list`; do
cd $dir
rm -f .git/index.lock
git init
# initialize git depository (./.git), if it's not been yet created for $dir

echo -e "\n####\n## gitting $dir...\n####"
 for file in `find . -type f | grep -vP "~$"| grep -vP "/\."`; do
 git add $file;
# add file to depository's index
 done;
echo "Done gitting $dir..."
git commit -m "version $now"
# commit current version
cd
done

# cd ~
# for file in `echo .bashrc .bash_profile`; do
# rm -f .git/index.lock
# echo -e "\n####\n## gitting $file...\n####"
# git add $file;
# echo "Done gitting $file..."
# done;
# git commit -m "version $now"

