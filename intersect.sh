cd $2; 
. /etc/profile
PATH="/users/rg/jlagarde/julien_utils:$PATH"
mkdir /home/jlagarde/tmp
TMPDIR="/home/jlagarde/tmp/"
echo $1
chr=$1
dir=$2
filelist=$3
for file1 in `cat $2/$3|grep -P "\.$chr\."`; do
set1=`echo $file1`;
echo "set1: $set1"
for file2 in `cat $2/$3|grep -P "\.$chr\."`; do
set2=`echo $file2`;
echo "set2: $set2"
if [ "$file2" !=  "$file1" ]
then
mkdir $dir/$chr
if [ ! -s $dir/$chr/$set1.intersect.$set2.txt ]
then
echo "creating $set1.intersect.$set2.txt"
if [ ! -a $TMPDIR/$set1.$chr.sort.gff ]
then
\cp -f $file1  $TMPDIR/$set1.$chr.sort.gff
fi
#gawk -v toadd=ex -v fileRef=~/projects/encode/scaling/whole_genome/affy_probe_coords/$chr.hg18.probes.sortedbed.gz.interrogated_regions.gff -f ~jlagarde/projects/encode/scaling/whole_genome/awg_200812/data/Awk/overlap_better_all_and_i_info_refgff_inbed.awk $TMPDIR/tf_overtr_overex.proj.gff.chr1.gff.sorted.bed

#total nucleotides covered by file1
if [ ! -s $dir/$chr/$set1.txt ]
then
if [ ! -s $TMPDIR/$set1.$chr.sort.gff ]
then
echo "0" > $dir/$chr/$set1.txt
else
#printf "calc nt in set $set1\n"; 
cat $TMPDIR/$set1.$chr.sort.gff |awk '{sum+=$5-$4+1; print sum}' | tail -n1 > $dir/$chr/$set1.txt
fi
fi
if [ ! -a $TMPDIR/$set2.$chr.sort.bed ]
then
gff2bed $file2 > $TMPDIR/$set2.$chr.sort.bed
fi
#total nucleotides covered by file2
if [ ! -s $dir/$chr/$set2.txt ]
then
if [ ! -s $TMPDIR/$set2.$chr.sort.bed ]
then
echo "0" > $dir/$chr/$set2.txt
else
#printf "calc nt in set $set2\n"; 
cat $TMPDIR/$set2.$chr.sort.bed |awk '{sum+=$3-$2; print sum}' | tail -n1 > $dir/$chr/$set2.txt
fi
fi
if [ ! -s $TMPDIR/$set2.$chr.sort.bed ] || [ ! -s $TMPDIR/$set1.$chr.sort.gff ]
then
echo "0" > $dir/$chr/$set1.intersect.$set2.txt
echo "" > $dir/$chr/$set1.intersect.$set2.gff
else
gawk -v toadd=ex -v fileRef=$TMPDIR/$set1.$chr.sort.gff -f /users/rg/jlagarde/julien_utils/overlap_better_all_and_i_info_refgff_inbed.awk $TMPDIR/$set2.$chr.sort.bed > $dir/$chr/$set1.intersect.$set2.gff
#printf "calc nt in set $set1 / $set2\n"; 
ssv2tsv $dir/$chr/$set1.intersect.$set2.gff |gawk '$NF>0'|cut -f5| sed -e 's/:/\
/g' | grep "," | sed -e 's/,/ /g' | awk '{print sum+=$1}' |  tail -n1 > $dir/$chr/$set1.intersect.$set2.txt
fi
rm -f $TMPDIR/$set1.$chr.sort.gff $TMPDIR/$set2.$chr.sort.bed
#gzip ~jlagarde/projects/encode/scaling/whole_genome/awg_200812/intersect/$chr/$set1.intersect.$set2.gff&
rm $dir/$chr/$set1.intersect.$set2.gff&
else
echo "skipping $set1.intersect.$set2.txt"
fi
fi
done
done

