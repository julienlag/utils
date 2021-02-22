
my %propertiesTree=();
our $propertiesTreeRef=\%propertiesTree;
foreach my $prop (keys %{$propertiesToReturn}){
	#print "##############\n$prop\n#################\n";
	my @tree=split('\.', $prop);
	#my $lastElement=pop(@tree);
	#my $lastHashElement=pop(@tree);

	my %tmpHash=();
	my $tmpHashRef=\%tmpHash;
	for (my $i=0; $i<=$#tree; $i++){
		my $node=$tree[$i];
		#unless(exists $propertiesTreeRef->{$node}){
		#unless($i==$#tree){
			$tmpHashRef->{$node}={};
			$tmpHashRef =$tmpHashRef->{$node};

		#else{
		#	$tmpHashRef->{$tree[$i-1]}=$node;
		#	$tmpHashRef =$tmpHashRef->{$node};
		#}
	}
	#print " last hash elemm: $lastHashElement\n";
	#print "tmpHashRef before".Dumper \%tmpHash;
	#$tmpHashRef->{$lastHashElement} = $lastElement;
	#print "tmpHashRef after".Dumper \%tmpHash;



	my $copyRef=$propertiesTreeRef;
		$propertiesTreeRef= merge($copyRef,\%tmpHash);
	#print "propertiesTreeRef after: ".Dumper $propertiesTreeRef;

	#print "propertiesTreeRef ".Dumper $propertiesTreeRef;

}
