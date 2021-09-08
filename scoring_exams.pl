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

# store the path to the solution file in a variable
my $solutionFile =  shift(@ARGV);

# store the path to the exam files from students in an array
my @studentFiles = @ARGV;


# file tests with file test operators
# Using the module Filechecks.pm
inputcheck($solutionFile);
for my $inputFile (@studentFiles) {
  inputcheck($inputFile);
}

# open the solution file
open (my $solutionfh, $solutionFile) or die $!;

# regex to match question lines
my $matchQuestion = qr{^\s*\d+\.\s*\w+.*}xms;

# read the solution file line by line
while (my $nextline = readline($solutionfh)) {
  chomp $nextline;
  # if $nextline is a question
  if ($nextline =~ $matchQuestion) {
    # save the question
    say "question: $nextline";
  }
}


say "Program works!";
