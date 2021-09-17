use v5.32;
use strict; # optional as a specific version is provided
use warnings;
use diagnostics;
use experimental 'signatures'; # needed to use named arguments

# Simplifies the displaying of data structures
use Data::Dumper 'Dumper';

# load the self written perl module
use Utility::Filechecks;

# used to remove stop words from texts
use Lingua::EN::StopWords qw(%StopWords);

# used to calculate the Levenshtein edit distance between two strings
use Text::Levenshtein qw(distance);

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

# array to store the path to the exam files of the students
my @studentFiles;

# check whether the user provided exactly two arguments
if ($numOfArguments == 2) {
  # check whether the second argument (which is now the first and
  # only array element since we removed the solution file from the
  # array) is a directory
  if (-d $ARGV[0]) {
    ##########################################################
    # read all files from this directory and add them to an array
    ##########################################################
    # open the directory
    opendir (my $examdir, $ARGV[0]) or die $!;
    # loop through the files in the directory
    while (my $nextfile = readdir($examdir)) {
      # exclude special folders . and ..
      next if $nextfile =~ /^\.\.?$/;
      # generate the filepath with directory and file name
      my $filepath = "$ARGV[0]/$nextfile";
      # push the filepath in the array
      push @studentFiles, $filepath;
    }
    # close the directory
    closedir($examdir);
  }
  else {
    # the argument is not a directory
    # store the path to the exam files from students in an array
    @studentFiles = @ARGV;
  }
}
else {
  # more than two arguments provided by the user
  # store the path to the exam files from students in an array
  @studentFiles = @ARGV;
}

# file tests with file test operators
# Using the module Filechecks.pm
inputcheck($solutionFile);


# open the solution file
open (my $solutionfh, $solutionFile) or die $!;

# hash to store question and answers of the solution file
my %solutionQandA = writeQandAinHash(fileHandle=>$solutionfh);

# array to store the score of the exam
my @scores;

# flag to detect whether manual intervention is needed
my $problemsDetected = 0;

# Print out a title
say "\n________________________________________________________________________\n";
say "Problems which need manual intervention:\n";

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
    if (exists $studentsQandA{$nextQuestion}) {
      ##########################################################
      # compare the answers
      ##########################################################
      # string which will hold the correct answer
      my $correctAnswer = "";
      # regex which matches an answer which is marked as correct
      my $matchMarkedAnswers = qr{^\s*\[\s*x\s*\]\s*}xms;
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
          # update the problems detected flag
          $problemsDetected = 1;
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
      # no exact question match, check whether there is an inexact match
      for my $studentKey (keys %studentsQandA) {
        # get the deviation between the original question and the one from the stundent
        my $deviation = getEditDistanceInPercent(solutionString=>$nextQuestion, studentString=>$studentKey);
        # if the edit-distance is no more than 10% accept the question
        if ($deviation <= 10) {
          # accept question
          say "$examFile:";
          say "Missing question: $nextQuestion";
          say "Used this instead: $studentKey";
        }
        else {
          # The question is missing in students exam file
          say "$examFile:";
          say "\t Missing question: $nextQuestion";
          # update the problems detected flag
          $problemsDetected = 1;
        }
      }
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

# check whether there are any problems or not
if ($problemsDetected == 0) {
  say "No problems detected within the provided files!\n";
}

#say Dumper %solutionQandA;
say "\n________________________________________________________________________\n";
say "The evaluation of the exams showed the following scores:\n";

# print the scores for each exam file
for my $examScore (@scores) {
  say $examScore;
}
say "\n________________________________________________________________________\n";

# test edit distance
my $string1 = "Hello from Marcel and Welcome to Perl";
my $string2 = "Hallo von Marcel and Welcome to Perl";
my $dist = getEditDistanceInPercent(solutionString=>$string1, studentString=>$string2);
say "Distance is: $dist";

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
      # normalization of the answer
      $nextline = getNormalizedString(string=>$nextline);
      # add the answer into the answer array.
      push @answers, $nextline;
    }


    # if $nextline is a question
    if ($nextline =~ $matchQuestion) {
      # normalization of the question
      $nextline = getNormalizedString(string=>$nextline);
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
# Returns the pure text of the answer as a string.
#
##########################################################
sub removeCheckbox ( %args ) {
  # String with a checkbox which was provided as argument
  my $string = $args{'string'};
  # use split function to remove the checkbox in front of the answer
  my @splittedString = split(/\s*\[(?:\s*|x\s*)\]\s*/, $string);
  # the actual answer text is stored as the second element
  my $answerText = $splittedString[1];
  # return the string with the pure text of the answer
  return $answerText;
}

##########################################################
#
# Gets a string as argument.
# This string will then be normalized within this
# subroutine. The normalization consists of the following:
# - converting the text to lower-case
# - removing any "stop words" from the text
# - removing whitespace characters at the start and/or the end of the text
# - replacing whitespace characters within the text with a single space character.
# Returns the normalized string.
#
##########################################################
sub getNormalizedString ( %args ) {
  # string which was provided as argument
  my $inputString = $args{'string'};
  # convert the text to lower case
  $inputString = lc($inputString);
  # use split function to add the words of the string into an array
  my @wordsOfString = split(/\s+/, $inputString);
  # Remove stop words from @wordsOfString and add them to a new variable
  my $noStopWords =  sprintf join " ", grep { !$StopWords{$_} } @wordsOfString;
  # remove whitespaces at the start and/or the end of the text
  $noStopWords =~ s/^\s+|\s+$//g;
  # remove whitespace characters within the text with single space
  $noStopWords =~ s/\s+/ /g;
  # return the normalized string
  return $noStopWords;
}

##########################################################
#
# Gets two strings as arguments. One is the original
# string from the solution file and the other is the
# normalized string from students exam files.
# The subroutine stores the length of the original
# string, calculates the edit-distance of both strings
# and calculates the deviation between the original
# and the normalized string in percent.
# Returns the deviation of both strings in percent.
#
##########################################################
sub getEditDistanceInPercent ( %args ) {
  # string from solution file, which was provided as argument
  my $solutionString = $args{'solutionString'};
  # string from students exam file, which was provided as argument
  my $studentString = $args{'studentString'};
  # store the length of the original string from the solution file
  my $lengthOriginalString = length($solutionString);
  # calculate the edit-distance of the two strings
  my $editDistance = distance($solutionString, $studentString);
  # calculate the edit-distance in percent
  my $editDistancePercent = ($editDistance / $lengthOriginalString) * 100;
  return $editDistancePercent;
}
