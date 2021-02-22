use processJsonToHash;
use Hash::Merge qw(merge);
use strict;
use warnings;
use Storable qw(dclone);
use Deep::Hash::Utils qw(reach slurp nest);
$Data::Dumper::Purity =1;

sub fetchMetadataFromCollection{
my $identifiers=$_[0]; # hashref
my $propertiesToReturn=$_[1]; # hashref

my %propertiesTree=();
our $propertiesTreeRef=\%propertiesTree;
foreach my $prop (keys %{$propertiesToReturn}){
	my @tree=split('\.', $prop);
	my %tmpHash=();
	my $tmpHashRef=\%tmpHash;
	for (my $i=0; $i<=$#tree; $i++){
		my $node=$tree[$i];
			$tmpHashRef->{$node}={};
			$tmpHashRef =$tmpHashRef->{$node};
	}
	my $copyRef=$propertiesTreeRef;
		$propertiesTreeRef= merge($copyRef,\%tmpHash);

}

our $fullCollection;
my $collectionJsonFile=$ENV{'ENCODE3_FULL_OBJECTS_COLLECTION'};
print STDERR "Converting $collectionJsonFile to hash...";
$fullCollection = processJsonToHash($collectionJsonFile);
#print STDERR Dumper \$fullCollection;
print STDERR " Done.\n";

#open O, ">tmphash" or die $!;
#print O Dumper $fullCollection;
#close O;

my %returnMetadataHash=();
foreach my $identifier (keys %{$identifiers}){
#	print STDERR $identifier."\n";
	#first, check if identifier exists in collection
	unless (exists $$fullCollection{$identifier}){
#		print STDERR "WARNING: $identifier not found in collection $collectionJsonFile. Will be absent from output.\n";
		next;
	}
	$returnMetadataHash{$identifier}=dclone($propertiesTreeRef); #initializing empty hash for $identifier

	$returnMetadataHash{$identifier}=retrieveMetadata($identifier, $returnMetadataHash{$identifier}); #checking existence of main key

}

return \%returnMetadataHash;

sub retrieveMetadata{

	my $id=$_[0]; #accession or uuid
 	my $propertiesNode=$_[1];
 	my @arrayNest=();
 	my %hashToReturn;
 	my %uuids=();
 	$uuids{'XXrootXX'}=$id;
# 	print STDERR "######################################################################################################################################################################################################################################\nIDENTIFIER $id\tPROPNODE ".Dumper $propertiesNode."\n"; #.Dumper \%returnMetadataHash;

 	for my $ar (sort { @$a <=> @$b } slurp($propertiesNode)){ #sort arrays by their size, and iterate on them
# 		print STDERR "ar: ".Dumper $ar."\n";
 		  my @arr=@{$ar};
 		  for (my $i=0; $i <= $#arr; $i++){
# 		  	print STDERR "curr. arr.: $arr[$i]\n";
 		  	if($i==$#arr){ #reached leaf. retrieve property
# 		  		print STDERR "#reached leaf. retrieve property\n";
 		  		my $parent;
 		  		if($i==0){ #we're at the root, so parent is the $identifier passed to the subroutine
 		  			$parent='XXrootXX';
 		  		}
 		  		else{
 		  			$parent=$arr[$i-1];
 		  		}
# 		  		print STDERR "parent: $parent , curr. arr.: $arr[$i] \n". Dumper $$fullCollection{$uuids{$parent}}{$arr[$i]}."\n";
 		  		if( exists ($uuids{$parent}) && exists ($$fullCollection{$uuids{$parent}}{$arr[$i]})) {
# 		  			print STDERR "value BEFORE '$$fullCollection{$uuids{$parent}}{$arr[$i]}'\n";
 		  			my $value = stripBase(dumpString($$fullCollection{$uuids{$parent}}{$arr[$i]}));
# 		  			print STDERR "value: '$value'\n";
	 		  		my @tmp=@arr;
	 		  		push(@tmp, $value);
 			  		push (@arrayNest, \@tmp);
 			  	}
 			  	else{
# 			  		print STDERR "WARNING: No value found in collection for $uuids{$parent} / $arr[$i]\n";
 			  		my @tmp=@arr;
	 		  		push(@tmp, '');
 			  		push (@arrayNest, \@tmp);
 			   	}
 		  	}
 		  	else{ #we've reached an object but not its property, so we need to retrieve its uuid
 		  		my $parent;
 		  		if($i==0){ #we're at the root, so parent is the $identifier passed to the subroutine
 		  			$parent='XXrootXX';
 		  		}
 		  		else{
 		  			$parent=$arr[$i-1];
 		  		}
# 		  		print STDERR "parent: $parent, curr. arr.: $arr[$i] \n". Dumper $$fullCollection{$uuids{$parent}}{$arr[$i]}."\n";

 		  		unless(exists($uuids{$arr[$i]})){
 		  			if( exists ($$fullCollection{$uuids{$parent}}{$arr[$i]})){
	 		  			my $string=stripBase(dumpIdString($$fullCollection{$uuids{$parent}}{$arr[$i]}));

 			  			$uuids{$arr[$i]}=$$fullCollection{$string}{'uuid'};
 		  			}
					else{
#	 			  		print STDERR "WARNING: uuid not found for $uuids{$parent} / $arr[$i] \n";
	 			  		last;
	 			  	}
				}
			}
		}
	}
	foreach my $array2 (@arrayNest){
		my @array=@{$array2};
		my @propString=();
		for (my $i=0; $i<=$#array; $i++){
			if($i<$#array){
				push(@propString,$array[$i]);
			}
			else{
				$hashToReturn{join('.', @propString)}=$array[$i];
			}
		}
	}
	return \%hashToReturn;

}

sub dumpIdString{
	my $var=$_[0];
	if(ref($var) eq 'ARRAY'){ #sort array and return joined array
		my @array=@{$var};
		@array=grep defined, @array; #remove undefined values
		foreach my $i(@array){
			$i=stripBase($i);
		}
		if(@array){
		#		print STDERR "a- ".join(",",@array)." -\n";
			@array= sort @array;
			return(join(",",@array));
		}
		else{
			return '';
		}
	}
	elsif(ref($var) eq 'HASH'){
		if(exists $$var{'uuid'}){
			return $$var{'uuid'};
		}
		else{
			return undef;
			}
	}
	else{ #must be a scalar
		return $var;
	}
}

sub dumpString{
	my $var=$_[0];
	if(ref($var) eq 'ARRAY'){ #sort array and return joined array
#		print STDERR "is ARRAY\n";
		my @array=@{$var};
#		print STDERR "a- ".join(",",@array)." -\n";
		@array=grep defined, @array; #remove undefined values
		foreach my $i(@array){
			$i=stripBase($i);
		}
		if(@array){
		#		print STDERR "a- ".join(",",@array)." -\n";
			@array= sort @array;
			return(join(",",@array));
		}
		else{
			return '';
		}
	}
	elsif(ref($var) eq 'HASH'){ #unsupported
		die "$var is a hash, unsupported\n";

	}
	else{ #must be a scalar
#		print STDERR "is SCALAR\n";

		return $var;
	}
}


sub stripBase{
	my $string=$_[0];
	if(defined $string){
		my @string=split("/", $string);
		if( ($#string == 2) && ($string[$#string]=~/^\S{8}-\S{4}-\S{4}-\S{4}-\S{12}$/ || $string[$#string]=~/^ENC/ ) ){ #test that it's an encode3 object name (e.g. /users/f5b7857d-208e-4acc-ac4d-4c2520814fe1/) and not e.g. a URL or some shit
			return $string[$#string];
		}
		else{
			return $string;
		}
	}
	else{
		return undef;
	}
}



}
1;
