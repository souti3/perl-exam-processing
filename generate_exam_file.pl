use v5.32;
use strict; # optional as a specific version is provided
use warnings;
use diagnostics;
use experimental 'signatures'; # needed to use named arguments

# needed to randomize the order of the answers
use List::Util 'shuffle';

# Simplify the display of data structures...
use Data::Dumper 'Dumper';

# needed to get the filename
use File::Basename;

# load the self written perl module
use Utility::Filechecks;

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


# store the argument in a variable
my $inputFile = $ARGV[0];
# file tests with file test operators
# Using the module Filechecks.pm
inputcheck($inputFile);
# call subroutine to get the file name
my $inputFileName = getFilename(filepath=>$inputFile);
# call subroutine to get the current timestamp
my $currentTimestamp = getTimeStamp();
# build the file name for the new file
my $outputFilename = "$currentTimestamp-$inputFileName";
#say "The filename of the output file will be: $outputFilename";

# open a file for the output
open (my $outputfh, ">", "./$outputFilename") or die $!;

# array to store the answers of a answer block
my @answers;

# open the provided examination master file
open (my $inputfh, $inputFile) or die $!;
# read the file line by line
while (my $nextline = readline($inputfh)) {
  # regex to match question lines
  my $matchQuestion = qr{^\s*\d+\.\s*\w+.*}xms;
  # regex to match answer lines
  my $matchAnswer = qr{^\s*\[(?:\s*|X\s*)\]\s*.*$}xms;
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
      # randomize the order of the answers for each question
      my @shuffledAnswers = shuffle(@answers);
      for my $answer (@shuffledAnswers) {
        # write the answers in the output file
        say {$outputfh} $answer;
      }
      # clear the array as the next question will follow
      @answers = ();
    }
    # write the line in the output file
    say {$outputfh} $nextline;
  }

  # copy the example answers as they are to the output file
  if ($nextline =~ $matchExampleAnswers) {
    say {$outputfh} $nextline;
  }

  # if nextline is an answer, but not an example answer
  if ($nextline =~ $matchAnswer && $nextline !~ $matchExampleAnswers) {
    # remove the X character from correct answers
    $nextline =~ s/(\s+\[)X(\]\s.*)/$1 $2/;
    # push the answer in an array
    push @answers, $nextline;
  }


  # if nextline is a question
  if ($nextline =~ $matchQuestion) {
    # store the question in a variable
    $currentQuestion = $nextline;
    # write the question in the output file
    say {$outputfh} $currentQuestion;
  }

  # assign the processed line to the variable $lastline
  $lastline = $nextline;

}
# close the input file
close $inputfh or die $!;
# close the output file
close $outputfh or die $!;

##########################################################
#
# No argument is needed to call this subroutine.
# Fetches the current timestamp in the format YYYYMMDD-HHMMSS
# Returns the timestamp as a String.
#
##########################################################
sub getTimeStamp {
  # get values from localtime and assign them to variables
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
  # format the output and return it
  return sprintf("%04d%02d%02d-%02d%02d%02d", , $year+1900, $mon+1, $mday, $hour, $min, $sec);
}

##########################################################
#
# Gets a path of a file as argument.
# Extracts the file name out of the whole path.
# Returns the file name as a String.
#
##########################################################
sub getFilename ( %args ) {
  # file path provided as argument
  my $filepath = $args{filepath};
  # return the file name by using the module File::Basename
  return basename($filepath);
}
