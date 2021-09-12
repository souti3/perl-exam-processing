use v5.32;
use strict; # optional as a specific version is provided
use warnings;
use diagnostics;

use experimental 'signatures'; # needed to use named arguments

# Simplify the display of data structures...
use Data::Dumper 'Dumper';

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


# open the solution file
open (my $solutionfh, $solutionFile) or die $!;

# hash to store question and answers of the solution file
my %solutionQandA = writeQandAinHash(fileHandle=>$solutionfh);

# iterate through the provided exam files from students
for my $examFile (@studentFiles) {
  # check wether the files are valid with file test operators
  inputcheck($examFile);
  # open the exam file
  open (my $examfh, $examFile) or die $!;
  # store the questions and answers in a hash
  my %studentsQandA = writeQandAinHash(fileHandle=>$examfh);
  #say "Students Q and A";
  #say Dumper %studentsQandA;
  #say "_________________";

  # compare the number of keys (i.e. number of questions) in the solution file
  # with the number of keys (i.e. number of question) in the exam file
  my $questionComparison = keys %solutionQandA <=> keys %studentsQandA;
  say "Question Comparison: $questionComparison";
  if ($questionComparison == 0) {
    say "$solutionFile and $examFile have the same number of questions";
  }
  elsif ($questionComparison == 1) {
    say "$examFile:";
    say "\t There are questions missing in this file!";
  }
  else {
    say "$examFile:";
    say "\t There are too many questions in this file!";
  }

  # iterate through the questions of the solution file
  while (my $nextQuestion = each %solutionQandA) {
    # check whether the question exists in the exam file
    if (exists $studentsQandA{$nextQuestion}){
      ##########################################################
      # compare the answers
      ##########################################################
      # Loop through the answers in the solution file
      for my $solutionAnswer (@{$solutionQandA{$nextQuestion}}) {
        # find the correct answer
        my $correctAnswer = "";
        if ($solutionAnswer =~ m/^\s*\[\s*X\s*\]\s*/xms) {
          $correctAnswer = $solutionAnswer;
        }
        $correctAnswer = removeCheckbox(string=>$correctAnswer);
        #say "correct Answer is: $correctAnswer";

        # call subroutine to remove the checkbox in front of the answer
        my $answerText = removeCheckbox(string=>$solutionAnswer);

        # check whether the answer exists in students exam file
        if ( grep(/$answerText/, @{$studentsQandA{$nextQuestion}}) ) {
          # answer exists, everything ok
        }
        else {
          # answer is missing in students exam file
          say "$examFile:";
          say "\t Missing answer: $answerText";
        }
      }
      # find out which answer is the correct one in the solution file
      # maybe loop through the array and find the line where the regex matches
      # or with a grep
      # Check that there is exactly one answer marked as correct in the
      # exam file i.e. otherwise score is zero
      # Check whether the correct answer is marked as correct in the exam file
    }
    else {
      say "$examFile:";
      say "\t Missing question: $nextQuestion";
    }
  }


  # close the exam file
  close $examfh or die $!;
}

# close the solution file
close $solutionfh or die $!;



#say Dumper %solutionQandA;

say "Program works!";

sub writeQandAinHash ( %args ) {
  # hash to store the questions together with the answer array
  my %questionAnswer;
  # array to store the answers of a answer block
  my @answers;
  # file handle provided as argument
  my $fileHandle = $args{'fileHandle'};

  # read the solution file line by line
  while (my $nextline = readline($fileHandle)) {
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
    if ($nextline !~ $matchAnswer) {
      # if lastline was an answer, but nextline is not,
      # the answer block is finished
      if ($lastline =~ $matchAnswer && $lastline !~ $matchExampleAnswers) {
        # add the array with the answers in to the hash
        $questionAnswer{$currentQuestion} = [@answers];
        # clear the array as the next question will follow
        @answers = ();
      }
    }

    # if nextline is an answer, but not an example answer
    if ($nextline =~ $matchAnswer && $nextline !~ $matchExampleAnswers) {
      # add the answer into the answer array.
      push @answers, $nextline;
    }


    # if $nextline is a question
    if ($nextline =~ $matchQuestion) {
      # save the question
      #say "question: $nextline";
      $currentQuestion = $nextline;
    }

    $lastline = $nextline;
  }

  # return the hash with all questions and answers of the file
  return %questionAnswer;
}

sub removeCheckbox ( %args ) {
  # String with a checkbox which was provided as argument
  my $string = $args{'string'};
  # use split function to remove the checkbox in front of the answer
  my @splittedString = split(/\s*\[(?:\s*|X\s*)\]\s*/, $string);
  # the actual answer text is stored as the second element
  my $answerText = $splittedString[1];
  return $answerText;
}
