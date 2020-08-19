#include <Arduino.h>
#include <IntervalTimer.h>
#include <Sonar.h>

IntervalTimer timer;
int counter=0;
int t=1;
int fs=200e3;
int ts=1/fs;
int numsamples = t/fs;

void ADC_sample(){
  
  if (counter<=numsamples){
    counter++;
    adc_sample();
  }
  else{
    digitalWrite(ledpin, LOW);
    counter=0;
    timer.end();
    stopTX();
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
    if (incomingByte=='s'){
      digitalWrite(ledpin, HIGH);
      Serial.flush();
      startTX();
      timer.begin(ADC_sample,ts);
    }
  }
}