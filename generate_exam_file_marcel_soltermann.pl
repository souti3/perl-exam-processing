use v5.32;
use strict; # optional as a specific version is provided
use warnings;
use diagnostics;
use experimental 'signatures'; # needed to use named arguments

use List::Util 'shuffle'; # needed to randomize the order of the answers

# Simplify the display of data structures...
use Data::Dumper 'Dumper';

# needed to get the filename
use File::Basename;

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



my $inputFile = $ARGV[0];
my $inputFileName = getFilename(filepath=>$inputFile);
my $currentTimestamp = getTimeStamp();
my $outputFilename = "$currentTimestamp-$inputFileName";
say "The filename of the output file will be: $outputFilename";

# open a file for the output
open (my $outputfh, ">", "./test_data/$outputFilename");

# array to store the answers of a answer block
my @answers;

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
  # regex to match question lines
  my $matchQuestion = qr{^\s*\d+\.\s*\w+.*}xms;
  # regex to match answer lines
  my $matchAnswer = qr{^\s*\[(?:\s+|X\s*)\]\s*.*$}xms;
  # regex to match the example answers
  my $matchExampleAnswers = qr{^\s*\[(?:\s+|X\s*)\]\s*This\his.*answer.*$}xms;
  # state variable to store the current question
  state $currentQuestion = "no current question";
  # state variable to store the last processed line
  state $lastline = "";

  chomp $nextline;

  # Copy the introduction as it is - line by line - to the output file
  if ($nextline !~ $matchAnswer && $nextline !~ $matchQuestion) {
    # if lastline was an answer, but nextline is not,
    # the answer block is finished
    if ($lastline =~ $matchAnswer && $lastline !~ $matchExampleAnswers) {
      for (@answers) {
        say {$outputfh} $_;
      }
      @answers = ();
    }
    # write the line in the output file
    say {$outputfh} $nextline;
  }

  # copy the example answers as they are to the output file
  if ($nextline =~ $matchExampleAnswers) {
    say {$outputfh} $nextline;
  }

  # new part
  if ($nextline =~ $matchAnswer && $nextline !~ $matchExampleAnswers) {
    # remove the X character from correct answers
    $nextline =~ s/(\s+\[)X(\]\s.*)/$1 $2/;
    push @answers, $nextline;
  }


  # print question
  if ($nextline =~ $matchQuestion) {
    $currentQuestion = $nextline;
    say {$outputfh} $currentQuestion;
  }

  $lastline = $nextline;

}
close $inputfh or die $!;
say "Program works!";


close $outputfh or die $!;

##########################################################
#
# Gets the current timestamp in the format YYYYMMDD-HHMMSS
# Retruns the timestamp as a String
#
##########################################################
sub getTimeStamp {
  # get values from localtime and assign them to variables
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
  # format the output
  return sprintf("%04d%02d%02d-%02d%02d%02d", , $year+1900, $mon+1, $mday, $hour, $min, $sec);
}

##########################################################
#
# Gets the filename of the input file, which was passed
# as argument when calling the script.
# Retruns the filename as a String
#
##########################################################
sub getFilename ( %args ) {
  my $filepath = $args{filepath};
  return basename($filepath);
}
