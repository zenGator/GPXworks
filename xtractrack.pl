#!/usr/bin/perl
# https://github.com/zenGator/xtractrack.pl
# zG:20240505

# other notes
# pull track names from RayMarine-generated .gpx
# ToDo:  give option to pull track OR route names

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#use and constants here
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
use strict;
use warnings;
use Getopt::Std;

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#declare subroutines here
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub usage;
#sub capOutput;
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst,$time);
# switches followed by a : expect an argument
# see usage() below for explanation of switches
my $commandname=$0=~ s/^.*\///r;
my %opt=();
getopts('hi:o:', \%opt) or usage();


usage () if ( $opt{h} or (scalar keys %opt) == 0 ) ;

my $infile=$opt{i};
open(my $fh, '<:encoding(UTF-8)', $infile)
  or die "Could not open file '$infile' $!";

my $outFH=*STDOUT;
if ($opt{o}) {
    open($outFH, '>:encoding(UTF-8)', $opt{o}) 
        or die "Could not open file '$opt{o}': $!\n";
    }


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#declare variables here
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    
my $x=0;  #primary counter, the line we are currently processing
my $trackCount=0;
my $outFiCount=0;
my $name;	#track name currently being processed


main: while (my $row = <$fh>) {
    #get a line
    $x++;  # increment line counter
    chomp $row;  #drop the newline at the end of the row
    my $orig_row=$row;	#store this off for later reference
	if ($row =~/<trk>/) {  # we're looking for the various tracks
		$trackCount++;
		$row=<$fh>;	# the <trk> tag signals a new block of tracks, and the next item should be <name>
		$x++;  # increment line counter
		chomp $row;  #drop the newline at the end of the row
		if ($row !~/^\s*<name>/){
			die "expected a nametag at $x: $row\n";
			}
		$name=$row;
		$name=~s/^\s*<name>(.*)<\/name>/$1/;
		print "track #$trackCount: $name\n";
		}
	}

sub usage() {
    print "like this: \n\t".$commandname." -i [infile] -o [outfile]\n";
    print "\nThis pulls the names of tracks from a RayMarine .gpx file.\n";
    exit 1;
    }
