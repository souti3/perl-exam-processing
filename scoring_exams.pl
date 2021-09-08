use v5.32;
use strict; # optional as a specific version is provided
use warnings;
use diagnostics;

# load the self written perl module
use Utility::Filechecks;

##########################################################
# read the argument from command-line, verify that it is
# a file and open it
##########################################################
# fetch the number of arguments provided
my $numOfArguments = @ARGV;
# make sure that there are at least two arguments
if ($numOfArguments <= 1) {
  die
    qq{You provided $numOfArguments arguments. However, }
  . qq{two or more (the name of the examination master file, followed }
  . qq{by the answer files of the students) }
  . qq{arguments must be provided in order to execute this program.};
}

my $solutionFile =  $ARGV[0];

# file tests with file test operators
# Using the module Filechecks.pm
for my $inputFile (@ARGV) {
  inputcheck($inputFile);
}

say "Program works!";
