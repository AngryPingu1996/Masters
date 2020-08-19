#include <ADC.h>

#define rx1 14
#define rx2 15
#define rx3 16
#define txFreq 40e3
#define txPin 18
#define clkFreq 2.05e6
#define clkPin 19
#define ledpin 13
ADC *adc = new ADC();


void setup_adc(){
    pinMode(rx1, INPUT);
    pinMode(rx2, INPUT);
    pinMode(rx3, INPUT);
    adc->adc0->setAveraging(0); // set number of averages
    adc->adc0->setResolution(13); // set bits of resolution
    adc->adc0->setConversionSpeed(ADC_CONVERSION_SPEED::VERY_HIGH_SPEED); // change the conversion speed
    adc->adc0->setSamplingSpeed(ADC_SAMPLING_SPEED::VERY_HIGH_SPEED); // change the sampling speed
}

void adc_sample(){
    uint16_t samples[3] = {(uint16_t)adc->analogRead(rx1), (uint16_t)adc->analogRead(rx2), (uint16_t)adc->analogRead(rx3)};
    uint8_t bytes[6];
    memcpy(bytes, samples, sizeof(bytes));
    Serial.write(bytes,6);
}

void setupCLK(){
    analogWriteFrequency(clkPin,clkFreq);
    analogWrite(clkPin,128);
}

void startTX(){
    tone(txPin,txFreq);
}

void stopTX(){
    noTone(txPin);
}