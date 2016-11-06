import wave
import struct

waveFile = wave.open('output16bit.wav', 'r')
length = waveFile.getnframes()
for i in range(0,length):
  waveData = waveFile.readframes(1)
  data = struct.unpack("<hh", waveData)
  print(int(data[0]))
  print(int(data[1]))


