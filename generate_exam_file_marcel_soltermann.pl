use v5.32;
use strict; # optional as a specific version is provided
use warnings;
use diagnostics;

##########################################################
# read the argument from command-line, verify that it is
# a file and open it
##########################################################
# fetch the number of arguments provided
my $numOfArguments = @ARGV;
# make sure that there is only a single argument
if ($numOfArguments != 1) {
  die
    qq{You provided $numOfArguments arguments. However, }
  . qq{exactly one (the name of the examination master file)}
  . qq{argument must be provided in order to execute this program.};
}

# open a file for the output
open (my $outputfh, ">", "./test_data/doublicate.txt");

my $inputFile = $ARGV[0];
##########################################################
# file tests with file test operators
##########################################################
# make sure that the file exists
die "File $inputFile does not exists!" if (! -e $inputFile);
# make sure that the file is readable
die "File $inputFile is not readable!" if (! -r $inputFile);
# make sure that the file is an ASCII text file
die "File $inputFile is not an ASCII text file!" if (! -T $inputFile);
# make sure that the file is a plain file
die "File $inputFile is not a plain file!" if (! -f $inputFile);
# make sure that the file is not empty
die "File $inputFile is empty!" if (-z $inputFile);
# make sure that the file has nonzero size
die "File $inputFile has size zero!" if (! -s $inputFile);
# open the provided examination master file
open (my $inputfh, $inputFile) or die $!;
# read the file line by line
while (my $nextline = readline($inputfh)) {
  chomp $nextline;
  # check whether the next line is a correct answer

  # write the line in the output file
  say {$outputfh} $nextline;
}
close $inputfh or die $!;
say "Program works!";

close $outputfh or die $!;
