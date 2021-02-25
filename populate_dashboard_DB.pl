#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use DBI;
use lib "/users/rg/jlagarde/julien_utils/";
use encode_metadata;

$|=1;
#the content of ONE infile (typically a "files.txt" file from UCSC) must relate to only ONE URL prefix

my $url_prefix=$ARGV[0];
if($url_prefix eq '.'){
	$url_prefix='';
}
my $DB_name=$ARGV[1];
my $md5checksums=$ARGV[2];
my $project_name=$ARGV[3];
my $labExpId2metadata_file=$ARGV[4];
my $atUcsc=0;

die $! unless $project_name;

$project_name=uc($project_name);

my %labExpId2metadata=encode_metadata::encode_metadata($labExpId2metadata_file);

#print Dumper \%labExpId2metadata;
#backup current version of DB:
`sleep 1`;
my @date=localtime(time); 
$date[5]=$date[5]+1900;
my $current_time=$date[5]."_".$date[4]."_".$date[3]."_".$date[2]."_".$date[1]."_".$date[0];
#print "@date $current_time\n";

#my $bkpfile=$DB_name."_dump_".$current_time.".sql";
#print "Backed up previous version of DB in $bkpfile\n";
#system("mysqldump -h localhost $DB_name -pencode > /users/rg/jlagarde/projects/encode/scaling/whole_genome/rna_dashboard/database/db_dumps_bkp/$bkpfile") == 0 or die $!;


print "@ARGV \n";
my $dbh = DBI->connect("dbi:mysql:dbname=$DB_name;host=pou","jlagarde","encode", {RaiseError => 0, AutoCommit => 1, PrintError =>1});

open MD5, "$md5checksums";
my %md5checksums=();

while(<MD5>){
	chomp;
	my @line=split /\s+/;
	my $file=$line[1];
	my $md5checksum=$line[0];
	$file=~s/.*\///;
#	if(exists $md5checksums{$file}){
		#die "##################
##############
##############
##############
##############                  SCRIPT DIED                 Duplicate file entry found in $md5checksums. Cannot continue
##############
##############
##############
##############
#";
#	}
#	else{
		$md5checksums{$file}=$md5checksum;
#	}
}
close MD5;


my @minimumSetOfAttributes=('cell','dataType','lab','localization','rnaExtract','type', 'grant', 'view'); #replicate can be absent, in that case it will be set to "last inserted +1", or to "1" if the latter is not possible

### keep attributes in a specific order to satisfy foreign key constraints when populating the tables:
# master tables:
my @attributesOrder=('lab', 'grant', 'dataType', 'cell', 'treatment','localization', 'rnaExtract', 'view');
# 'sample' table:
push(@attributesOrder, 'replicate', 'bioRep');
# 'experiment' table:
push(@attributesOrder, 'subId', 'readType', 'labProtocolId', 'insertLength', 'labExpId');
# 'file' table
push(@attributesOrder,'type', 'size','filenameJulien','mapAlgorithm', 'dateSubmitted', 'fileLab');

if($url_prefix=~/\.ucsc\.edu\//){
	$atUcsc=1;
}



#append slash toURL if absent
print STDERR "url_prefix= $url_prefix\n";
$url_prefix.="/" unless ($url_prefix=~/\/$/ || $url_prefix eq ''); 
print STDERR "url_prefix= $url_prefix\n";

