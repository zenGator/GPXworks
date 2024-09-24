#!/bin/bash
# zG:20240707
# data reduction:  only 1 waypoint per 15 seconds

awk 'BEGIN{oldtime=0}; 
	match($0,/<time>([-0-9:.TZ]{20,27})<\/time>/,m) {
		rawtime=m[1];
		split(rawtime,daytime,"T"); 
		split(daytime[1],date,"-"); 
		daytime[2]=substr(daytime[2],1,8); 
		split(daytime[2],time,":"); 
		newtime=mktime(sprintf("%s %s %s %s %s %s",date[1],date[2],date[3],time[1],time[2],time[3])); 
		delta=newtime-oldtime; 
		if(delta>15){
			print $0;
			oldtime=newtime;
			}
		next;
	}{print $0};' "$1"
