use v5.32;
use strict; # optional as a specific version is provided
use warnings;
use diagnostics;

use List::Util 'shuffle'; # needed to randomize the order of the answers

# Simplify the display of data structures...
use Data::Dumper 'Dumper';

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

# array for the answers
my @answers;
# hash for the questions
my %questions;

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
  # regex to match question lines
  my $matchQuestion = qr{^\s*\d+\.\s*\w+.*}xms;
  # regex to match answer lines
  my $matchAnswer = qr{^\s*\[(?:\s+|X\s*)\]\s*.*$}xms;
  # regex to match the example answers
  my $matchExampleAnswers = qr{^\s*\[(?:\s+|X\s*)\]\s*This\his.*answer.*$}xms;
  # state variable to store the current question
  state $currentQuestion = "no current question";
  chomp $nextline;

  # Copy the introduction as it is - line by line - to the output file
  while ($nextline !~ $matchAnswer && $nextline !~ $matchQuestion) {
    # write the line in the output file
    say {$outputfh} $nextline;
    last;
  }

  # copy the example answers as they are to the output file
  if ($nextline =~ $matchExampleAnswers) {
    say {$outputfh} $nextline;
  }

  # remove the X character from correct answers
  $nextline =~ s/(\s+\[)X(\]\s.*)/$1 $2/;

  # push questions in a hash
  if ($nextline =~ $matchQuestion) {
    $currentQuestion = $nextline;
    #$questions{$currentQuestion} = [ @answers ];
    @answers = ();
  }

  # shuffle answers
  if ($nextline =~ $matchAnswer) {
    if ($nextline !~ $matchExampleAnswers) {
      push @answers, $nextline;
    }
  }

  # push the answer array in the hash if the current line is not a question
  # and not an answer line i.e. the question and all it's answers is
  # already processed.
  if (
  $nextline !~ $matchAnswer &&
  $nextline !~ $matchQuestion &&
  $nextline !~ $matchExampleAnswers
  ) {
    $questions{$currentQuestion} = [ @answers ];
    delete($questions{'no current question'});
    say "99999999999";
    say Dumper(%questions);
    say "99999999999";
    #for ($questions{$currentQuestion}->@*) {
    #  say {$outputfh} $_;
    #}


    if ($currentQuestion ne "no current question") {
      say {$outputfh} $currentQuestion;
      # rendomize the order of the answers for each question
      #my @shuffled = shuffle(@answers);
      #$questions{$currentQuestion} = [ @answers ];
      #$questions{$currentQuestion} = [ @shuffled ];
      #for (@{$questions{$currentQuestion}}) {
      #  say {$outputfh} $_;
      #}
      #for ($questions{$currentQuestion}->@*){
      #  say {$outputfh} $_;
      #}
      say "1111111111111";
      say Dumper(%questions);
      say "1111111111111";
      #delete($questions{$currentQuestion});
      #say {$outputfh} $questions{$currentQuestion}[0];
      #$currentQuestion = "no current question";
      #for (@{$questions{$currentQuestion}}) {
      #  say {$outputfh} $_;
      #}
      for my $key ( sort keys %questions ) {
          for (@{$questions{$key}}) {
            if (defined($_)){
              say {$outputfh} $_;
            }


          }
          say "key is: $key";
          print Dumper($questions{$key});
          say "ok";
          delete($questions{$key});
      }
      #$currentQuestion = "no current question";

    }
    delete($questions{$currentQuestion});


    #say {$outputfh} "####################";

    #for (@{$questions{$currentQuestion}}) {
    #  say {$outputfh} $_;
    #}
    #delete($questions{$currentQuestion});

    #for my $key ( sort keys %questions ) {
    #    say {$outputfh} "$key\n";
    #    for (@{$questions{$key}}) {
    #      say {$outputfh} $_;
          #delete($questions{$key});
    #    }
    #}
  }

  # write the line in the output file
  #say {$outputfh} $nextline;
}
close $inputfh or die $!;
say "Program works!";

say "The answer array contains the following:";
for (@answers){
  say $_;
}

say "The question hash contains the following:";
print Dumper(%questions);

for my $key ( sort keys %questions ) {
    print "$key\n";
    for (@{$questions{$key}}) {
      say $_;
    }
}

close $outputfh or die $!;
