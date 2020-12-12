load num;           %Loading filter coeficients
fs=200e3;           %sampling frequency
fc=40e3;            %centre frequency
tr=1;               %time to record in seconds
num_read=fs*tr;     %number of samples to receive
ts=1/fs;            %sampling time
t=0:ts:tr-ts;       %time stamp array

%creating notch filter coeficcients
w0=0.4;
bw=w0/1000;
[b,a]=iirnotch(w0,bw);

%loop for the amount of gestures to record in one session
num_recording = 100;
for k=1:num_recording    
    pause(0.5);
    %serial port configuration
    s=serialport('COM6',480e6);
    flush(s);
    write(s,int2str(tr),'char');
    data=read(s,num_read*3,'uint16');
    delete(s);
    
    %split data into 3 arrays
    data = reshape(data,3,num_read);
    y1 = data(1,:);
    y2 = data(2,:);
    y3 = data(3,:);
    
    %apply notch filter to signal
    nf1=filter(b,a,y1);
    nf2=filter(b,a,y2);
    nf3=filter(b,a,y3);
    
    %baseband conversion
    bb1=nf1.*exp(-1j*2*pi*fc*t);
    bb2=nf2.*exp(-1j*2*pi*fc*t);
    bb3=nf3.*exp(-1j*2*pi*fc*t);
    
    %baseband filtering
    bbf1=filter(Num,1,bb1);
    bbf2=filter(Num,1,bb2);
    bbf3=filter(Num,1,bb3);
    
    %downsampling
    ds=15;
    bbf1_ds=downsample(bbf1,ds);
    bbf2_ds=downsample(bbf2,ds);
    bbf3_ds=downsample(bbf3,ds);
    
    %save recordings
    X_bb{end+1,1}=[bbf1_ds;bbf2_ds;bbf3_ds];
    Y(end+1,1) = 'down';
    Y_lr(end+1,1) = 'down_R';
    disp(k);
end
% save data set
save('recordings.mat','X_bb','Y','Y_lr');