package encode_metadata;

#reads in a file formatted like:
# #cell   replicate_old   replicate       localization    rnaExtract      dataType        labExpId        bioRep  spikeInPool
# A549    1       1       cell    longNonPolyA    RnaSeq  LID9005 021     14

#and returns a hash like:
# 'LID9190' => {
#                         'rnaExtract' => 'total',
#                         'spikeInPool' => '14',
#                         'dataType' => 'RnaSeq',
#                         'replicate_old' => '4',
#                         'replicate' => '4',
#                         'bioRep' => '026',
#                         'labExpId' => 'LID9190',
#                         'localization' => 'nucleoplasm',
#                         'cell' => 'K562'
#                       }

sub encode_metadata{
	die "Wrong number of arguments: @_ .\n" if ($#_!=2 || $_[0] eq '' || $_[1] eq ''|| $_[2] eq '');
	my $infile=$_[0];
	my $leave_bioRep_alone=undef;
	if ($_[1]==1){
		$leave_bioRep_alone=1;
	}
	else{
		$leave_bioRep_alone=0
	}
	
	my $organism=lc($_[2]);
	
	#print STDERR "leavebioRep $leave_bioRep_alone\n";
	my %localizationToLabProtocolId=(
	"cell" => "WC",
	"chromatin" => "CH",
	"nucleus" => "N",
	"nucleolus" => "NL",
	"nucleoplasm" => "NP",
	"cytosol" => "C",
	"polysome" => "P",
	);
	my %LabProtocolIdToLocalization=(
	"WC" => "cell",
	"CH" => "chromatin",
	"N" => "nucleus",
	"NL" => "nucleolus",
	"NP" => "nucleoplasm",
	"C" => "cytosol",
	"P" => "polysome",
	);
my %rnaExtractToLabProtocolId=(
	"longNonPolyA" => "-",
	"longPolyA" => "+",
	"shortTotal" => "s",
	"total" => "t"
	);
my %dataTypeToLabProtocolId=(
	"Cage" => "cage",
	"RnaPet" => "pet",
	"RnaSeq" => ""
	);


	open MASTER, "$infile" or die "$infile : $!";
	my %labExpId_to_all;
	my @keys=();
	while(<MASTER>){
		#print;
		chomp;
		my %line_attr=();
		my @line=split "\t";
		if($.==1){
			if ($_=~/^#(.+)$/){ #reading "keys"
				#print "'$1'";
				my $l=$1;
				@keys=split("\t",$l);
				next;
			}
			else{
				die "No header found in file $infile. Cannot continue";
			}
		}
		#print join(" = ",@keys);
		for (my $i=0; $i<=$#line; $i++){
			$line_attr{$keys[$i]}=$line[$i];
		}
		next if (!defined $line_attr{'labExpId'} || $line_attr{'labExpId'} eq '.' || $line_attr{'labExpId'} eq 'N/A' || $line_attr{'labExpId'} eq '');
		warn "duplicate ".$line_attr{'labExpId'}."\n" if (exists $labExpId_to_all{$line_attr{'labExpId'}});
		$labExpId_to_all{$line_attr{'labExpId'}}=\%line_attr;
		
#		unless($organism eq 'mouse'){
			
#			if($line_attr{'bioRep'}=~/^(\d{3,})((WC)|(CH)|(N)|(NL)|(NP)|(C)|(P))$/){
#				$line_attr{'bioRep'}=$1; #trim WC NP NL from bioRep if present
#				$line_attr{'localization'}=$LabProtocolIdToLocalization{$2};
#			}
#		}
		my $labProtocolId=undef;
		if(exists ($line_attr{'labProtocolId'})){
			$labProtocolId=$line_attr{'labProtocolId'};
		}
#		else{
#			$labProtocolId=$line_attr{'bioRep'}.$localizationToLabProtocolId{$line_attr{'localization'}}.$rnaExtractToLabProtocolId{$line_attr{'rnaExtract'}}.$dataTypeToLabProtocolId{$line_attr{'dataType'}};
#		}
		my $bioRep=undef;
#		if ($leave_bioRep_alone == 0){
#			$bioRep=$line_attr{'bioRep'}.$localizationToLabProtocolId{$line_attr{'localization'}};
#		} 
#		else{
#			$bioRep=$line_attr{'bioRep'};
#		}
		
#		$labExpId_to_all{$line_attr{'labExpId'}}{'bioRep'}=$bioRep;
		$labExpId_to_all{$line_attr{'labExpId'}}{'labProtocolId'}=$labProtocolId if (defined $labProtocolId);
	}
	close MASTER;
	return %labExpId_to_all;
}

1;
