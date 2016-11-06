#!/bin/bash
#remove file .on to stop the script

apikeysPool="4f9573f3-3488-4bb3-a83b-ff2ca590030b:07d4909b-f2a7-40ec-9534-75cd0237e8c4:e6e3103a-f5ea-457d-992f-df024fd90d5e:f8594837-5b82-4b0c-9716-c233015d6a39:ed60d868-1666-41c3-8fa2-f0f7c3152069:73df7388-c736-4731-b9d2-4aa9576ff701:dfe6e724-911e-4b4f-9df0-6dad1d712cf9:f4d8a28a-5857-49b5-8158-ea11580096fa:e874a5de-b18f-417c-aaee-3a7b3f6fa5da:221b0d20-187e-485c-af00-261ae94dc1c9:80306b71-caf9-45e4-b8fb-8780c8ec7f27:1cd0aa7e-883f-4791-a90d-3e9dabdf0f42"

apikey="ab00903b-664d-4efa-9966-4c258c562145"


# speechToText file.wav
function speechToText {
	echo "starting speechToText $count" 1>&2 
	file=$1
	#curl -X POST --form "file=@$file" --form "apikey=$apikey" https://api.havenondemand.com/1/api/async/recognizespeech/v1 1>&2
	#curl -X POST --form "file=@test.wav" --form "apikey=ab00903b-664d-4efa-9966-4c258c562145" https://api.havenondemand.com/1/api/async/recognizespeech/v1 2>/dev/null 
	#curl -X GET https://api.havenondemand.com/1/job/status/w-eu_591ca1d8-d092-4867-b2d6-683a610db318?apikey=ab00903b-664d-4efa-9966-4c258c562145
	jobIdRaw=$(curl -X POST --form "file=@$file" --form "apikey=$apikey" https://api.havenondemand.com/1/api/async/recognizespeech/v1 2>/dev/null)

	jobId=$(echo $jobIdRaw | grep "jobID" | cut -d ':' -f2 | cut -d '"' -f'2' )
	if [ "$jobId" == "" ]; then
		echo "********* job ID is empty!!!" 1>&2 
		#echo  "$jobIdRaw" | tr '' 1>&2 
		#echo "*******"  1>&2 
		#echo 1>&2 
		#rm .on
	fi 
	while [ -e .on ] && [ "$jobId" != "" ]; do
		sleep 5
		curlResult=$(curl -X GET https://api.havenondemand.com/1/job/status/$jobId?apikey=$apikey 2>/dev/null)

		#echo $curlResult 1>&2 
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
	echo "text To Speech result ($count): $outputText" 1>&2 
	echo "$outputText"
}

# textAnalysis "a long sting of text perhaps"
# -1 to 1
function textAnalysis {
	text=$( echo $1 | sed 's/ /%20/g' | sed 's/[<>\/\\]/%20/g' )
	
	jsonResult=$(curl -X GET "https://api.havenondemand.com/1/api/sync/analyzesentiment/v1?text=$text&apikey=$apikey" 2>/dev/null)
	

	echo "debug text $text" 1>&2 
	echo "debug api key $apikey" 1>&2 
	echo "debug jsonResult $jsonResult"
	
	echo "$jsonResult" | grep '"error"' > /dev/null
	if [ $? -eq 0 ]; then 
		score=0
	else
		score=$(echo "$jsonResult" | sed 's/.*aggregate//g' | cut -d ',' -f2 | cut -d'}' -f1 | cut -d':' -f2)
	fi

	#curl -X GET "https://api.havenondemand.com/1/api/sync/analyzesentiment/v1?text=$text&apikey=ab00903b-664d-4efa-9966-4c258c562145"
	echo "text Analysis result ($count): $score" 1>&2 
	
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
	echo "starting speechVolume ($count)" 1>&2 
	file=$1
	sox $file -b 16 output16bit.wav
	python writeSound.py output16bit.wav > .temp.out
	#sed -n '1,22050 p' .temp.out | datamash sstdev 1
	NLINES=$(echo $(wc -l .temp.out) | cut -d' ' -f1)
	QUARTERSECONDS=$(expr $(( $NLINES / 11025)))

	#echo DEBUG: $QUARTERSECONDS 1>&2 
	outputArray=""
	for i in $(seq 1 $QUARTERSECONDS);
	do 
	  STARTLINE=$((1 + (i-1)*11025))
	  ENDLINE=$((i*11025))
	  stddev=$(sed -n "$STARTLINE,$ENDLINE p" .temp.out | datamash sstdev 1)
	  outputArray="$outputArray, $stddev"
	  
	done
	
	#python getVolume $file

	echo "ending speechVolume ($count)" 1>&2 
	echo "$outputArray" | cut -d',' -f2- | sed 's/[ ,]*$//g'
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
	
	echo debug json to send: $json
	echo

	# actually sending out the request
 	curl "$serverAddress" -X POST --data "$json"
	
	#curl "https://r3rl24plha.execute-api.us-east-1.amazonaws.com/test/records" -X POST --data '{ "userName":"Kyle", "startTime":"2016-11-06 19:10:06", "endTime":"2016-11-06 19:10:21", "speechVolume":[ 742.74023151452, 1052.8724434048, 1368.1678977123, 1471.5171898344, 660.61758403054, 378.8484040583, 1028.8571613397, 432.39608033396, 71.468110690365, 461.17551592886, 187.27400463265, 188.71034860925, 1384.0271606744, 472.88485885089, 657.2478713472, 62.640429702527, 44.803614068124, 311.00176934837, 662.83107022778, 252.15985154048, 42.190253481325, 30.782603403563, 27.690060779129, 28.447454404775, 27.797645583109, 26.467696458392, 275.29331873992, 494.75239255643, 706.3260797411, 678.87443163902, 712.75369215112, 500.85662126828, 514.59081005462, 531.70673336901, 93.347073522959, 41.231100549282, 169.66216197676, 544.44418409903, 46.371761316453, 386.60853593992, 792.4114139759, 608.27978157301, 105.17918837618, 440.01595235117, 463.49119684077, 205.07185715928, 448.70636563535, 72.006988428065, 49.05443614954, 384.71119164335, 957.13161106652, 766.00861781557, 387.91494779553, 289.42692606843, 154.66007310612, 101.39763616629, 103.11419507329, 1143.961719542, 351.5233383938, 208.20572785655], "sentiment":"0.6", "textToken":"it just to say that this is the centuries it I have any actual lessons yet", "jobID":"d0yvUiFjy+Wflkjsdzklfjklaj"}'
	
}


apikeysPool=$(echo $apikeysPool | tr ':' '\n')

#read user name into username
#echo enter username:
#read username
#change me
userId=0
count=0

touch .on
rm wordsSaid.txt
rm micVolume.txt
while [ -e .on ]; do
	apikey=$(echo "$apikeysPool" | sed -n "$(( $userId * 2 + ( $count % 2 ) + 1 )) p" )
	count=$(( $count + 1 ))
	
	#break
	if [ $count -gt 5 ]; then
		break
	fi
	timer=15
	wavFile="speech_$RANDOM.wav"
	startTime=$(timeNow)
	echo "debug: started recording $count"
	record $wavFile $timer 
	echo "debug: ended recording $count"
	endTime=$(timeNow)

	if [ -e $wavFile ]; then
		speechText=$(speechToText $wavFile)
		speechVolume=$(speechVolume $wavFile)
		#echo debug $speechText
		
		#speechSentiment=$(textAnalysis "$speechText")
		#speechRate=$(speechRate "$speechText" $timer)
		
		#upload "$speechText" "$speechSentiment" "$speechRate" "$speechVolume" "$startTime" "$endTime" "$username"
		
		echo $speechText | tr ' ' '\n' >> wordsSaid.txt
		echo $speechVolume | tr ',' '\n' | sed 's/ //g' >> micVolume.txt
		rm $wavFile
	fi &
	#break
done &

echo started, to kill, "rm .on" 
echo "time now is" $(timeNow)
echo 
