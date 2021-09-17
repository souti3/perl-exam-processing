# Exam generation and grading
## Required version and modules
### Valid for both Perl programs
The Perl programs are written and tested with the Perl version 5.32. I used the atom text editor to write the code and PowerShell as shell. The whole development and testing was done on a computer with Windows 10 operating system. The programs use the “strict”, “warnings” and “diagnostics” specifiers. In order to enable named arguments for subroutines both programs use “experimental 'signatures'”. For troubleshooting and debugging reasons the Perl module Data::Dumper was used. Furthermore, both Perl programs use a self-written Perl module called “Utility::Filechecks”. You will find the source code of this module on GitHub as well. It was written to perform some simple file checks based on file test operators. These tests make sure that the provided arguments are files in the expected format.
### Program generate_exam_file.pl
Besides the already above-mentioned specifiers and modules, generate_exam_file.pl uses the “File::Basename” module from CPAN. With this module I was able to extract the file name from the file path. In addition, I used the module “List::Util” from CPAN in order to shuffle the answers (randomize the order of the answers).
### Program scoring_exams.pl
In addition to the already mentioned specifiers and modules in the section “valid for both Perl programs”, I used the following modules in the Perl program scoring_exams.pl: “List::Util qw(reduce)” to find the minimal value in a hash, “Text::Levenshtein qw(distance)” to calculate the edit-distance and “Lingua::EN::StopWords qw(%StopWords)” to remove stop words. All of these modules were necessary to complete the extension (part 2).
### Module Filechecks.pm
Like the two Perl programs, the module Filechecks.pm also uses Perl version 5.32. It uses the specifiers “warnings” and “experimental 'signatures'” as well as the module “base 'Exporter'”. The module exports a subroutine called “inputcheck”.
## Randomization of questions - Main task (part 1a)
The main task (part 1a) is solved with the Perl program called generate_exam_file.pl.

It accepts exactly one argument: The path to a text file. This file contains the exam with the correct answers marked. In case the user provides a wrong number of arguments, the program will throw an exception and show an error message. The same applies in case the (as argument) provided file is either not readable, not an ASCII text file, not a plain file, is empty, has size zero or does not exist. The last-mentioned checks are done by using file test operators, which are in the self-written Perl module Filechecks.pm (path to the module: lib\Utility\Filechecks.pm).

The program reads the file line by line and writes the lines to a newly created output file. Thereby it removes the correct answer indicator ([X]) from any answer (except for the example answer at the beginning of the file) and randomize the order of the answers for each question. In order to shuffle the answers, every answer which belongs to the same question is pushed into an array and then shuffled with the help of the module “List::Util”.

As a result, the program generates a new file in the current directory with the name YYYYMMDD-HHMMSS-NameOfTheInputFile (e.g. “20210916-143857-short_exam_master_file.txt”). This file contains an exam based on the questions and answers of the input file, which can be sent to the students. The output of the program on the command line is just the statement “Program executed successful!” or a corresponding error message in case of an issue.

##### You can execute the program like this:

`perl generate_exam_file.pl <nameOfTheExaminationMasterFile>`

For example:

`perl generate_exam_file.pl test_data\short_exam_master_file.txt`

This will create a new exam file in the current directory with the order of answers randomized and the indicators for correct answers removed.

## Scoring of student responses – Main task (part 1b)
The main task (part 1b) is solved with the Perl program called scoring_exams.pl.

It accepts two or more arguments. The first argument is a solution file of the exam. The other arguments are completed examination files from the students. While the first argument always must be a single file, it is possible to provide a directory which contains all the completed examination files as second argument. So, you can choose between either list every single examination file as argument or provide a single directory as the second (and last) argument. Similar than in the other Perl program also this one verifies whether the provided number of arguments are correct and whether the arguments are valid files (or a directory). If that is not the case the program will throw an exception and print out an error message.

The program uses a hash as container for the data structure. A subroutine extracts the questions and answers of each file. Each answer which belongs to the same question is pushed to an array. A reference to this array is then the value of the hash, while the question itself is the key of the hash. After the file is processed, the hash with all questions and answers is returned. Loops are used to compare whether all questions and all answers from the solution file are also present in the solved exams. In order to calculate the score for each student, there is a comparison between the answers which are marked as correct in the exam files of the students and the correct solution from the solution file.

The output of the program is then a list with the score of each file. The score is displayed as number of correct answered question / number of total questions. In addition, the program reports missing questions or answers in the completed examination files from the students. In this case a manual check would make sense.

##### You can execute the program like this:

###### Option 1:

`perl scoring_exams.pl <nameOfSolutionFile> <nameOfStudentsFile1> <nameOfStudentsFile2> <nameOfStudentsFile3> <nameOfStudentsFile4>`

For example:

`perl scoring_exams.pl test_data\short_exam_master_file.txt test_data\Student_answers\student_Anton_Andersson.txt test_data\Student_answers\student_Bianca_Berner.txt test_data\Student_answers\student_Claudia_Christen.txt test_data\Student_answers\student_David_Dillier.txt test_data\Student_answers\student_Esther_Engler.txt test_data\Student_answers\student_Fabian_Fritschi.txt`

###### Option 2:

`perl scoring_exams.pl <nameOfSolutionFile> <directoryWithStudentExams>`

For example:

`perl scoring_exams.pl test_data\short_exam_master_file.txt test_data\Student_answers`

## Inexact matching of questions and answers – Extension (part 2)
The extension (part 2) is solved directly in the Perl program called scoring_exams.pl.

In order to enable inexact matching, I enhanced the existing Perl program. However, the execution of the program stays the same. Most of the new code was added in the subroutines. The questions and answers are now normalized and questions with an edit-distance lower than 10% are accepted as matched. Unfortunately, I could not implement the inexact matching for the answers. I faced some issues and was not able to solve them just in time. That is also the reason, why the score for the file “student_Giulia_Gruber.txt” is not correct.

The code itself was documented directly in the Perl program with the help of comments.

## Extension part 3 and part 4
Unfortunately, I had not enough time to look at extension part 3 and part 4. The implementation and documentation of the other parts of this project already exceeded the 40 hours which were reserved for this project.

## Example data and test files
The files, which I used to test the programs can be found in the folder “test_data”. This folder contains two solution files. The directory “Student_answers” contains some examples of exams written by students. They fit for the solution file called “short_exam_master_file.txt”.
