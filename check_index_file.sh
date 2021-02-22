#!/bin/bash
set -e
file=$1
echo "Removing lines revoked/replaced"
 cat $file| grep -vP "(revoked)|(replaced)|(renamed)" > tmp
echo "done"




#add replicate number when absent (i.e. for pooled files)

#human gingeras
for dir in `skipcomments DCC_dirs.list |grep Cshl`; do \mv $dir/files.txt $dir/files.txt.bkp2; echo $dir; add_rep.pl /users/rg/jlagarde/projects/encode/scaling/whole_genome/dcc_submission/samples/all_Gingeras_samples.tsv human $dir/files.txt.bkp2 > $dir/files.txt; tkdiff $dir/files.txt.bkp2 $dir/files.txt; done










echo "Removing lines where identifying attributes are absent"
 cat tmp| removeIncompleteLinesFromIndexFile.pl - view lab cell labExpId localization readType replicate rnaExtract type dataType grant > tmp2
echo "done"




exit 0
############################
# detect duplicate files, based on identifying tuples
############################
# cat ~/public_html/encode_RNA_dashboard/mm9/1376932708606328360.mm9_RNA_dashboard_files.txt.crg | grep TranscriptEnsV65|grep 38132|discoverDuplicateLinesFromIndexFile.pl - view cell localization readType replicate rnaExtract lab age  strain
# cat ~/public_html/encode_RNA_dashboard/mm9/1376932708606328360.mm9_RNA_dashboard_files.txt.crg | discoverDuplicateLinesFromIndexFile.pl - view cell localization readType replicate rnaExtract lab grant age strain treatment sex type

  cat tmp2 | grep -v type=bai | discoverDuplicateLinesFromIndexFile.pl - view cell localization readType replicate rnaExtract lab grant age strain treatment sex protocol insertLength fileLab 
#WARNING adding "type" will miss gtf/gff duplicates

# cat ~/public_html/encode_RNA_dashboard/mm9/1376932708606328360.mm9_RNA_dashboard_files.txt.crg | grep lab=CSHL|grep -v type=bai|discoverDuplicateLinesFromIndexFile.pl - view cell localization readType replicate rnaExtract lab age  strain
# cat hg19_RNA_dashboard_files.txt.crg| grep -v "type=bai;" | discoverDuplicateLinesFromIndexFile.pl - view cell localization readType replicate rnaExtract lab                                                                                                                                                                                                            cat hg19_RNA_dashboard_files.txt.crg| grep -v "type=bai;" | discoverDuplicateLinesFromIndexFile.pl - cell localization rnaExtract lab fileLab readType replicate protocol insertLength view > tmp

# if dateProcessed present, take latest one. if version present, take latest one. if ucsc version present, take it-

# homogeneize file types. if not BAM or BAI, everything should be GZIPPED.

#identify missing views

# verify paths
