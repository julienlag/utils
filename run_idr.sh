#/bin/bash


set -e    #die immediately if any command fails

## NOT TO BE RUN IN PARALLEL IN THE SAME DIRECTORY!!



##########################################
#    read arguments and set variables    #
##########################################

gffAttrToIDR=$1        # value to IDR (i.e. GFF attribute to look for in the 9th field of input files). Usually "reads". Example:
                       # chr1    ENSEMBL transcript      3044314 3044814 .       +       .       transcript_id "ENSMUST00000160944"; locus_id "chr1:3044314-3044814W"; gene_id "ENSMUSG00000090025"; reads 0.000000; length 501; RPKM 0.000000

filePairsFile=$2       # TSV file containing GFF files to pair when calculating IDR. One line per pair of file, Each line is tab-separated.
                       # If the two fields contain the same filename, it is assumed that we're dealing with a singleton (hence the corresponding GFF will simply be appended "iIDR \"NA\";" to each of its lines
                       # Example:
                       # /users/rg/jlagarde/projects/encode/scaling/whole_genome/dcc_submission/to_submit/from_cshl_to_load/20121121_mouse/flux/flux_out/SID38132_BC19DCACXX_6.mm65.long.gtf.gtf    /users/rg/jlagarde/projects/encode/scaling/whole_genome/dcc_submission/to_submit/from_cshl_to_load/20121121_mouse/flux/flux_out/SID38133_BC19DCACXX_6.mm65.long.gtf.gtf
                       # the filename should contain the replicate ID ($labExpId, e.g. "SID38132") as prefix followed by an underscore "_" or a dot ".".

view=$3                # string to write in the output filename between labExpId pair and file extension. Example:
                       # view="TranscriptEnsV65" -> output file is  SID38132-SID38133_TranscriptEnsV65.gtf

scriptsPath=$4         # full path to directory containing formatting perl and matlab scripts. Example:
                       # /users/rg/jlagarde/julien_utils/

gffElementId=$5        # attribute to look for in the input GFF in order to identify the elements to IDR. Example:
                       # "exon_id" if exon quantifications
                       # "transcript_id" if transcript quantifications
                       # "gene_id" if gene quantifications

outDir=$6              # output directory

if [ -n "$7" ]
then
idrStep=$7             #step for IDR calculation
else
idrStep=1           # should be set to 1, unless you know what you're doing
fi


rm -f idrTmpFiles2removeAtTheEnd.list

############################################
#      summarize parameters for user       #
############################################
echo "Parameters are:"
printf "\tgffAttrToIDR = $gffAttrToIDR\n"
printf "\tfilePairsFile = $filePairsFile\n"
printf "\tview = $view\n"
printf "\tscriptsPath = $scriptsPath\n"
printf "\tgffElementId = $gffElementId\n"
printf "\tidrStep = $idrStep\n"
echo
echo "All set, let's go"
echo
#cp $scriptsPath/funIDRnpFile.m . #copying seems to be the only way to make Matlab understand where this file is)
mkdir -p $outDir

cat $filePairsFile | while read file1 file2; do
	[ -z "$file1" ] && [ -z "$file2" ] && continue
		labExpId1=`basename $file1| awk -F"[_.]" {'print $1'}`
		labExpId2=`basename $file2| awk -F"[_.]" {'print $1'}`
		echo "Pair of labExpIds is: $labExpId1, $labExpId2"
	if [ "$file1" = "$file2" ]
	then
		printf "\tSame file1 and file2. Singleton replicate.\n";
		cat $file1 |awk '{print $0" iIDR \"NA\";"}' > $outDir/$labExpId1\_$view.idr.$gffAttrToIDR.gff
		printf "\tdone. Output file is in $outDir .\n"
	else
 		printf "\tPooling and converting to matchedPeak format...\n"
		$scriptsPath/gff2matchedPeaks.pl $file1 $file2 $gffElementId $gffAttrToIDR >$labExpId1\-$labExpId2.$view.matchedPeaks.txt
		echo "${labExpId1}-${labExpId2}.$view.matchedPeaks.txt" >> idrTmpFiles2removeAtTheEnd.list
		cat $labExpId1\-$labExpId2.$view.matchedPeaks.txt  | sort -k1,1 -d |awk '$2!=0||$4!=0 {print $2"\t"$4}' > tmp.$labExpId1\-$labExpId2.$view.matchedPeaks.txt
		echo "tmp.${labExpId1}-${labExpId2}.$view.matchedPeaks.txt" >> idrTmpFiles2removeAtTheEnd.list
		printf "\tdone\n"
		printf "\tRunning iIDR...\n"
		R --slave --args tmp.$labExpId1\-$labExpId2.$view.matchedPeaks.txt tmp.$labExpId1\-$labExpId2.$view.iIDR.out $idrStep 2 < $scriptsPath/npIDR.r
		echo tmp.${labExpId1}-${labExpId2}.$view.iIDR.out >> idrTmpFiles2removeAtTheEnd.list
		cat  $labExpId1\-$labExpId2.$view.matchedPeaks.txt | sort -k1,1 -d|awk '$2!=0||$4!=0 {print $1}' |paste tmp.$labExpId1\-$labExpId2.$view.iIDR.out - > $labExpId1\-$labExpId2.$view.iIDR.out
		echo ${labExpId1}-${labExpId2}.$view.iIDR.out >> idrTmpFiles2removeAtTheEnd.list
		printf "\tdone\n"
		printf "\tMaking final GFF file with IDR'd elements...\n"
		$scriptsPath/idr2gff.pl $file1 $file2 $labExpId1\-$labExpId2.$view.iIDR.out $labExpId1\-$labExpId2.$view.matchedPeaks.txt $gffElementId  $gffAttrToIDR transcript_id transcript_ids exon_id locus_id gene_id gene_ids id length | $scriptsPath/sortgff > $outDir/$labExpId1\-$labExpId2\_$view.idr.$gffAttrToIDR.gff
		printf "\tdone. Output file is in $outDir .\n"
	fi
   	echo

done


#####################
#      cleanup      #
#####################
echo "Cleaning up temp files (moving to ./tmpIdr/) ..."
mkdir -p ./tmpIdr/
#mv -f funIDRnpFile.m ./tmpIdr/
#mv -f out ./tmpIdr/
for file in `cat idrTmpFiles2removeAtTheEnd.list`; do mv -f $file ./tmpIdr/; done
rm -f idrTmpFiles2removeAtTheEnd.list
echo "done"
exit 0