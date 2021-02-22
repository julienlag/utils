
sub reverseComplement{
	my $seq=$_[0];
	my $rseq=reverse($seq);
	$rseq=~ tr/ACGTacgt/TGCAtgca/;
	return $rseq;
}
1;
