float margin =30;
PImage volumeicon;
PImage speedicon;
PImage timeicon;
float volumey;
float speedy;
float timey;
PFont bodyfont;
PFont displayfont;
PFont largefont;
float columnTwo;
color brand;
color good;
color goodStroke;
color ok;
color okStroke;
color bad;
color badStroke;
color grayStroke;
color grayBar;


void setup() {
  size(400,400);
  //String[] fontList = PFont.list();
  //printArray(fontList);
  smooth();
  volumeicon = loadImage("Volumesmall.png");
  timeicon = loadImage("TalkingTimesmall.png");
  speedicon = loadImage("Speedsmall.png");
  volumey = 120;
  speedy = 220;
  timey = 310;
  brand = color(67,185,208);
  good = color(99,203,130);
  ok = color(255,222,63);
  bad = color(255,148,76);
  goodStroke = color(67,187,103);
  okStroke = color(222,205,38);
  badStroke = color(233,128,57);
  grayStroke = color(233);
  grayBar = color(239);
  columnTwo = 90+margin;
  bodyfont = loadFont("HelveticaNeue-13.vlw");
  displayfont = loadFont("HelveticaNeue-Bold-13.vlw");
  largefont = loadFont("HelveticaNeue-Bold-30.vlw");
  

}

float volume = -1;
int wordCount = -1;
int timeSpeaking = -1;
String lines[] = null;

void draw() {
  textFont(bodyfont);
  background(255,255,255);
  fill(brand);
  noStroke();
  rect(0,0,400,48);
  fill(255);
  text("Your meeting is in progress", margin, 30);
  drawButton((width-margin-60),10, "end", 19);
  drawButton((width-margin-60-12-60),10, "pause", 13);
  drawMeetingTitle();
  
  
  lines = loadStrings("volumeResults.txt");
  if(lines.length > 0) {
    volume = Float.parseFloat(lines[0]);
    volume = 1.7*log(volume) - 7.0;
  }
  
//  text("Your volume is " + volume, margin, 120);
  drawVolume((int)volume);  

  lines = loadStrings("micTime.txt");
  if(lines.length > 0) {
    timeSpeaking = 1 + (int)(Integer.parseInt(lines[0]) * 0.25);
  }
//  text("Your time speaking is " + timeSpeaking + " seconds.", margin, 140);

  lines = loadStrings("wordCount.txt");
  if(lines.length > 0) {
    wordCount = Integer.parseInt(lines[0]);
  }
//  text("Your wordCount is " + wordCount, margin, 160);

  float talkSpeed = 1.0 + (1.5 * wordCount / timeSpeaking);
  if(talkSpeed > 8.0)
    talkSpeed = 8.0;
  drawSpeed((int)talkSpeed);

  drawTalkingTime(timeSpeaking);
  
  
}

void drawButton(float xposition, float yposition, String label, float labelposition){
  fill(255,255,255,80);
  stroke(15, 136, 160);
  rect(xposition, yposition, 60, 30);
  fill(30);
  text(label,xposition+labelposition, yposition+20);
}

void drawMeetingTitle(){
  fill(120);
  noStroke();
  text("#ladyproblems brainstorming session", margin, 75);
  text("Nov 6, 2:30pm", margin, 89);
}

void drawVolume(int vol){
  color volColor=color(255);
  color volStroke=color(255);
  textFont(displayfont);
  image(volumeicon, margin+9, volumey);
  fill(brand);
  text("Volume", margin, volumey+46);
  fill(grayBar);
  stroke(grayStroke);
  for (int i = 0; i < 8; i=i+1){
    rect(columnTwo+i*27, volumey, 20, 35);
  }
  if (vol > 4) {
    volColor = good;
    volStroke =goodStroke;
  } else if ( 2 < vol && vol <= 4 ) {
    volColor = ok;
    volStroke =okStroke;
  } else if (2 >= vol){
    volColor = bad;
    volStroke = badStroke;
  }
  fill(volColor);
  stroke(volStroke);
  for (int i = 0; i < vol; i++) {
    rect(columnTwo+i*27, volumey, 20, 35);
  }
  
}

void drawSpeed(int speed) {
  color speedColor = color(255);
  color speedStroke = color(255);
  image(speedicon, margin+8, speedy);
  fill(brand);
  text("Average", margin, speedy+36);
  text("Speed", margin+5, speedy+51);
  fill(grayBar);
  stroke(grayStroke);
  for (int i = 0; i < 8; i=i+1){
    rect(columnTwo+i*27, speedy, 20, 35);
  }
  
  if (speed > 3 && speed < 7) {
    speedColor = good;
    speedStroke =goodStroke;
  } else if ( speed == 3 || speed == 7 ) {
    speedColor = ok;
    speedStroke =okStroke;
  } else {
    speedColor = bad;
    speedStroke = badStroke;
  }
  fill(speedColor);
  stroke(speedStroke);
  for (int i = 0; i < speed; i++) {
    rect(columnTwo+i*27, speedy, 20, 35);
  }

}

void drawTalkingTime(int timeVal) {
  image(timeicon, margin+11, timey);
  fill(brand);
  text("Talking", margin, timey+46);
  text("Time", margin+7, timey+61);
  textFont(largefont);
  fill(67,185,208);
  noStroke();
  text(timeVal + " seconds", columnTwo, timey+30);

}
