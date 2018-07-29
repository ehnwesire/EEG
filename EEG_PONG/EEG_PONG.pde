/* Mind Pong
 * by Christian Henry
 *
 * Simple single player "pong" game. Measuring off the occipital lobe,
 * close your eyes and relax to increase alpha wave concentration and 
 * move the paddle up, open your eyes and focus to move the paddle down.
 *
 * This sketch has sparse documentation, as most of the code is taken
 * directly from the READ_EEG sketch. To make it easier to start off with,
 * this one is not object oriented. The two player version is.
 */
 
// commented by eric li the all-time cheater 
 
// importing the minim library 
 import ddf.minim.*;
 import ddf.minim.signals.*;
 import ddf.minim.analysis.*;
 import ddf.minim.effects.*;
 
 int windowLength = 500; // length and height of the window 
 int windowHeight = 400;
 int paddleWidth; // width and length of the paddle 
 int paddleLength;
 float[] alphaAverages; // an array of the averaged alpha waves? 
 int averageLength = 50; // not sure yet //averages about the last 5 seconds worth of data
 int counter = 0; // counting how many times the ball collides with the paddle 
 
 static int alphaCenter = 9; // center of the alpha waves? 
 static int alphaBandwidth = 2; //probably diving the alphawaves by 2? //really bandwidth divided by 2
 
 //mostly audio functions to grab/process the data
 Minim minim; // creating a minim object 
 AudioInput in; // setting the audio input object in 
 FFT fft; // perform a Fourier Transform on audio data to generate a frequency spectrum // in other words transforming the audio input as some sort of spectrum?
 BandPass alphaFilter; //Bandpass allows waves between two frequencies to pass
 float scaleFreq = 1.33f; // f is probably 440Hz
 
 boolean absoluteBadDataFlag;
 boolean averageBadDataFlag;
 
 //Parameters for the ball. For both pos and vel, 0 index is x and 1 index is y.
 float[] ballpos = {250,250};
 float ballspeed = 1;
 float[] ballvel = {0,0}; //velocity
 float ballrad = 10;      //radius
 
void setup(){
  alphaAverages = new float[averageLength]; // creating an array of 50 floats
  for (int i = 0; i < averageLength; i++){ // setting the floats value to 0
    alphaAverages[i] = 0;
  }
  
  size(500,400,P2D); // setting up the programs window with length 500 height 400 and p2d renderer
  background(0); //make background black
  stroke(0, 123, 0);   //and everything we draw white
  
  paddleWidth = 5; // the paddles width 
  paddleLength = (height-100) / 5; // the paddles length, i suppose its (400-100)/5 = 60?
  
  //initialize minim, as well as our alpha filter
  minim = new Minim(this);
  minim.debugOn();
  alphaFilter = new BandPass(alphaCenter/scaleFreq,alphaBandwidth/scaleFreq,32768); 
  // initializing alphaFilter as a new BandPass object, parameters refer to: float freq, float bandWidth, float sampleRate)
  // imo the alphaCenter might be the base frequency and Bandwith is the range? 
  
  
  in = minim.getLineIn(Minim.MONO, 8192*4); 
  // Audioinput object = minim.getLineIn(int type, int bufferSize) MONO refers to something, not sure
  // bufferSize refers to how long we want the sound card to process audio input
  in.addEffect(alphaFilter); // applying the bandpass filter to our audio input 
  fft = new FFT(in.bufferSize(), in.bufferSize()); // parameters: (int timeSize, float sampleRate)
  // we want to analyze the audio input for a long time and using the audio inputs buffer size as the sample rate
  fft.window(FFT.HAMMING); // creating a Hamming window to use on the sample buffers (or how the program shows the wave?)
}