#prepare SQL INSERT statements:
my $insert_grant = $dbh->prepare("INSERT INTO grantName (name, projectName) VALUES (?, ?)");
my $insert_lab = $dbh->prepare("INSERT INTO lab (name) VALUES (?)");
#my $insert_fileView = $dbh->prepare("INSERT INTO fileView (name) VALUES (?)");
my $insert_sample = $dbh -> prepare ("INSERT INTO sample (id, internalName, localization, cell, rnaExtract, treatment, replicate, notes, grantName) VALUES (?,?,?,?,?,?,?,?,?)");
my $insert_experiment = $dbh -> prepare ("INSERT INTO experiment (id, subId, labExpId, technology, readType, techReplicate, sampleName, grantName, lab, insertLength) VALUES (?,?,?,?,?,?,?,?,?,?)");
my $insert_experiment_data_processing = $dbh -> prepare ("INSERT INTO experiment_data_processing (crgAcc, experiment, auth_bool, notes) VALUES (?,?,?,?)");
#my $select_file = $dbh -> prepare ("");
my $select_file = $dbh -> prepare ("SELECT file.atUcsc, file.url, file.atUcsc, file.fileType, file.experiment_data_processing, file.lab, file.fileView, file.releaseN, file.allAttributes FROM file, experiment_data_processing, experiment, sample WHERE file.fileType = ? AND file.lab = ? AND experiment_data_processing.crgAcc = ? AND experiment.techReplicate= ? AND sample.internalName = ? AND experiment.technology = ? AND file.fileView = ? AND file.experiment_data_processing = experiment_data_processing.crgAcc AND experiment_data_processing.experiment = experiment.id AND experiment.sampleName=sample.id;"); #used to return deleted rows. has to be the exact equivalent of the $delete_file
my $delete_file = $dbh -> prepare ("DELETE file FROM file, experiment_data_processing, experiment, sample WHERE file.fileType = ? AND file.lab = ? AND experiment_data_processing.crgAcc = ? AND experiment.techReplicate= ? AND sample.internalName = ? AND experiment.technology = ? AND file.fileView = ? AND file.experiment_data_processing = experiment_data_processing.crgAcc AND experiment_data_processing.experiment = experiment.id AND experiment.sampleName=sample.id;"); #this has to be the exact equivalent of the $select_file

my $insert_file = $dbh -> prepare ("INSERT INTO file (url, atUcsc, fileType, dateSubmitted, experiment_data_processing, size, mapAlgorithm, description, notes, lab, allAttributes, md5sum, fileView, releaseN, filename) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");

my $insert_file_link_experiment_data_processing = $dbh -> prepare ("INSERT INTO file_link_experiment_data_processing (experiment_data_processing, fileId) VALUES (?,?)");

my $select_rnaExtract = $dbh -> prepare ("SELECT count(ucscName) FROM rnaExtract WHERE ucscName = ?");

my $select_cell = $dbh -> prepare ("SELECT count(ucscName) FROM cell WHERE ucscName = ?");
my $select_technology = $dbh -> prepare ("SELECT count(name) FROM technology WHERE name = ?");
my $select_localization = $dbh -> prepare ("SELECT count(ucscName) FROM localization WHERE ucscName = ?");
my $select_fileType = $dbh -> prepare ("SELECT count(*) from fileType WHERE name = ?");
my $select_fileView = $dbh -> prepare ("SELECT count(*) from fileView WHERE name = ?");
#my $select_lastFileNumber = $dbh -> prepare ("SELECT max(fileNumber) from file WHERE experiment = ? AND fileType = ? AND fileView = ?");


