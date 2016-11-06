# To run:
# source makeSound.sh  > output.out 2>&1
# source makeSound.sh > /dev/null 2>&1

THRESHOLD_VALUE=0.2

for i in `seq 1000000`; do
  sox -d processing.wav trim 0 0.25
  sox processing.wav -b 16 processing16bit.wav
  rm processing.wav
  python processingWriteSound.py processing16bit.wav > temp.processing.out
  rm processing16bit.wav
  cat temp.processing.out | datamash sstdev 1 > data/volumeResults.txt
  rm temp.processing.out

  (wc -l < ../wordsSaid.txt | awk '{$1=$1;print}') > data/wordCount.txt
  (wc -l < ../micVolume.txt | awk '{$1=$1;print}') > data/micTime.txt  
done

