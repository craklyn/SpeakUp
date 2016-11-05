#!/bin/bash
#remove file .on to stop the script

# speechToText file.wav
function speechToText {
	file=$1
	outputText=$(echo 'curl')
	echo "speechToText: this is a test $outputText"
}

# textAnalysis "a long sting of text perhaps"
function textAnalysis {
	text=$1
	output=$(echo 'curl someurl text')
	echo textAnalysis:$output
}

# record filename seconds; eg record sound.wav 30
function record {
	filename=$1
	seconds=$2
	sox -d $filename trim 0 $seconds &>/dev/null
}

# volume file.wav 
# output an array of int(0-255), each represent the volume of the second
function volume {
	file=$1
	#python getVolume $file
	echo [255,255,255,255]
}

# speechRate "sample string" timeInSeconds
# output a word per min value 
function speechRate {
	string=$1
	time=$2
	numberOfWord=$( echo "$string" | tr ' ' '\n' | wc -l)
	wordPerMin=$(( $numberOfWord * 60 / $time ))

	echo $wordPerMin
}

function timeNow {
	dateTimeString=$(curl http://www.timeapi.org/utc/now 2>/dev/null) 
	timeNow=$(echo $dateTimeString | cut -d 'T' -f2 | cut -d '+' -f1)
	echo $timeNow
}


# upload somedata
function upload {
	text=$1
	speechMode=$2
	speechRate=$3
	volume=$4
	echo curl upload
	echo "$text" 
	echo "$speechMode" 
	echo "$speechRate" 
	echo "$volume"
}


touch .on
while [ -e .on ]; do
	timer=5
	wavFile="speech.wav"
	record $wavFile $timer 

	if [ -e $wavFile ]; then
		speechText=$(speechToText $wavFile)
		speechMode=$(textAnalysis "$speechText")
		speechRate=$(speechRate "$speechText" $timer)
		speechVolume=$(volume $wavFile)
		
		upload "$speechText" "$speechMode" "$speechRate" "$speechVolume"
	fi &
	
done &

echo started, to kill, "rm .on" 
echo "time now is" $(timeNow)
echo 