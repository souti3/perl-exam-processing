use v5.32;
use strict; # optional as a specific version is provided
use warnings;
use diagnostics;
use experimental 'signatures'; # needed to use named arguments

# Simplifies the displaying of data structures
use Data::Dumper 'Dumper';

# load the self written perl module
use Utility::Filechecks;

##########################################################
# read the arguments from command-line, verify that the
# correct number of arguments are provided and store them
# in variables.
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

# array to store the score of the exam
my @scores;

# iterate through the provided exam files from students
for my $examFile (@studentFiles) {
  # check whether the files are valid with file test operators
  inputcheck($examFile);
  # open the exam file
  open (my $examfh, $examFile) or die $!;
  # store the questions and answers in a hash
  my %studentsQandA = writeQandAinHash(fileHandle=>$examfh);
  #say Dumper %studentsQandA;


  # compare the number of keys (i.e. number of questions) in the solution file
  # with the number of keys (i.e. number of question) in the exam file
  my $questionComparison = keys %solutionQandA <=> keys %studentsQandA;
  #say "Question Comparison: $questionComparison";
  if ($questionComparison == 0) {
    #say "$solutionFile and $examFile have the same number of questions";
  }
  elsif ($questionComparison == 1) {
    #say "$examFile:";
    #say "\t There are questions missing in this file!";
  }
  else {
    #say "$examFile:";
    #say "\t There are too many questions in this file!";
  }

  # variable to store the score
  my $score = 0;
  # count the total number of questions
  my $numberOfQuestions = 0;

  # iterate through the questions of the solution file
  while (my $nextQuestion = each %solutionQandA) {
    # check whether the question exists in the exam file
    if (exists $studentsQandA{$nextQuestion}){
      ##########################################################
      # compare the answers
      ##########################################################
      # string which will hold the correct answer
      my $correctAnswer = "";
      # regex which matches an answer which is marked as correct
      my $matchMarkedAnswers = qr{^\s*\[\s*X\s*\]\s*}xms;
      # count the number of answers which are marked as correct
      my $numMarkedAsCorrect = 0;
      # Loop through the answers in the solution file
      for my $solutionAnswer (@{$solutionQandA{$nextQuestion}}) {
        # find the correct answer in the solution file
        if ($solutionAnswer =~ $matchMarkedAnswers) {
          # assign the correct answer to the string variable
          $correctAnswer = $solutionAnswer;
          # remove the checkbox in front of the correct answer
          $correctAnswer = removeCheckbox(string=>$correctAnswer);
        }

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

      # store the answer which the student marked as correct
      my $answerMarkedAsCorrect = "";

      # Loop through the answers in the exam file
      for my $studentAnswer (@{$studentsQandA{$nextQuestion}}) {
        ##########################################################
        # grade the answers
        ##########################################################
        # check whether the current answer is marked as correct
        if ($studentAnswer =~ $matchMarkedAnswers) {
          # increase the counter for answers which are marked as correct
          $numMarkedAsCorrect++;
          # remove the checkbox in front of the answer
          $answerMarkedAsCorrect = removeCheckbox(string=>$studentAnswer);
        }
      }
      # if there is only one answer marked as correct
      if ($numMarkedAsCorrect == 1) {
        # compare the answer from the student with the solution answer
        if ($answerMarkedAsCorrect eq $correctAnswer) {
          # increase the score by one
          $score++;
        }
      }
      # set the counter back to zero for the next question
      $numMarkedAsCorrect = 0;

    }
    else {
      # The question is missing in students exam file
      say "$examFile:";
      say "\t Missing question: $nextQuestion";
    }
    # increase the number of questions by one
    $numberOfQuestions++;
  }

  # format the output with sprintf
  my $scoringOutput = sprintf "%-60s %-30s %1d/%1d", $examFile, " ", $score, $numberOfQuestions;
  # use a regex to replace whitespace characters with dots
  $scoringOutput =~ s/\s/\./g;
  # add the score to the array in order to print it out at the end
  # of this program
  push @scores, $scoringOutput;

  # close the exam file
  close $examfh or die $!;
}

# close the solution file
close $solutionfh or die $!;

#say Dumper %solutionQandA;

say "The evaluation of the exams showed the following scores:";

# print the scores for each exam file
for my $examScore (@scores) {
  say $examScore;
}

##########################################################
#
# Gets a file handle as argument. This file handle
# belongs to an exam file with questions and answers.
# This subroutine stores the questions (as key) and
# the answers (in an array reference as value) in a hash.
# Returns a hash with the questions (as key) and the
# answers (as value) of the corresponding file.
#
##########################################################
sub writeQandAinHash ( %args ) {
  # hash to store the questions together with the answer array
  my %questionAnswer;
  # array to store the answers of a answer block
  my @answers;
  # file handle provided as argument
  my $fileHandle = $args{'fileHandle'};

  # read the file line by line
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
      $currentQuestion = $nextline;
    }

    # assign the processed line to the variable $lastline
    $lastline = $nextline;
  }

  # return the hash with all questions and answers of the file
  return %questionAnswer;
}

##########################################################
#
# Gets a string as argument, which contains an answer.
# This answer string was read from an exam file and
# contains a checkbox in front of the answer text.
# This subroutine removes the checkbox from the string.
# Returns the pure text of the answer as a String.
#
##########################################################
sub removeCheckbox ( %args ) {
  # String with a checkbox which was provided as argument
  my $string = $args{'string'};
  # use split function to remove the checkbox in front of the answer
  my @splittedString = split(/\s*\[(?:\s*|X\s*)\]\s*/, $string);
  # the actual answer text is stored as the second element
  my $answerText = $splittedString[1];
  # return the string with the pure text of the answer
  return $answerText;
}
