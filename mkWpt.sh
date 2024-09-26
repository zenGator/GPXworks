#!/usr/bin/awk -f
# zG:220240925
#
# mkWpt.sh
# build waypoints from NOAA hurricane discussion
# fields:
#	2	time offset
#	3	timestamp
#	4	latitude
#	5	longitude
#	6	speed in kts
#	7	"KT"
#	8	speed in mph
#	9	"MPH"+...inland comments
BEGIN{	#there are a couple of fixed lines for the file header
	print "<?xml version=\"1.0\"?>";
	print "<gpx version=\"1.1\" creator=\"OpenCPN\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://www.topografix.com/GPX/1/1\" xmlns:gpxx=\"http://www.garmin.com/xmlschemas/GpxExtensions/v3\" xsi:schemaLocation=\"http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd http://www.garmin.com/xmlschemas/GpxExtensions/v3 http://www8.garmin.com/xmlschemas/GpxExtensionsv3.xsd\" xmlns:opencpn=\"http://www.opencpn.org\">";
}
match($0,/^INIT/,m) {			#INIT also identifies which advisory
	$0=" "$0;					#pre-pend a space so we can treat all lines identically
	split($0,myFields," *");	#file/text is multi-space delimited
	advisory=myFields[3];		#third field is date/time
}
{	
	split($0,myFields," *");	#each line has space prepended, & so fields (myFields) are offset by 1
	if (myFields[3]==advisory){myFields[3]="INIT";}			#let's have the initial marked as such
	if (!myFields[4]) {			#close file if there's no latitude
		print "</gpx>";			#close parent node
		exit;
		}
	sub(/[N]/,"",myFields[4]);				#strip the N/W from the lat/long
	sub(/[W]/,"",myFields[5]);				#strip the N/W from the lat/long
	print "<wpt lat=\""myFields[4]"\" lon=\"-"myFields[5]"\">";		#key component, lat/long
	split(myFields[3],myTS,"/");							#day/date is first part of timestamp
	patsplit(myTS[2],myTime,/../);							#insert colon in time component
	print "\t<time>2024-09-"myTS[1]"T"myTime[1]":"myTime[2]"</time>";
	print "\t<name>Helene @ "myFields[3]" per "advisory" advisory</name>";
	mySym="Weather-Tropical-Storm-NH";
	if (myFields[6] >= 64 ){mySym="Weather-Hurricane-NH"};	#TS is < 64kt wind
	print "\t<sym>"mySym"</sym>";							#either TS or Hurricane
	print "\t<type>WPT</type>\n\t<extensions>";				#fixed string
	print "\t\t<opencpn:viz_name>1</opencpn:viz_name>";		#fixed string, make visible
	print "\t</extensions>\n</wpt>";						#fixed string, close extensions and entire file
}
