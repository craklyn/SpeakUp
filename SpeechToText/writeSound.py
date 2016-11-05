import wave

waveFile = wave.open('output16bit.wav', 'r')
length = waveFile.getnframes()
for i in range(0,length):
  waveData = waveFile.readframes(1)
  data = map(ord, list(waveData))
  print(int(data[0]))


