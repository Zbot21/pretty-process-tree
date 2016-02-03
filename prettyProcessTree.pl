#!/usr/bin/perl

use File::Temp qw/tempfile/;
use Text::CSV;
use GraphViz;

my $parent=$ARGV[0];
my $outfile=$ARGV[1];

# Script designed for making pretty process trees
my $psOutput=`ps -ael`;
$psOutput =~ s/[^\S\n]+/\,/g;
my $fh = tempfile();
print $fh $psOutput;
my $csv = Text::CSV->new();
seek $fh, 0, 0;
$csv->column_names($csv->getline($fh));
my @processes = @{$csv->getline_hr_all($fh)};

if(not defined $parent){
	$parent = 1;
}

if(not defined $outfile){
	$outfile = "test.png";
}

generateGraph($parent);

sub getChildProcesses {
	my $parentPid = shift;
	my @children = ();
	for my $process (@processes){
		if($process->{PPID} eq $parentPid){
			push @children, $process;
		}
	}
	return @children;
}

sub generateGraph {
	my $g = GraphViz->new();
	my $parent = shift;
	$g->add_node('pid'.$parent);
	recurseGraph($g, $parent);
	$g->as_png($outfile);
}

sub recurseGraph {
	my $g = shift;
	my $parent = shift;
	my @children = getChildProcesses($parent);
	my $parentId = 'pid'.$parent;
	for my $child (@children){
		my $childId = 'pid'.$child->{PID};
		$g->add_node($childId);
		$g->add_edge($parentId => $childId);
		recurseGraph($g, $child->{PID});
	}
}