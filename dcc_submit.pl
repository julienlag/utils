#!/usr/bin/perl -w
use strict;
use warnings;
use lib "/users/rg/jlagarde/julien_utils/";
use encode_metadata;
use Data::Dumper;
use Getopt::Long;
#use Getopt::Long qw(:config debugh);
$|=1;
my $today=`date +%Y%m%d`;
chomp $today;
my $filelist='';
my $labExpId2metadata_file='';
my $sourceLab='';
my $labVersion='';
my $filenames2labExpIds_file='';
my $explicit_readme_file='';
my $organism='';
my %ReadmesNotCopied=();
GetOptions (
	'filelist=s' => \$filelist,
	'labExpId2metadata_file=s' => \$labExpId2metadata_file,
	'sourceLab=s' => \$sourceLab,
	'labVersion=s' => \$labVersion,
	'filenames2labExpIds_file=s' => \$filenames2labExpIds_file,
	'readme=s' => \$explicit_readme_file,
	'organism=s' => \$organism
	);

die "Unknown sourceLab" unless ($sourceLab && ($sourceLab eq 'cshl' || $sourceLab eq 'gis' || $sourceLab eq 'riken' || $sourceLab eq 'caltech' || $sourceLab eq 'licr' || $sourceLab eq 'psu' || $sourceLab eq 'uw' || $sourceLab eq 'sydh' || $sourceLab eq 'illumina' || $sourceLab eq 'remc' || $sourceLab eq 'encode'));
die unless ($filelist && $labExpId2metadata_file);


#print "$labExpId2metadata_file\n";
print STDERR "'$labExpId2metadata_file','0','$organism'\n";

my %labExpId2metadata=();

if($sourceLab eq 'cshl' || $sourceLab eq 'gis' || $sourceLab eq 'riken'){
	%labExpId2metadata=encode_metadata::encode_metadata($labExpId2metadata_file,0,$organism);
}
else{ #caltech or others, don't touch labExpId or bioRep
	%labExpId2metadata=encode_metadata::encode_metadata($labExpId2metadata_file,1,$organism);
}

#print Dumper \%labExpId2metadata;

# my %fn2labExpIds=();
# if($sourceLab eq 'gis'){
# 	die unless ($filenames2labExpIds_file);
# 	open FN2LABEXPIDS, "$filenames2labExpIds_file" or die $!;
# 	while(<FN2LABEXPIDS>){
# 		chomp;
# 		my @line=split "\t";
# 		$fn2labExpIds{$line[0]}=$line[1];
# 	}
# 	close FN2LABEXPIDS;
# }


