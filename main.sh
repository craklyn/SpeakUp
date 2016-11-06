#!/bin/bash
#remove file .on to stop the script

apikey="ab00903b-664d-4efa-9966-4c258c562145"

function debugLog {
	echo $1 1>&2 
}


# speechToText file.wav
function speechToText {
	echo speechToText 1>&2 
	file=$1
	#curl -X POST --form "file=@$file" --form "apikey=$apikey" https://api.havenondemand.com/1/api/async/recognizespeech/v1 1>&2
	#curl -X POST --form "file=@test.wav" --form "apikey=ab00903b-664d-4efa-9966-4c258c562145" https://api.havenondemand.com/1/api/async/recognizespeech/v1 2>/dev/null 
	#curl -X GET https://api.havenondemand.com/1/job/status/w-eu_591ca1d8-d092-4867-b2d6-683a610db318?apikey=ab00903b-664d-4efa-9966-4c258c562145
	jobIdRaw=$(curl -X POST --form "file=@$file" --form "apikey=$apikey" https://api.havenondemand.com/1/api/async/recognizespeech/v1 2>/dev/null)

	jobId=$(echo $jobIdRaw | grep "jobID" | cut -d ':' -f2 | cut -d '"' -f'2' )
	if [ "$jobId" == "" ]; then
		echo "********* job ID is empty!!!" 1>&2 
		echo  "$jobIdRaw" 1>&2 
		echo "*******"  1>&2 
		echo 1>&2 
		rm .on
	fi 
	while [ -e .on ] && [ "$jobId" != "" ]; do
		sleep 5
		curlResult=$(curl -X GET https://api.havenondemand.com/1/job/status/$jobId?apikey=$apikey 2>/dev/null)

		echo $curlResult 1>&2 
		text=$(echo $curlResult | grep "content")

		if [ $? -eq 0 ]; then
			break
		fi
		
		# if error, break
		echo $curlResult | grep '"error"' >/dev/null
		if [ $? -eq 0 ]; then
			text=""
			break
		fi
	done
	
	outputText=$(echo $text | sed 's/.*"content"//g' | cut -d'"' -f2)
	echo "debug output:   $outputText" 1>&2 
	echo "$outputText"
}

# textAnalysis "a long sting of text perhaps"
# -1 to 1
function textAnalysis {
	text=$( echo $1 | sed 's/ /%20/g' | sed 's/[<>\/\\]/%20/g' )
	
	jsonResult=$(curl -X GET "https://api.havenondemand.com/1/api/sync/analyzesentiment/v1?text=$text&apikey=$apikey" 2>/dev/null)
	
	echo "$jsonResult" | grep '"error"' > /dev/null
	if [ $? -eq 0 ]; then 
		score=0
	else
		score=$(echo "$jsonResult" | sed 's/.*aggregate//g' | cut -d ',' -f2 | cut -d'}' -f1 | cut -d':' -f2)
	fi

	#curl -X GET "https://api.havenondemand.com/1/api/sync/analyzesentiment/v1?text=$text&apikey=ab00903b-664d-4efa-9966-4c258c562145"
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
function speechVolume {
	file=$1
	sox $file -b 16 .output16bit.wav
	python writeSound.py .output16bit.wav > .temp.out
	#sed -n '1,22050 p' .temp.out | datamash sstdev 1
	NLINES=$(echo $(wc -l temp.out) | cut -d' ' -f1)
	QUARTERSECONDS=$(expr $(( $NLINES / 11025)))

	#echo DEBUG: $QUARTERSECONDS 1>&2 
	outputArray=""
	for i in $(seq 1 $QUARTERSECONDS);
	do 
	  STARTLINE=$((1 + (i-1)*11025))
	  ENDLINE=$((i*11025))
	  stddev=$(sed -n "$STARTLINE,$ENDLINE p" temp.out | datamash sstdev 1)
	  outputArray="$outputArray, $stddev"
	  
	  #echo $stddev >> .temp.txt
	done

	#(tr '\n' ' ' < .temp.txt) > volumePerQuarterSecond.txt 
	
	
	#python getVolume $file
	echo "$outputArray"
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
	serverAddress="https://r3rl24plha.execute-api.us-east-1.amazonaws.com/test/records"
	textToken=$1
	speechSentiment=$2
	speechRate=$3
	speechVolume=$4
	startTime=$5
	endTime=$6
	
	username=$7
	
	jobID="$(openssl rand -base64 12)"
	
	jsonUserName="\"userName\":\"$username\""
	jsonStartTime="\"startTime\":\"$startTime\""
	jsonEndTime="\"endTime\":\"$endTime\""
	jsonVolume="\"speechVolume\":[$speechVolume]"
	jsonSentiment="\"sentiment\":\"$speechSentiment\""
	jsonTextToken="\"textToken\":\"$textToken\""
	
	jsonJobID="\"jobID\":\"$jobID\""
	
	json="{ $jsonUserName, $jsonStartTime, $jsonEndTime, $jsonVolume, $jsonSentiment, $jsonTextToken, $jsonJobID}"
	
	echo debug: $json
	echo

 	#curl "$serverAddress" -X POST --data "$json"
}

#read user name into username
echo enter username:
read username

touch .on
while [ -e .on ]; do
	timer=15
	wavFile="speech_$RANDOM.wav"
	startTime=$(timeNow)
	echo debug: started recorded
	record $wavFile $timer 
	echo debug: ended recorded
	endTime=$(timeNow)

	if [ -e $wavFile ]; then
		speechVolume=$(speechVolume $wavFile)
		speechText=$(speechToText $wavFile)
		speechSentiment=$(textAnalysis "$speechText")
		speechRate=$(speechRate "$speechText" $timer)
		
		upload "$speechText" "$speechSentiment" "$speechRate" "$speechVolume" "$startTime" "$endTime" "$username"
		rm $wavFile
	fi &
	
done &

echo started, to kill, "rm .on" 
echo "time now is" $(timeNow)
echo 