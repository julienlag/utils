 for chr in `cat ~/chr.list`; do awk -v chr=$chr '$1==chr' $1 > $1.$chr.bed; done
