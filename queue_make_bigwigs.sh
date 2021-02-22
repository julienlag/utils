wd=$PWD
genomeFai=$1
for file in `skipcomments bamList`; do
	echo "#!/bin/bash
cd $wd
#set -e
. /etc/profile
PATH=\"~jlagarde/bin/:~jlagarde/julien_utils/:~jlagarde/bin/bin:$PATH\"
#$ -e $wd/$file.queue_make_bigwigs.q.e
#$ -o $wd/$file.queue_make_bigwigs.q.o
make_bigwig.sh $file $genomeFai 
" > $file.queue_make_bigwigs.q;
qsub -q mem_6 $file.queue_make_bigwigs.q;
done;
