#!/bin/bash
#remove file .on to stop the script

apikey="ab00903b-664d-4efa-9966-4c258c562145"
# speechToText file.wav
function speechToText {
	file=$1
	
	jobIdRaw=$(curl -X POST --form "file=@$file" --form "apikey=$apikey" https://api.havenondemand.com/1/api/async/recognizespeech/v1 2>/dev/null | grep "jobID" | cut -d ':' -f2)
	jobId=$(echo $jobIdRaw | cut -d '"' -f'2' )
	while true; do
		text=$(curl -X GET https://api.havenondemand.com/1/job/status/$jobId?apikey=$apikey 2>/dev/null | grep "content")
		if [ $? -eq 0 ]; then
			break
		fi
	done
	
	outputText=$(echo $text | cut -f4 -d'"')
	echo "$outputText"
}

# textAnalysis "a long sting of text perhaps"
# -1 to 1
function textAnalysis {
	text=$( echo $1 | sed 's/ /%20/g' | sed 's/[<>\/\\]/%20/g' )
	
	score=$(curl -X GET "https://api.havenondemand.com/1/api/sync/analyzesentiment/v1?text=$text&apikey=$apikey" 2>/dev/null | sed 's/.*aggregate//g' | cut -d ',' -f2 | cut -d'}' -f1 | cut -d':' -f2)

	echo $score
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
	timeNow=$(echo $dateTimeString | tr 'T' ' ' | cut -d '+' -f1)
	
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
	timer=30
	wavFile="speech.wav"
	record $wavFile $timer 

	if [ -e $wavFile ]; then
		speechVolume=$(volume $wavFile)
		speechText=$(speechToText $wavFile)
		speechMode=$(textAnalysis "$speechText")
		speechRate=$(speechRate "$speechText" $timer)
		
		upload "$speechText" "$speechMode" "$speechRate" "$speechVolume"
	fi &
	
done &

echo started, to kill, "rm .on" 
echo "time now is" $(timeNow)
echo 