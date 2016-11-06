for i in `seq 1000`; do
  sox -d processing.wav trim 0 0.25
  sox processing.wav -b 16 processing16bit.wav
  python processingWriteSound.py processing16bit.wav > temp.processing.out
  cat temp.processing.out | datamash sstdev 1 > data/volumeResults.txt
done