open SKIPPED, ">skipped_lines.txt" or die $!;
my $skipped_lines=0;
my $grants_inserted=0;
my $labs_inserted=0;
my $cells_inserted=0;
my $samples_inserted=0;
my $experiments_inserted=0;
my $experiments_data_processings_inserted=0;
my $files_inserted=0;
my $in_lines=0;
my $total_nr_deleted_rows=0;
while(<STDIN>){
	my @deletedRows=();
	my $pooledFile=0;
	next if ($_=~/^#/);
	print STDERR "=\n";
	print STDERR;
	chomp;
	#check format of line
	warn "##################
##############
##############
##############
##############                  SERIOUS ERROR:                 Malformed line in line $. of input file. Cannot continue.
##############
##############
##############
##############
" unless ($_=~/\S+\t(\S+=\S+;\s)+/);
	$in_lines++;
	my $doSkipLine=0;
	my @line=split "\t";
	my $filename=$line[0];
	my %attributes=();
	my @keyvalues=split("; ", $line[1]);
	my $all_attributes=$line[1];
	foreach my $keyvalue (@keyvalues){
		$keyvalue=~/(\S+)=(.+)/;
		$attributes{$1}=$2;
	}
	$attributes{'filenameJulien'}=$filename;
	foreach my $key (@minimumSetOfAttributes){
		unless (exists $attributes{$key}){
			if ($key eq 'cell' || $key eq 'dataType' || $key eq 'type' || $key eq 'lab'){ # cannot guess value for this key
				warn "Mandatory attribute '$key' missing at line $.. Skipped corresponding line\n";
				print STDERR "## Skipped line: $_\n";
				print SKIPPED "$url_prefix$_\n";
				$skipped_lines++;
				$doSkipLine=1;
				last;
			}
			elsif ($key eq 'rnaExtract'){
				$attributes{$key}='longPolyA';
				warn "WARNING: Mandatory attribute '$key' missing at line $.. Set to 'longPolyA'.\n";
			}
			elsif ($key eq 'localization'){
				$attributes{$key}='cell';
				warn "WARNING: Mandatory attribute '$key' missing at line $.. Set to 'cell'.\n";
			}
			elsif ($key eq 'grant'){
				$attributes{$key}='gingeras';
				warn "WARNING: Mandatory attribute '$key' missing at line $.. Set to 'gingeras'.\n";
			}
			elsif ($key eq 'view'){
				$attributes{$key}='';
				warn "WARNING: Mandatory attribute '$key' missing at line $.. Set to '' (empty string).\n";
			}
			#elsif ($key eq 'labProtocolId'){
			#	$attributes{$key}='';
			#	warn "WARNING: Mandatory attribute '$key' missing at line $.. Set to '' (empty string).\n";
			#}
		}
		
		$attributes{$key}=uc($attributes{$key});
		$attributes{$key}=~s/[^A-Z0-9]//g;
		#convert all instances of longRnaSeq and shortRnaSeq to RNASEQ
		if($key eq 'dataType' && $attributes{$key} =~ /RNASEQ/){
			$attributes{$key}= 'RNASEQ';
		}
		elsif($key eq 'lab' && $attributes{$key} =~ /GIS/){ #there are malformed values for GIS sometimes
			$attributes{$key}= 'GIS';
		}
		elsif($key eq 'type' && $attributes{$key} eq 'INSDIST'){ #there are malformed values sometimes
			$attributes{$key}= 'INSDISTRIB';
		}
		elsif($key eq 'dataType' && $attributes{$key} =~ /PET/){
			$attributes{$key}= 'RNAPET';
		}
		elsif($key eq 'view' && $attributes{$key} =~ /EXONGENCV3C/){
			$attributes{$key}= 'EXONSGENCV3C';
		}
	}
	next if ($doSkipLine);
	#print STDERR Dumper \%attributes; 
	my $sample_id='';
	my $sample_grant=undef;
	my $sample_bioRep=undef;
	my $sample_localization=undef;
	my $sample_cell=undef;
	my $sample_rnaExtract=undef;
	my $sample_treatment=undef;
	my $sample_replicate=undef;
	my $sample_notes=undef;
	my $exp_subId=undef;
	my $exp_lab=undef;
	my $exp_technology=undef;
	my $sample_internalName=undef;
	
	my $exp_readType=undef;
	my $exp_insertLength=undef;
	my $exp_techReplicate=undef;
	my $exp_labExpId=undef;
	my $file_type=undef;
	my $file_size=undef;
	my $file_url=undef;
	unless($url_prefix eq ''){
		$file_url=$url_prefix."/".$filename;
	}
	else{
		$file_url=$filename;
	}
	$file_url=~s/([^:])\/\//$1\//g; #remove "slash" duplicates in URL, without touching the one in "http://"
	my $release_number=undef;
	if($file_url =~ /\/release(\d+)\//){
		$release_number=$1;
	}
	my $file_mapAlgorithm=undef;
	my $file_dateSubmitted=undef;
	my $file_lab=undef;
	#my $file_fileNumber=undef;
	my $file_fileView='';
	foreach my $key (@attributesOrder){
		if($key eq 'grant'){
			if($insert_grant -> execute($attributes{$key}, $project_name)){
				$grants_inserted++;
				print STDERR "New row inserted in grantName.name : $attributes{$key}, $project_name\n";
			}
			$sample_id.=$attributes{$key};
			$sample_grant=$attributes{$key};
		}
		elsif($key eq 'lab'){
			if($insert_lab -> execute($attributes{$key})){
				$labs_inserted++;
				print STDERR "New row inserted in table lab.name: $attributes{$key}\n";
			}
			$exp_lab=$attributes{$key};
		}
		elsif($key eq 'view'){
			$select_fileView -> execute ($attributes{$key});
			while ( my @row = $select_fileView->fetchrow_array ) {
				warn "##################
##############
##############
##############
##############                  SERIOUS ERROR:                 Unknown type value: $attributes{$key} at line $.
##############
##############
##############
##############
" unless ($row[0] > 0);
			}
			$file_fileView=$attributes{$key};
		}

		elsif($key eq 'dryLab' || $key eq 'fileLab'){
			if($insert_lab -> execute($attributes{$key})){
				$labs_inserted++;
				print STDERR "New row inserted in table lab.name: $attributes{$key}\n";
			}
			$file_lab=$attributes{$key};
		}
		elsif($key eq 'cell'){
			#if($insert_cell -> execute($attributes{$key})){
			#	$cells_inserted++;
			#	print STDERR "New row inserted in cell.ucscName: $attributes{$key}\n";
			#}
			$select_cell -> execute ($attributes{$key});
			while ( my @row = $select_cell->fetchrow_array ) {
				warn "##################
##############
##############
##############
##############                  SERIOUS ERROR:                 Unknown cell value: $attributes{$key} at line $.
##############
##############
##############
##############
" unless ($row[0] > 0);
			}

			$sample_id.="_".$attributes{$key};
			$sample_cell=$attributes{$key};
		}
		elsif ($key eq 'rnaExtract'){
			$select_rnaExtract -> execute ($attributes{$key});
			while ( my @row = $select_rnaExtract->fetchrow_array ) {
				warn "##################
##############
##############
##############
##############                  SERIOUS ERROR:                 Unknown rnaExtract value: $attributes{$key} at line $.
##############
##############
##############
##############
" unless ($row[0] > 0);
			}
			$sample_id.="_".$attributes{$key};
			$sample_rnaExtract=$attributes{$key};
		}
		elsif ($key eq 'dataType'){
			$select_technology -> execute ($attributes{$key});
			while ( my @row = $select_technology->fetchrow_array ) {
				warn "##################
##############
##############
##############
##############                  SERIOUS ERROR:                 Unknown dataType value: $attributes{$key} at line $.
##############
##############
##############
##############
" unless ($row[0] > 0);
			}
			$exp_technology=$attributes{$key};
		}
		elsif($key eq 'type'){
			$select_fileType -> execute ($attributes{$key});
			while ( my @row = $select_fileType->fetchrow_array ) {
				warn "##################
##############
##############
##############
##############                  SERIOUS ERROR:                 Unknown type value: $attributes{$key} at line $.
##############
##############
##############
##############
" unless ($row[0] > 0);
			}
			$file_type=$attributes{$key};
		}
		elsif ($key eq 'localization'){
			$select_localization -> execute ($attributes{$key});
			while ( my @row = $select_localization->fetchrow_array ) {
				warn "##################
##############
##############
##############
##############                  SERIOUS ERROR:                 Unknown localization value: $attributes{$key} at line $.
##############
##############
##############
##############
##############
" unless ($row[0] > 0);
			}
			$sample_id.="_".$attributes{$key};
			$sample_localization=$attributes{$key};
		}
		elsif($key eq 'replicate'){
			$sample_replicate=$attributes{$key};
			$pooledFile=1 if($sample_replicate eq 'pooled' || $sample_replicate=~/.+,.+/);
		}
		elsif($key eq 'bioRep'){
			$sample_bioRep=$attributes{$key};
			$pooledFile=1 if($sample_bioRep=~/,/);

		}
		elsif($key eq 'subId'){
			$exp_subId=$attributes{$key};
		}
		elsif($key eq 'type'){
			$file_type=$attributes{$key};
		}
		elsif($key eq 'size'){
			$file_size=$attributes{$key};
		}
		elsif($key eq 'mapAlgorithm'){
			$file_mapAlgorithm=$attributes{$key};
		}
		elsif($key eq 'dateSubmitted'){
			$file_dateSubmitted=$attributes{$key};
		}
		elsif($key eq 'readType'){
			$exp_readType=$attributes{$key};
		}
		elsif($key eq 'insertLength'){
			$exp_insertLength=$attributes{$key};
		}
		elsif($key eq 'labExpId'){
			$exp_labExpId=$attributes{$key};
		}
		elsif($key eq 'treatment'){
			$sample_treatment=$attributes{$key};
			$sample_id.="_".$attributes{$key};
		}
		elsif($key eq 'labProtocolId'){
			$sample_internalName=$attributes{$key};
			print "exp_labId = '$sample_internalName'\n";
		}
		elsif($key eq 'techRep'){
			$exp_techReplicate=$attributes{$key};
		}
		delete $attributes{$key};
	}


#####################################################
	# edit this when pooled files are supported:
#####################################################

	if ($pooledFile == 1){
		warn "Pooled file at line $..\n";
		#print STDERR "## Skipped line: $_\n";
		#print SKIPPED "$url_prefix$_\n";
		#		$skipped_lines++;
				#$doSkipLine=1;
		#		next;
	}
	### process list of experiments, in case a file is a pool of experiments
	#first make a consistent, spacechar-free, sorted list of experiments so uniqueness can also be enforced on pooled files (VERY IMPORTANT)
	$exp_labExpId=~s/\s//g;
	my @exp_labExpId=split(",",$exp_labExpId);
	@exp_labExpId=sort(@exp_labExpId);
	$exp_labExpId=join(",",@exp_labExpId);

	
	$sample_internalName=~s/cage//g;
	$sample_internalName=~s/pet//g;


	my $file_notes=undef;
	foreach my $key (keys %attributes){# process the non-mandatory attributes:
		$file_notes.="$key=$attributes{$key}; "
	}
	#print "$file_notes\n";
	
	unless ($sample_replicate){
		if (exists $labExpId2metadata{$exp_labExpId}{'replicate'}){
			$sample_replicate=$labExpId2metadata{$exp_labExpId}{'replicate'};
			print STDERR "Could not find replicate for file '$filename' in input. Set to '$sample_replicate', according to $ARGV[4] (labExpId = '$exp_labExpId').\n";
		}
		else{
			unless($exp_technology eq 'RNACHIP'){
				warn "##################
##############
##############
##############
##############                  SERIOUS ERROR:                 Could not find replicate for file '$filename' neither in input, neither in $ARGV[4] (labExpId = '$exp_labExpId').\n
##############
##############
##############
##############
";
			}
		}
	}
	else{
		if (exists $labExpId2metadata{$exp_labExpId}{'replicate'}){
			if($sample_replicate ne $labExpId2metadata{$exp_labExpId}{'replicate'}){
				warn "##################
##############
##############
##############
##############                  SERIOUS ERROR:                 replicate # for file '$filename' differ in input ('$sample_replicate') and $ARGV[4] ($labExpId2metadata{$exp_labExpId}{'replicate'} , labExpId = '$exp_labExpId').\n
##############
##############
##############
##############
";
			}
		}
		else{
			#do nothing, as $ARGV[4] may contain only gingeras stuff, contrary to input.
			
		}
	}

#	unless($sample_replicate){
	# if absent set to '1'
#		$sample_replicate=1;
#	}
	$sample_id.="_".$sample_replicate;
	
	#insert sample
	if($insert_sample -> execute($sample_id, $sample_internalName, $sample_localization, $sample_cell, $sample_rnaExtract, $sample_treatment, $sample_replicate,undef,$sample_grant)){
		$samples_inserted++;
		print "sample $sample_id inserted\n";
		
	}
	else{
		print "sample $sample_id NOT inserted\n";
	}
	
	#insert experiment
	$exp_techReplicate=1 unless (defined ($exp_techReplicate));
	my $exp_id=$sample_id."_".$exp_lab."_".$exp_technology;
	$exp_id.="_$exp_readType" if(defined ($exp_readType) && $sample_grant ne 'GINGERAS');
	$exp_id.="_$exp_insertLength" if(defined ($exp_insertLength)  && $sample_grant ne 'GINGERAS');
	$exp_id.="_$exp_techReplicate";
	#print STDERR "Sample id: $sample_id ; exp_labId: $sample_internalName;  Exp id: $exp_id.\n";
	if($insert_experiment -> execute($exp_id, $exp_subId, $exp_labExpId, $exp_technology, $exp_readType, $exp_techReplicate, $sample_id, $sample_grant, $exp_lab, $exp_insertLength)){
		$experiments_inserted++;
		print "experiment $exp_id inserted\n";
	}
	else{
	    print "experiment $exp_id NOT inserted\n";
	}
	
	my $experiment_data_processing_id= $exp_id; #takes value of $exp_id for the time being. should be changed to whatever unique "pipeline run" identifier in the future
	if($insert_experiment_data_processing -> execute($experiment_data_processing_id, $exp_id, undef, undef)){
		$experiments_data_processings_inserted++;
		print "experiment_data_processing $experiment_data_processing_id inserted\n";
	}
	else{
	    print "experiment_data_processing $experiment_data_processing_id NOT inserted\n";
	}
	
	$file_lab = $exp_lab unless ($file_lab);
	if($pooledFile == 0){
		#######################
		####    Insert file
		#######################
		
		#######################                        Procedure for dashboard DB updates                                    ####################################################
		# a file entry X
		#  - is identified by: (file.fileType, file.experiment, file.lab) or (sampleName+technology) or "absolute ID (like md5sum of fastq)
		#  - and can correspond to a set of files (each of them identified within a set by their "fileNumber" values)
		#
		#  - should be inserted when:
		#         - there's no file entry corresponding to X
		#
		#  - should be deleted & re-inserted (NOT simply updated, because of (1) file.fileNumber isssues, (2) to avoid possible inconcsitencies between updated and untouched fields of the same row) when:
		#         - the new version is at UCSC
		#         - the new version is not at UCSC, but the URL changed
		#
		#  - should not be touched when:
		#         - current file entry X is marked as "atUcsc" and new file entry is not
		#         - IT'S NOT IDENTIFIED BY AN "internalName"
		########################################################################################################################################################################
		
		### check if an equivalent is already in the DB
		my $fileAlreadyInDB=0;
		my $previousAtUcsc=0;
		my $existsExpId=0;
		#my $fileReleaseInDB=undef;
		#my $fileReleaseGreaterThanInDBoRReleaseNrNotApplicable=0;
		if(defined $sample_internalName){ #if sample/experiment is uniquely identified
			$existsExpId=1;
		}
		if ($existsExpId ==1){
			$select_file -> execute ($file_type, $file_lab, $experiment_data_processing_id, $exp_techReplicate, $sample_internalName, $exp_technology, $file_fileView);
			while ( my @row = $select_file -> fetchrow_array ) {
				$previousAtUcsc= $row[0];
#		$fileReleaseInDB=$row[8];
				shift @row;
				push (@deletedRows, join("\t", @row));
				$previousAtUcsc=1;
			}
#	if( defined($fileReleaseInDB) &&  defined($release_number) ){ 
#		if ($release_number>=$fileReleaseInDB ){
#			$fileReleaseGreaterThanInDBoRReleaseNrNotApplicable=1;
#		}
#		else{
#			$fileReleaseGreaterThanInDBoRReleaseNrNotApplicable=0;
#		}
#	}
#	else{
#		$fileReleaseGreaterThanInDBoRReleaseNrNotApplicable=1;
#	}
#	print "fileReleaseGreaterThanInDBoRReleaseNrNotApplicable = $fileReleaseGreaterThanInDBoRReleaseNrNotApplicable\n";
			
#	if ($existsExpId == 1){
			
			if($previousAtUcsc==1){
				print STDERR "file $file_type, $file_lab, $experiment_data_processing_id, $exp_techReplicate, $sample_internalName, $exp_technology, $file_fileView already in DB\n";
			}
			else{
				print STDERR "file $file_type, $file_lab, $experiment_data_processing_id, $exp_techReplicate, $sample_internalName, $exp_technology, $file_fileView not yet in DB\n";
			}
			unless ($previousAtUcsc == 1 && $atUcsc == 0){ # && $fileReleaseGreaterThanInDBoRReleaseNrNotApplicable == 1){
				my $nr_deleted_rows=0;
				$nr_deleted_rows = $delete_file -> execute($file_type, $file_lab, $experiment_data_processing_id, $exp_techReplicate, $sample_internalName, $exp_technology, $file_fileView);
				
				#while( my @row = $delete_file->fetchrow_array){
				#	$nr_deleted_rows=$row[0];
				$total_nr_deleted_rows = $total_nr_deleted_rows + $nr_deleted_rows;
				#}
				
				if($nr_deleted_rows>0){
					print STDERR "\n#### deleted rows : $nr_deleted_rows , total = $total_nr_deleted_rows\n";
					print STDERR join("\n### Deleted: ", @deletedRows);
				}
			}
		}
		else{
			print STDERR "file $file_type, $file_lab, $exp_techReplicate, $sample_internalName, $exp_technology, $file_fileView sample is not identified by an internalName. Cannot update corresponding DB entry, if it exists\n";
		}
		#$select_lastFileNumber -> execute($exp_id, $file_type, $file_fileView);
		#my $lastFileNumber=undef;
		#while ( my @row = $select_lastFileNumber->fetchrow_array ) {
		#	$lastFileNumber= $row[0];
		#}
		#if(defined($lastFileNumber)){
		#	print "lastFileNumber: $lastFileNumber file_fileNumber: $file_fileNumber\n";
		#	$file_fileNumber=$lastFileNumber+1;
#		print "incr. file_fileNumber: $file_fileNumber\n";
#	}
#	else{
#		print "Undef lastFileNumber\n";
#		$file_fileNumber=1;
#	}
#	print "fileNumber: $file_fileNumber\n";
		unless(exists $md5checksums{$filename}){
			print STDERR "no md5 checksum found for file $filename. Set to NULL.\n";
			$md5checksums{$filename}=undef;
		}
		if($insert_file -> execute($file_url, $atUcsc, $file_type, $file_dateSubmitted, $experiment_data_processing_id, $file_size, $file_mapAlgorithm, undef, $file_notes, $file_lab, $all_attributes, $md5checksums{$filename}, $file_fileView, $release_number, $filename)){
			$files_inserted++;
			print "file $filename ($exp_id - $file_fileView - $file_type ) inserted\n";
		}
		else{
			print "### file $filename ($exp_id - $file_fileView - $file_type ) NOT inserted\n";
		}
	}
}



$dbh->disconnect;

#print STDERR "\n\nWARNING: $skipped_lines lines skipped in input file. See file 'skipped_lines.txt' for details.\n\n" if ($skipped_lines>0);
my $should_be_inserted=$in_lines-$skipped_lines;


print STDERR "

#################################
# Lines in input file:
# \t$in_lines
# Skipped lines in input file 
# \t$skipped_lines
# Rows inserted:
# \t$grants_inserted in 'grantName'
# \t$labs_inserted in 'labs'
# \t$cells_inserted in 'cell'
# \t$samples_inserted in 'sample'
# \t$experiments_inserted in 'experiment'
# \t$experiments_data_processings_inserted in 'experiment_data_processing'
#### Deleted $total_nr_deleted_rows rows in previous DB.
";
	
print STDERR "# \t$files_inserted in 'file' (should be $should_be_inserted)
#################################
";

