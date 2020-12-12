%%
clear all;
clc;
%load variables and network
load num;
load net;

%start timer
tic

pause(1);
fs=200e3;                               %sampling frequency
tr=2;                                   %length of recording
num_read=fs*tr;                         %number of samples to read

%serial port config
s=serialport("COM6",480e6);
flush(s);
write(s,int2str(tr),"char");
data=read(s,num_read*3,"uint16");
delete(s);

%split data into 3 arrays
data = reshape(data,3,num_read);
y1=data(1,:)*3.3/2^12-1.65;
y2=data(2,:)*3.3/2^12-1.65;
y3=data(3,:)*3.3/2^12-1.65;

%%
fc=40e3;                                %Centre frequency
l2 = (343/fc)/2;                        %factor to convert from frequency to velocity
ts=1/fs;                                %Sampling time
t=0:ts:tr-ts;                           %time instances
n=length(t);                            %length of time instances

%%
%creating notch filter coeficcients
w0=0.4;
bw=w0/1000;
[b,a]=iirnotch(w0,bw);

%apply notch filter to signal, baseband conversion, baseband filtering
bf=filter(b,a,y1);
bb=bf.*exp(-1j*2*pi*fc*t);
bbf1=filter(Num,1,bb);

bf=filter(b,a,y2);
bb=bf.*exp(-1j*2*pi*fc*t);
bbf2=filter(Num,1,bb);

bf=filter(b,a,y3);
bb=bf.*exp(-1j*2*pi*fc*t);
bbf3=filter(Num,1,bb);

%downsampling
ds=15;
bbf1_=downsample(bbf1,ds);
bbf2_=downsample(bbf2,ds);
bbf3_=downsample(bbf3,ds);

%new sampling frequency
fs=fs/ds;                                       

%%
%spectrogram conversion
[P1,F,T]=pspectrum(bbf1_,fs,'spectrogram','FrequencyResolution',128,'MinThreshold',-70);
[P2,~]=pspectrum(bbf2_,fs,'spectrogram','FrequencyResolution',128,'MinThreshold',-70);
[P3,~]=pspectrum(bbf3_,fs,'spectrogram','FrequencyResolution',128,'MinThreshold',-70);
vd=F*l2;
%%
%median frequency measurement
dv1=medfreq(P1,F)*l2;
dv2=medfreq(P2,F)*l2;
dv3=medfreq(P3,F)*l2;
dv1(1:5)=0;
dv2(1:5)=0;
dv3(1:5)=0;
dv1(end-5:end)=0;
dv2(end-5:end)=0;
dv3(end-5:end)=0;

%smoothing the median frequency measurements
dv1= smoothdata(dv1,'movmean',10);
dv2= smoothdata(dv2,'movmean',10);
dv3= smoothdata(dv3,'movmean',10);

%differential frequency calculation
diff1=dv1-dv2;
diff2=dv1-dv3;
diff3=dv2-dv3;

x=[];
x=[dv1;dv2;dv3;diff1;diff2;diff3];                  %uncomment if using LSTM
% x(1,:,:)=[dv1;dv2;dv3;diff1;diff2;diff3]';        %uncomment if using CNN
ypred = classify(net,x);                            %gesture prediction
disp(ypred);                                        %display predicted gesture

%end timer and display time taken
toc