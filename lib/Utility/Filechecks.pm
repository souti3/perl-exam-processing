package Utility::Filechecks 0.000001;
use v5.32;
use warnings;
use experimental 'signatures';
use base 'Exporter';

our @EXPORT = ( 'inputcheck' );


sub inputcheck ($inputFile) {
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
}
1;
__END__
