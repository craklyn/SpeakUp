# Python script to break file into values
#!/usr/bin/python
import sys
import wave

waveFile = wave.open(sys.argv[1], 'r')
length = waveFile.getnframes()
for i in range(0,length):
  waveData = waveFile.readframes(1)
  data = map(ord, list(waveData))
  print(int(data[0]))

