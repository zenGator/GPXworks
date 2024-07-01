#!/usr/bin/perl
# https://github.com/zenGator/ [name]
# trackExtract_oCPNgpx:
#	extract individual tracks from a gpx export, built with oCPN in mind, but may work on TZiBoats as well
#	each route is within a node bookended by <trk></trk>
#	each is saved as its own .gpx
# zG:20240626

# other notes

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#use and constants here
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
use strict;
use warnings;
use Getopt::Std;
#use File::Copy;
#use constant XWFLIM => 100000;

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


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#declare variables here
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    
my ($x, $i, $c) =(0) x 3;		# utility
my $line=0;			# primary counter, the line we are currently processing
my $routeCount=0;	# number of individual routes extracted
my ($headerBuffer, $routeName, $routeBuffer);	# initial line of each routefile, name, route contents
my @routeTable=();


main: while (my $row = <$fh>) {			# get a line
    $line++;  # increment line counter
    chomp $row;  #drop the newline at the end of the row
    my $orig_row=$row;	#store this off for later reference

	if  ($row =~ /^ *<\/gpx>/) {		# report and close out process
		printf "done\n";
		for my $arrRow (@routeTable) {
			printf join("\t", @{$arrRow})."\n";
			}
		exit;
		}

	if (! $headerBuffer) {				# build header
		until ($row =~ /<trk>/) {
			$headerBuffer.=$row."\n";
			$row = <$fh>;	# read a single line
			$line++;		# increment line counter
			chomp $row;
			}
		chomp $headerBuffer;
#debug:
#printf "headerBuffer:\n%s\n", $headerBuffer;
		}
		
#debug:
#printf "\nDEBUG: line %d: %s\n", $line, $row;
	# $row should now be /<trk>/
	if ($row !~ /<trk>/){
		warn "unexpected value/tag at $line: >$row<\n";
		}
	$routeCount++;
	$routeBuffer="";
	$routeName="";
#dbg:	printf "here at new route # %d, with \$routeName of >%s<\n", $routeCount, $routeName;
	do {							#collect route details
			$routeBuffer.=$row."\n";
			$row = <$fh>;	# read a single line
			$line++;		# increment line counter
			chomp $row;
			if ($row =~ /^\s*<name>/ && ! $routeName ){
#dbg:				printf "\textracting row name from:\n\t\t%s\n", $row;
				$row =~ /^(\s*<name>)(.+)(<\/name>)/;
				$routeName=$2;
#				printf "%s\n", $routeName; #dbg
				push (@routeTable,([$routeCount,$routeName]));
#ToDo:  if routeName="", generate random or use routeCount
#ToDo:  append routeCount if routeName already used
#ToDo:  may need to address commas in the routeName
#ToDo:  need to address unallowable characters in the fileName
				}
			} until ($row =~ /<\/trk>/);
	# $row should now be /</trk>/

# write to file
	my $outFileName=$routeName."_".$routeCount.".gpx";
#debug
#	printf "will be writing to file here:\n\t%s\t%s => %s\n", $routeCount, $routeName, $outFileName;
	open(my $outFH, '>:encoding(UTF-8)', $outFileName) 
		or die "Could not open file '$outFileName': $!\n";
    printf $outFH "%s\n", $headerBuffer;
	printf $outFH "%s", $routeBuffer;
	printf $outFH "</trk>\r\n</gpx>";
	close $outFH;
	}

sub usage() {
    print "like this: \n\t".$commandname." -i [infile] -o [outfile]\n";
    print "\nThis extracts individual routes from an OpenCPN export of a collection of routes.\n";
    exit 1;
    }
