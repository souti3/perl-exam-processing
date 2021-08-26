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

my $file = $ARGV[0];
##########################################################
# file tests with file test operators
##########################################################
# make sure that the file exists
die "File $file does not exists!" if (! -e $file);
# make sure that the file is readable
die "File $file is not readable!" if (! -r $file);
# make sure that the file is an ASCII text file
die "File $file is not an ASCII text file!" if (! -T $file);
# make sure that the file is a plain file
die "File $file is not a plain file!" if (! -f $file);
# make sure that the file is not empty
die "File $file is empty!" if (-z $file);
# make sure that the file has nonzero size
die "File $file has size zero!" if (! -s $file);
# open the provided examination master file
open(my $fh, $file) or die $!;
close $fh or die $!;
say "Program works!";
