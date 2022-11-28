#!/usr/bin/perl
# https://github.com/zenGator/ [name]
# zG:20221126

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

my $outFH=*STDOUT;
if ($opt{o}) {
    open($outFH, '>:encoding(UTF-8)', $opt{o}) 
        or die "Could not open file '$opt{o}': $!\n";
    }


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#declare variables here
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    
my $x=0;  #primary counter, the line we are currently processing
my $outFiCount=0;


main: while (my $row = <$fh>) {
    #get a line
    $x++;  # increment line counter
    chomp $row;  #drop the newline at the end of the row
    my $orig_row=$row;	#store this off for later reference

    # transforms
	# first two are header differences
	if ($row =~ /<\?xml version="1.0"\?>/) {  
		$row = '<?xml version="1.0" encoding="UTF-8" ?>';
		next;
	}
	if ($row =~ /<gpx version="1.1" creator="OpenCPN" /) {
		$row = '<gpx creator="GPSMAP 942" version="1.1" xmlns="http://www.topografix.com/GPX/1/1" xmlns:gpxx="http://www.garmin.com/xmlschemas/GpxExtensions/v3" xmlns:wptx1="http://www.garmin.com/xmlschemas/WaypointExtension/v1" xmlns:gpxtpx="http://www.garmin.com/xmlschemas/TrackPointExtension/v1" xmlns:uuidx="http://www.garmin.com/xmlschemas/IdentifierExtension/v1" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd http://www.garmin.com/xmlschemas/GpxExtensions/v3 http://www8.garmin.com/xmlschemas/GpxExtensionsv3.xsd http://www.garmin.com/xmlschemas/WaypointExtension/v1 http://www8.garmin.com/xmlschemas/WaypointExtensionv1.xsd http://www.garmin.com/xmlschemas/TrackPointExtension/v1 http://www.garmin.com/xmlschemas/TrackPointExtensionv1.xsd http://www.garmin.com/xmlschemas/IdentifierExtension/v1 http://www.garmin.com/xmlschemas/IdentifierExtension.xsd">';

	# insert metadata node here to explain the origin of the file
		$row.="\r\n";
		($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime(time);
		$year = $year + 1900;
	$time="$year-$mon-${mday}T$hour:$min:${sec}Z";
		$row.="<metadata>\r\n\t<time>$time</time>\r\n";
		$row.="\t<sourcefile>$infile</sourcefile>\r\n";
		$row.="</metadata>";
		next;
	}

	next if ($row =~ /^ *<wpt lat=/ );
	next if ($row =~ /^ *<time>/ );
	if ($row =~ /^ *<name>/ ){
		$row =~ s/^( *<name>.+)(<\/name>)/$1_oCPN$2/;
		next;
	}
	if ($row =~ /^ *<desc>/ ){
		$row =~ s/(^ *)<desc>(.+)/$1<cmt>$2/;
		my $buffer = $row;
		until ($row =~ /<\/desc>/){
			$row = <$fh>;	# read a single line
			$x++;  			# increment line counter
			chomp $row;
			$buffer.="\r\n".$row;
		}
		$buffer =~ s/<\/desc>/;  oCPN: $infile<\/cmt>/;
		$row= $buffer;
		next;
	}
	
	if ($row =~ s/^ *<type>WPT<\/type>//){  # we don't need this node in the Garmin file, so we're going to drop it and force a new line read
		$row = <$fh>;	# read a single line
		$x++;  			# increment line counter
		chomp $row;
	}
	#here's we handle extensions 
	if ($row =~ /^ *<extensions>/){  #first insert this Garmin-specific extension
		$row.="\r\n\t<gpxx:WaypointExtension>\r\n\t".
				"\t<gpxx:DisplayMode>SymbolAndName</gpxx:DisplayMode>\r\n\t".
				"</gpxx:WaypointExtension>";
		next;
	}
	if ($row =~ s/(<opencpn:guid>)([-0-9a-f]{36})(<\/opencpn:guid>)/<uuidx:uuid>$2<\/uuidx:uuid>/){ # change the tag name
		my $buffer=$row;
		until ($row =~ /^ *<\/extensions>/){  #skip through the rest of the extensions
			$row = <$fh>;	# read a single line
			$x++;  			# increment line counter
			chomp $row;
		}
		$row=$buffer."\r\n".$row;
		next;
	}

#series of symbol transformations
	my @symbolTransforms = (	['Anchor', 'Anchor'],
								['Bridge','Bridge'],
								['Hazard','Hazard'],
								['wreck','Caution'],
								['Marina','Marina'],
								['Symbol-Diamond-','Diamond, Blue'],
								['Information','Diamond, Green'],
								['Service','Diamond, Red'],
								['mooring','Diamond, Yellow'],
								['Pin,','Pin, Blue'],
								['Symbol-Glow-','Pin, Green'],
								['Symbol-Star','Pin, Red'],
								['Symbol-Spot','Pin, Yellow'],
								['Symbol-X-Large-Red','Triangle, Red'],
								['Symbol-Exclamation-Red','Triangle, Red'],
								['Flag, Green','Flag, Green'],
								['Boat Ramp','Boat Ramp'],
								['Fishing Area','Fishing Area'],
								['Waypoint','Waypoint']
								);
	foreach (@symbolTransforms){
		my ($cpnSym,$garminSym)=@$_;
#need to break out of the main loop, not just this foreach
		next main if $row =~ s/(<sym>.*)$cpnSym.*(<\/sym>)/$1$garminSym$2/i;
	}
	next if $row =~ /^ *<\/wpt>/;
	next if $row =~ /^ *<\/gpx>/;
	
	warn "unexpected value/tag at $x: $row\n";

 
}
continue {
    printf $outFH "%s\r\n", $row;
}

sub usage() {
    print "like this: \n\t".$commandname." -i [infile] -o [outfile]\n";
    print "\nThis transforms a set of OpenCPN waypoints to something that Garmin GPSMap 942 can use.\n";
    exit 1;
    }
