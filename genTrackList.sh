#!/bin/bash
# zG:20240613
# generates list of tracks in a standard gpx file

grep -A1 "<trk>" "$1" |grep "</\?name>"| sed "s/<\/\?name>//g; s/^ *//"
