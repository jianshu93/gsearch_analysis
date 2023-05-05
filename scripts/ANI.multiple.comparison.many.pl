#!/usr/bin/perl -w
# @author: Jianshu Zhao
# @update: Mar-23-2023
# @license: artistic license 2.0
#
use strict;
use Getopt::Long;

#this script inputs a text file with all comparison file names and one file name to compare

sub usage {
  print "\nHow to run this code:\n";
  print "./ANI.multiple.comparison.many.pl -i input_list -n comparison_file -m method -o output.txt\n";
  print "-i\t\tA list with all filenames on one line, from the location to be excecuted\n";
  print "-n\t\tThe file to compare to\n";
  print "-m\t\tani or aai\n";
  print "-o\t\tname of output file\n";
}

my $input_list;
my $input_file;
my $method="none";
my $help=0;
my $output_file;

#other variables
my $file1; my $file2;
my $ani_value;
my @ani_values;
my @ani_names;

sub initialize {
  GetOptions(
  'i=s' => \$input_list,
  'n=s' => \$input_file,
  'm=s' => \$method,
  'o=s' => \$output_file,
  'h'   => \$help,
  ) or die "Incorecct usage!\n";

  if ($help ne 0) {
    usage(); exit 1;
  }
  unless (defined $input_list) {
    print "You need to entire the input file\n"; usage(); exit 1;
  }
  unless (defined $input_file) {
    print "You need to entire the file to be compared!\n"; usage(); exit 1;
  }
  $method = lc $method;
  unless ($method eq "aai" or $method eq "ani") {
    print "You must enter a valid method, either aai or ani\n"; usage(); exit 1;
  }
  unless (defined $output_file) {
    $output_file = "output.txt";
  }
}

sub readInput {
  my ($filename) = @_;
  open (FILE, "<", $filename) or die "Can't open the file $filename!!!\n";
  while (<FILE>) {
    chomp $_;
    $file2 = $_;
    $file1 = $input_file;
    $ani_value = runANI($file1, $file2);
    push @ani_values, $ani_value;
    push @ani_names, $file2;
  }
  close FILE;
}

sub runANI{
  ($file1, $file2) = @_; #get the input
  my $temp;
  #check for the method
  if ($method eq 'ani') {
    $temp = `ani.rb -1 $file1 -2 $file2 -t 10 -a -q`;
  }
  elsif ($method eq 'aai') {
    $temp = `aai.rb -1 $file1 -2 $file2 -t 10 -a -q`;
  }
  $ani_value = "";
  if ($temp eq "") { $ani_value = "NULL"; }
  else {
    chomp $temp;
    $ani_value = $temp;
  }
  return $ani_value;
}

initialize();
readInput($input_list);
open (OUT, ">", $output_file) or die "Can't open the output file!!\n";
$file1 =~ s/.fasta//g;
print OUT "$file1\t\n";
my $num_values = scalar @ani_values;
for (my $i=0; $i < ($num_values - 1) ; $i++) {
  if ($ani_values[$i] eq "NULL") {
    print OUT "";
  }
  else {
    print OUT "$ani_names[$i]\t";
    print OUT "$ani_values[$i]\n";
  }
}
if ($ani_values[$num_values-1] ne "NULL") {
  print OUT "$ani_names[$num_values-1]\t";
  print OUT "$ani_values[$num_values-1]\n";
}
#print OUT "\n";
close OUT;
