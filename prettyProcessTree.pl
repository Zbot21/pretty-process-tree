#!/usr/bin/perl

use File::Temp qw/tempfile/;
use Text::CSV;
use Data::Dumper;
use GraphViz;

my $parent=$ARGV[0];

# Script designed for making pretty process trees
my $psOutput=`ps -ael`;
$psOutput =~ s/[^\S\n]+/\,/g;
my $fh = tempfile();
print $fh $psOutput;
my $csv = Text::CSV->new();
seek $fh, 0, 0;
$csv->column_names($csv->getline($fh));
my @processes = @{$csv->getline_hr_all($fh)};

generateGraph(1);

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

sub getAllChildrenProcesses {
	my $parentPid = shift;
	my %processChildren = ();
	my @children = getChildProcesses($parentPid);
	$processChildren{$parentPid} = \@children; 
	for my $child (@children) {
		getAllChildrenProcesses_recurse($child->{PID}, \%processChildren);
	}
	return \%processChildren;
}

sub getAllChildrenProcesses_recurse {
	my $parentPid = shift;
	my $processChildren = shift;
	my @children = getChildProcesses($parentPid);
	$processChildren->{$parentPid} = \@children;
	for my $child (@children){
		getAllChildrenProcesses_recurse($child->{PID}, $processChildren);
	}
}

sub generateGraph {
	my $g = GraphViz->new();
	my $parent = shift;
	my $childProcesses=getAllChildrenProcesses($parent);
	$g->add_node('pid'.$parent);
	recurseGraph($g, $childProcesses, $parent);
	$g->as_png("test.png");
}

sub recurseGraph {
	my $g = shift;
	my $childProcesses = shift;
	my $parent = shift;
	my $children = $childProcesses->{$parent};
	my $parentId = 'pid'.$parent;
	for my $child (@{$children}){
		my $childId = 'pid'.$child->{PID};
		$g->add_node($childId);
		$g->add_edge($parentId => $childId);
		recurseGraph($g, $childProcesses, $child->{PID});
	}
}