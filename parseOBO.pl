#!/usr/bin/perl -w

use strict;
use warnings;
use diagnostics;
use GO::Parser;
use Data::Dumper;

my $parser = new GO::Parser({handler=>'obj'}); # create parser object
$parser->parse("$ARGV[0]"); # parse file -> objects
my $graph = $parser->handler->graph;  # get L<GO::Model::Graph> object

open TERMNAMES, "$ARGV[1]" or die $!;
while(<TERMNAMES>){
	chomp;
	my $name=$_;
	print STDERR "Searching term $name...\n";
	my $term = $graph->get_term_by_name("$name");   # fetch a term by ID
	#print STDERR "$term";
	if(!defined $term){
		warn "  Couldn't find '$name' in ontology\n";
		next;
	}
	#printf "  Got term: %s %s\n", $term->acc, $term->name;
	my $child_terms = $graph->get_recursive_child_terms($term->acc);
  	foreach my $child_term (@$child_terms) {
  		if ($graph->is_leaf_node($child_term->acc)){
    	print "$name\t".$child_term->acc."\t".$child_term->name."\n";
		}
  	}
  }