#print Dumper \%labExpId2metadata;
my %labExpId_view_file=();
open FILELIST, "$filelist" or die $!;
while(<FILELIST>){
   	print STDERR "File: $_";
	chomp;
	my $filepath=$_;
	unless($filepath=~/.*\/\S+$/){
		$filepath="./".$filepath;
	}
	$filepath=~/.*\/(\S+)$/ or die $!;
	my $file=$1;
	$file=~/(.*)\.(\S+)$/;
	my $prefix=$1;
	my $ext=lc($2);
	my $labExpIds=undef;

	if($sourceLab eq 'riken'){
		if($prefix=~/([A-Z]\d\d-[A-Z]\d\d)/ || $prefix=~/([A-Z]\d\d)/ || $prefix=~/(CT\S+)/){
			#print "OK, pooled file\n";
			print STDERR "Prefix: $prefix\n";
			$prefix=~/([-A-Za-z0-9]+)\.*/;
			#print STDERR $1;
			$labExpIds=$1;

		}
		else{
			die "Malformed filename? $prefix $file $filepath\n";
		}
	}
	elsif($sourceLab eq 'gis'){
		if($prefix=~/^(\S+)_/){
			# my $sample=$1;
			# $prefix=~/(Rep\d)/;
			# my $rep=$1;
			# $sample.=$rep;
			# die "Unknown labExpId for $filepath.\n" unless (exists ($fn2labExpIds{$sample}));
			$labExpIds=$1;
		}
		else{
			$labExpIds=$prefix;
		}
	#print "$ext\n";
	}

	elsif($sourceLab eq 'cshl'){
		if($prefix=~/([A-Z]ID\d+)\S+([A-Z]ID\d+)/ || $prefix=~/(ENCLB\S{6})\S+(ENCLB\S{6})/){
			$labExpIds="$1-$2";
		}
		elsif($prefix=~/([A-Z]ID\d+)/ || $prefix=~/(crg-\d+)/ || $prefix=~/(ENCLB\S{6})/){
			$labExpIds=$1;
		}
		else{
			die "Malformed filename? sourcelab='$sourceLab' prefix='$prefix' file='$file' $filepath\n";
		}
	}
	elsif($sourceLab eq 'caltech'|| $sourceLab eq 'licr' || $sourceLab eq 'psu' || $sourceLab eq 'uw'|| $sourceLab eq 'sydh' || $sourceLab eq 'illumina' || $sourceLab eq 'remc' || $sourceLab eq 'encode'){

		if($prefix=~/\S+_(\S+Rep\d)\.(\S+Rep\d)/){
			$labExpIds="$1-$2";
		}

		elsif ($prefix=~/\S+_(\S+Rep\d)/){
			$labExpIds=$1;
		}
		elsif ($prefix=~/\S+\.(\S+Rep\d)/){
			$labExpIds=$1;
		}
		elsif ($prefix=~/(\S+)_\S+$/){
			$labExpIds=$1;
		}
		elsif ($prefix=~/\S+\.(\S+)/){
			$labExpIds=$1;
		}
		elsif($prefix=~/(\S+)-(\S+)_/){
			$labExpIds="$1-$2";
		}
		else{
			warn "Malformed filename? sourcelab='$sourceLab' prefix='$prefix' file='$file' $filepath\n";
			$labExpIds=$prefix;
		}
	}
	else{
		die "Unknown sourceLab: $sourceLab.\n";
	}
	my $view='';
	print STDERR "labExpIds: $labExpIds\n";
	if($ext eq 'bam'){
		if($prefix =~ /spikeins/ || $prefix =~ /spikes/ || $prefix =~ /spike-ins/){
			$view='Spikeins';
		}
		else{
			$view='Alignments';
		}
	}
	elsif($ext eq 'pdf'){
		$view='Protocol';
	}
	elsif($ext eq 'tgz'){
		if ($prefix=~/HMM-TSS\.bed$/){
			$view='TssHmm';
		}
		else{
			die "view not specified for $filepath (prefix is: '$prefix'.)\n"
		}
	}
	elsif($ext eq 'gz'){
		if($prefix=~/_1\.txt$/ || $prefix=~/FastqRd1/ || $prefix=~/_1.fastq$/ ){ #LID21038_FC62Y1HAAXX_1_1.txt
			$view='FastqRd1';
		}
		elsif($prefix=~/_2\.txt$/|| $prefix=~/FastqRd2/ || $prefix=~/_2.fastq$/){ #LID21038_FC62Y1HAAXX_1_2.txt
			$view='FastqRd2';
		}
		elsif($prefix=~/.bam.bed$/){
			$view='bamBed';
		}
		elsif ($prefix=~/\.txt$/){
			$view='RawData';
		}
		else{
			die "view not specified for $filepath (prefix is: '$prefix'.)\n"
		}
	}
	elsif($ext eq 'bigwig' || $ext eq 'bigWig'){

		if($prefix=~/rawSignalPlusUnique$/ || $prefix=~/strand\+_unique$/){
			$view='UniquePlusRawSignal';
		}
		elsif($prefix=~/rawSignalMinusUnique$/ || $prefix=~/strand\-_unique$/){
			$view='UniqueMinusRawSignal';
		}
		elsif($prefix=~/rawSignalPlus$/ || $prefix=~/strand\+$/){
			$view='MultiPlusRawSignal';
		}
		elsif($prefix=~/rawSignalMinus$/ || $prefix=~/strand\-$/){
			$view='MultiMinusRawSignal';
		}
		elsif($prefix=~/rawSignalUnstrandedUnique$/){
			$view='UniqueSignal';
		}
		elsif($prefix=~/rawSignalUnstranded$/){
			$view='MultiSignal';
		}
		elsif($prefix=~/plus$/ || $prefix=~/\+strand/ || $prefix=~/strand\+/){
			$view='PlusRawSignal';
		}
		elsif($prefix=~/minus$/ || $prefix=~/\-strand/ || $prefix=~/strand\-/){
			$view='MinusRawSignal';
		}
		else{
			warn "No strand specified for $filepath Signal view. View set to 'RawSignal'\n";
			$view="RawSignal";
		}
	}
	elsif($ext eq 'bed'){
		if($prefix=~/clusters/ || $prefix=~/Clusters/){
			$view='Clusters';
		}
		elsif($prefix=~/Contig/){
			$view='Contigs';
		}
		elsif($prefix=~/Junctions/ || $prefix=~/SJ/){
			$view='Junctions';
		}
		elsif ($prefix=~/HMM-TSS$/){
			$view='TssHmm';
		}
		else{
			die "view not specified for $filepath (prefix is: '$prefix'.)\n"
		}
	}



	elsif($ext eq 'gtf' || $ext eq 'gff'){
		if($prefix=~/Transcript(Genc|Ens)V*(\d+)cuff/){
			$view='Transcript'.$1.'V'.$2.'cuff';
		}
		elsif($prefix=~/Transcript(Genc|Ens)V*(\d+)IAcuff/){
			$view='Transcript'.$1.'V'.$2.'IAcuff';
		}
		elsif($prefix=~/(Transcript|Exons|Gene)(.*)(Genc|Ens)V*(\d+)/){
			$view=$1.$2.$3.'V'.$4.'';
		}
		elsif($prefix=~/(Transcript|Exons|Gene)(\S*)(PipeR)/){
			$view=$1.$2.$3;

		}
		elsif($prefix=~/TranscriptDeNovo/){
			$view='TranscriptDeNovo';
		}
		elsif($prefix=~/TssGencV(\d+)/ || $prefix=~/TssGencv(\d+)/ || $prefix=~/TSSGencv(\d+)/){
			$view='TssGencV'.$1.'';
		}
#		else{
#			die "view not specified for $filepath (prefix is: '$prefix'.)\n"
#		}

#		if($prefix=~/TssGencV(\d+)/ || $prefix=~/TssGencv(\d+)/ || $prefix=~/TSSGencv(\d+)/){
#			$view='TssGencV'.$1.'';
#		}
		elsif($prefix=~/Exons(Genc|Ens)V*(\d+)NoDeconv/ || $prefix=~/Exon(Genc|Ens)V*(\d+)NoDeconv/){
			$view='Exons'.$1.'V'.$2.'NoDeconv';
		}
		elsif($prefix=~/Exons(Genc|Ens)V*(\d+)IAcuff/ || $prefix=~/Exon(Genc|Ens)V*(\d+)IAcuff/){
			$view='Exons'.$1.'V'.$2.'IAcuff';
		}
		elsif($prefix=~/Exons(Genc|Ens)V*(\d+)cuff/ || $prefix=~/Exon(Genc|Ens)V*(\d+)cuff/){
			$view='Exons'.$1.'V'.$2.'cuff';
		}
#		elsif($prefix=~/Exons(Genc|Ens)V*(\d+)/ || $prefix=~/Exon(Genc|Ens)V*(\d+)/){
#			$view='Exons'.$1.'V'.$2.'';
#		}
		elsif($prefix=~/Gene(Genc|Ens)V*(\d+)NoDeconv/ || $prefix=~/Genes(Genc|Ens)V*(\d+)NoDeconv/){
			$view='Gene'.$1.'V'.$2.'NoDeconv';
		}
		elsif($prefix=~/Gene(Genc|Ens)V*(\d+)IAcuff/ || $prefix=~/Genes(Genc|Ens)V*(\d+)IAcuff/){
			$view='Gene'.$1.'V'.$2.'IAcuff';
		}
		elsif($prefix=~/Gene(Genc|Ens)V*(\d+)cuff/ || $prefix=~/Genes(Genc|Ens)V*(\d+)cuff/){
			$view='Gene'.$1.'V'.$2.'cuff';
		}
#		elsif($prefix=~/Gene(Genc|Ens)V*(\d+)/ || $prefix=~/Genes(Genc|Ens)V*(\d+)/){
#			$view='Gene'.$1.'V'.$2.'';
#		}
		elsif($prefix=~/GeneDeNovo/){
			$view='GeneDeNovo';
		}
		elsif($prefix=~/ExonsDeNovo/ || $prefix=~/ExonDeNovo/){
			$view='ExonsDeNovo';
		}
		else{
			die "view not specified for $filepath (prefix is: '$prefix'.)\n"
		}
	}

	elsif($ext eq 'fastq'){
		if($prefix=~/FastqRd1/){
			$view='FastqRd1';
		}
		elsif($prefix=~/FastqRd2/){
			$view='FastqRd2';
		}
		else{
			die "FastqRd1 or FastqRd2? $filepath\n";
		}
	}
	else{
		die "Unknown file type $ext : $filepath\n";
	}
	#print STDERR "Ext: $ext\nView: $view\n";
	warn "Dup! labExpIds= $labExpIds view= $view\n" if (exists $labExpId_view_file{$labExpIds}{$view});
	$filepath=~s/\.\///;
	push(@{$labExpId_view_file{$labExpIds}{$view}}, $filepath);
}
open SETLIST, ">./dir_list.txt" or die $!;
open EXPLIST, ">./labExpId.list" or die $!;
#print STDERR "\nHASH ".Dumper \%labExpId_view_file;
foreach my $labExpIds (keys %labExpId_view_file){
	my %labExpIds2metadata=();
	print STDERR "Processing dataset $labExpIds.\n";
	my $ddf="$labExpIds.ddf";
	print SETLIST "$labExpIds/\n";
	open DDF, ">$ddf" or die $!;
	#print DDF "files\tview\t";
	my @ddfheader=();
	push(@ddfheader, "files","view");
	my @labExpIds=();
	if($labExpIds=~/^crg-\d+$/){
		push(@labExpIds, $labExpIds);
	}
	elsif($labExpIds=~/-/){
		@labExpIds=split ("-", $labExpIds);
	}
	else{
		push(@labExpIds, $labExpIds);
	}
	#print STDERR "List of labExpIds is: ".join (",", @labExpIds)."\n";
	foreach my $labExpId (@labExpIds){
		#print Dumper \%{$labExpId2metadata{$labExpId}};
		unless (exists $labExpId2metadata{$labExpId}){
			die "###\n Unknown labExpId $labExpId.\n###\n";

		}
		print EXPLIST "$labExpId\n";
		foreach my $key (keys %{$labExpId2metadata{$labExpId}}){
			push (@{$labExpIds2metadata{$key}}, ${$labExpId2metadata{$labExpId}}{$key});
			#print "curr: ".Dumper \%labExpIds2metadata;;
		}
		if ($labVersion){
			push (@{$labExpIds2metadata{'labVersion'}}, $labVersion);
		}
	}
	#print "labExpIds2metadata ".Dumper \%labExpIds2metadata;
	foreach my $key ( keys %labExpIds2metadata){
		#print "key=$key ; ";
		#print "@{$labExpIds2metadata{$key}}\n";
		my %seen = ();
		my @uniq=();
		#print STDERR "$key\n";
		foreach my $item (@{$labExpIds2metadata{$key}}) {
			push(@uniq, $item) unless $seen{$item}++; };
		@{$labExpIds2metadata{$key}}=@uniq;
		#print @uniq
	}
	#print Dumper \%labExpIds2metadata;


	foreach my $key (sort keys %labExpIds2metadata){
		unless ($key eq 'replicate_old' || $key eq 'dataType' ){ #|| $key eq 'spikeInPool'){
#print DDF "$key\t"; #print DDF header
			push(@ddfheader, $key);
		}
	}
	push(@ddfheader, 'dateProcessed');
	print DDF join ("\t",@ddfheader)."\n";
	foreach my $view ( keys %{$labExpId_view_file{$labExpIds}}){
		#my $fileList=join(",", @{$labExpId_view_file{$labExpIds}{$view}});
		my @ddfline=();
		#print STDERR "\tview: $view\n";
		my @fileList=();
		foreach my $file (@{$labExpId_view_file{$labExpIds}{$view}}){
			my $newfilepath='';
			unless($file=~/\/$labExpIds\// || $file=~/^$labExpIds\//){ #move to subdir only if file is not already there
				`mkdir -p $labExpIds`;
				$newfilepath="$labExpIds/$file";
			}
			else{
				$newfilepath="$file";
			}
			if ($file ne $newfilepath){
				`mv $file $newfilepath`;
			}
			push(@fileList, $newfilepath);
		}
		my $newFilePathList=join(",",@fileList);
		my $readme_file='';
		unless ($explicit_readme_file){
			$readme_file="README_$view.txt";
		}
		else{
			$readme_file=$explicit_readme_file;
		}
		#print STDERR "Copying $readme_file\n";
		system("cp $readme_file $labExpIds/ 2>/dev/null") == 0 or $ReadmesNotCopied{$readme_file}=1 ;
		push (@ddfline,$newFilePathList);
		push(@ddfline,$view);
		#print DDF "$newfilepath\t$view\t";
		foreach my $key (sort keys %labExpIds2metadata){
			unless ($key eq 'replicate_old' || $key eq 'bioRep'|| $key eq 'labExpId' || $key eq 'labExpId' || $key eq 'labProtocolId' || $key eq 'labVersion' || $key eq 'replicate'){ #should not have more than one item in array
				if($#{$labExpIds2metadata{$key}} > 0 && $key ne 'donorId'){
					warn "\n\n\tWARNING: key '$key' contains multiple values: '".join(",", @{$labExpIds2metadata{$key}})."'. See file $ddf.\n\n\n";
				}
			}
			unless ($key eq 'replicate_old'|| $key eq 'dataType' ){#|| $key eq 'spikeInPool'){
				print STDERR "$key\n";
				my $value=join(",", @{$labExpIds2metadata{$key}});
				$value='' if ($value eq 'N/A' || $value eq 'NA');
				#print DDF "$value\t";
				push (@ddfline,$value);
			}
		}
		push(@ddfline, $today);
		print DDF join ("\t",@ddfline)."\n";
		if($#ddfline != $#ddfheader){
			die "ddfline ($#ddfline) and ddfheader ($#ddfheader) don't have the same number of elements.\n@ddfline\n@ddfheader\n";
		}
	}
}


foreach my $README (keys %ReadmesNotCopied){
	print STDERR "$README not found.\n";
}

