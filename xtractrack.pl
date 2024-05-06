#!/usr/bin/perl
# https://github.com/zenGator/xtractrack.pl
# zG:20240505

#other notes:
#	pull track or route names from RayMarine-generated .gpx

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#use and constants here
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
use strict;
use warnings;
use Getopt::Std;

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#declare variables here
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    
my $x=0;  #primary counter, the line we are currently processing
my $name;	#route or track name currently being processed
my $trackCount=0;	#how many have we found?
my $commandname=$0=~ s/^.*\///r;
my %opt=();
my ($target, $type); #route or track


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#declare subroutines here
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub usage;

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#pre-processing (options)
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# switches followed by a : expect an argument
# see usage() below for explanation of switches
getopts('hi:o:rt', \%opt) or usage();

usage () if ( $opt{h} or (scalar keys %opt) == 0 ) ;

my $infile=$opt{i};
open(my $fh, '<:encoding(UTF-8)', $infile)
  or die "Could not open file '$infile' $!";

my $outFH=*STDOUT;
if ($opt{o}) {
    open($outFH, '>:encoding(UTF-8)', $opt{o}) 
        or die "Could not open file '$opt{o}': $!\n";
    }

if ($opt{r}) {
	$target="<rte>" ;
	$type="route";
	}
if ($opt{t}) {
	$target="<trk>" ;
	$type="track";
	}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#main program block
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
main: while (my $row = <$fh>) {    #get a line
    $x++;  # increment line counter
    chomp $row;  #drop the newline at the end of the row
	while (! defined $target) {	# default behaviour:  no -[r|t] specified
		if ($row =~ /<rte>|<trk>/){	# maybe this line begins a track/route block
			($target = $row) =~ s/^\s*(.*)\s/$1/;	#if so, set target, use the special 'r' modifier
			$type="route" if $target =~/<rte>/;		#also need to identify type
			$type="track" if $target =~/<trk>/;
			printf "\nINFO: type of extract not specified.  First thing found is a %s, so that's what we'll report on.\n\n", $type; # notify
			}
		else {		#if not, grab another line as we normally would
			$row=<$fh>;
			$x++;
			chomp $row;
			}
		}
	if ($row =~/$target/) {  # we're looking for either tracks or routes
		$trackCount++;
		$row=<$fh>;	# the [$target] tag signals a new block, and the next item should be <name>
		$x++;  # increment line counter
		chomp $row;  #drop the newline at the end of the row
		if ($row !~/^\s*<name>/){	#after the rte or trk tag, there should be a <name> tag
			die "expected a nametag at $x: $row\n";	#if not, abort
			}
		$name=$row;
		$name=~s/^\s*<name>(.*)<\/name>/$1/;	#strip the nametag
		printf $outFH "%s #%d: %s\r\n", $type,$trackCount,$name;	#output
		}
	}

sub usage() {
    print "like this: \n\t".$commandname." -i [infile] -o [outfile] -[t|r]\n";
    print "\nThis pulls the names of tracks from a RayMarine .gpx file.\n";
	print "\nuse -t for tracks, and -r for routes.  If neither is specified, the first type (track or route) encountered will be used.\n";
    exit 1;
    }
