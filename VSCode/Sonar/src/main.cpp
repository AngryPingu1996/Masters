#include <Arduino.h>
#include <IntervalTimer.h>
#include <Sonar.h>

IntervalTimer timer;
int counter=0;
int t=0;
int fs=200e3;
int numsamples = 0;

void ADC_sample(){
  if (counter<=numsamples){
    counter++;
    adc_sample();
  }
  else{
    digitalWrite(ledpin, LOW);
    counter=0;
    stopTX();
    timer.end();
  }
}

void setup() {
  setupCLK();
  setup_adc();
  Serial.begin(480e6);
  Serial.clear();
  pinMode(ledpin, OUTPUT);
  
}

void loop() {
  if (Serial.available()) {
    char incomingByte = Serial.read();
    t=atoi(&incomingByte);
    numsamples = t*fs;
    digitalWrite(ledpin, HIGH);
    Serial.flush();
    startTX();
    timer.begin(ADC_sample,5);
  }
}