void draw(){
  background(0); //clear previous drawings
  
  absoluteBadDataFlag = false; // not sure what this is 
  averageBadDataFlag = false; // not sure what this is 
  float timeDomainAverage = 0; // still not sure 
  
  fft.forward(in.mix); //compute FFT 
  // void forward(float[] buffer) forward transforms the buffer: i guess this makes the audio input into the sprctruM?
  line(0,100,windowLength,100); //line separating time and frequency data // yeah, just the line sitting there
  
  //get a good amount of time data
  // dont quite understand yet
  for(int i = 0; i < windowLength; i++){
    // abs = absolute value; in.left = the single channel of audio; .get = getting the ith sample in buffer
    // i = every pixel in the window length; round = rounding a float to int; in.bufferSize() = the inputs buffer size 
    // dividing by windowLength to get the windows current spectrum? 
    if (abs(in.left.get(i*round(in.bufferSize()/windowLength)))*2 > .95){
      absoluteBadDataFlag = true;
    }
    
    line(i, 50 + in.left.get(i*round(in.bufferSize()/windowLength))*100, 
         i+1, 50 + in.left.get((i+1)*round(in.bufferSize()/windowLength))*100);
   
    timeDomainAverage += abs(in.left.get(i*round(in.bufferSize()/windowLength)));
  }
  
  timeDomainAverage = timeDomainAverage / (windowLength);
  
  for (int i = 0; i < windowLength - 1; i++){
    if (abs(in.left.get((i+1)*round(in.bufferSize()/windowLength))) > timeDomainAverage*4)
      averageBadDataFlag = true;
  }
  
  // i dont quite understand this absoluteDataFlag thing :(
  // my guess is if the frequency exceeds the windows spectrum part the data wont get counted
  
  text("game controller project under construction", windowLength - 350, 20);
  text("mr trey eric li", windowLength - 170, 250);
  
  int lowBound = fft.freqToIndex(alphaCenter - alphaBandwidth); // AHA! it does indicate the high and low bound of the frequency
  int hiBound = fft.freqToIndex(alphaCenter + alphaBandwidth);
  
  lowBound = round(lowBound/scaleFreq); // getting the frequency to a moderate level 
  hiBound = round(hiBound/scaleFreq);
  
  float avg = 0;
  for (int j = lowBound; j <= hiBound; j++){ // doing this for every freqeuncy in the band pass filter
    avg += fft.getBand(j); //getting the amplitude of the frequency band and adding it to avg
  }
  avg /= (hiBound - lowBound + 1); // scaling, i guess?
  //scale averages a bit
  avg *= .3775;
  
  // setting the alpha data to avg if the datas are not bad?
  if (absoluteBadDataFlag == false && averageBadDataFlag == false){
    alphaAverages[counter%averageLength] = avg;
  }
  
  // adding all alphaAverages values to the final value 
  float finalAlphaAverage = 0;
  for (int k = 0; k < averageLength; k++){
    finalAlphaAverage += alphaAverages[k];
  }
  // getting the final average by dividing the avg num by 50
  finalAlphaAverage = finalAlphaAverage / averageLength;
  finalAlphaAverage = finalAlphaAverage - 200; //base average is around 100, normalize it
                                               //and make the lower half negative
  //so i think what we just did was averaging and getting the usable, doable frequency datas to the array and determine how the padle moves 
  float paddleHeight = height-paddleLength;
  
  // making the paddle move
  paddleHeight += finalAlphaAverage /5; //finalAlphaAverage ranges from about 0 to 200 now,
                                           //we want that to cover window of 0 to 300
  // the actualy game part 
  //make sure the paddle doesn't go off-screen
  if (paddleHeight > height - paddleLength)
    paddleHeight = height - paddleLength;
  if (paddleHeight < 100)
    paddleHeight = 100;

  rect(5,paddleHeight,paddleWidth,paddleLength);
  
  ballpos[0] += ballvel[0];
  ballpos[1] += ballvel[1];
  
  ellipse(ballpos[0],ballpos[1],ballrad,ballrad);
  
  //collision detection with paddle
  if ((ballpos[0] - ballrad > 5) && (ballpos[0] - ballrad < 5 + paddleWidth) && 
  (ballpos[1] < paddleHeight + paddleLength) && (ballpos[1] > paddleHeight)){
    ballvel[0] *= -1;
    float paddleCenter = (paddleHeight + (paddleHeight + paddleLength)) / 2;
    ballvel[1] = -(paddleCenter - ballpos[1])/15;
  }
  //collision detection with opposite wall
  if (ballpos[0] + ballrad > width){
    ballvel[0] *= -1;
  }
  //collision with top wall
  if (ballpos[1] < 100 + ballrad || ballpos[1] > height - ballrad){
    ballvel[1] *= -1;
  }
  
  counter++;
}

void keyPressed(){
  if (key == ' '){
    ballpos[0] = 250;
    ballpos[1] = 250;
    ballvel[0] = -ballspeed;
    ballvel[1] = 0;
  }
}
