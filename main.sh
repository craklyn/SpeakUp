#!/bin/bash

# speechToText file.wav
function speechToText {
	file=$1
	outputText=$(echo 'curl')
	echo $text
}

# textAnalysis "a long sting of text perhaps"
function textAnalysis {
	text=$1
	output=$(echo 'curl someurl text')
	echo $output
}

# record filename seconds; eg record sound.wav 30
function record {
	filename=$1
	seconds=$2
	echo "rec $filename 0 $seconds &>/dev/null"
	rec $filename trim 0 $seconds &>/dev/null
}

# volume file.wav 
# output an array of int(0-255), each represent the volume of the second
function volume {
	file=$1
	#python getVolume $file
}

# upload somedata
function upload {
	text=$1
	speechMode=$2
	speechRate=$3
	volume=$4
	echo curl upload
}

touch .on
while [ -e .on ]; do
	timer=5
	wavFile="speech.wav"
	record $wavFile $timer 

	if [ -e $wavFile ]; then
		text=$(speechToText $wavFile)
		speechMode=$(textAnalysis "$text")
		#speechRate
		volume=$(volume $wavFile)
		upload "$text" "$speechMode" "rate" "$volume"
	fi &
	
done
