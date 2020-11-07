load recordings_right;          %load saved data
X_post_lstm={};                 %empty array for the training data the LSTM network
X_post_cnn=[];                  %empty array for the training data for the CNN
fs=200e3/15;                    %sampling frequency after down sampling
fc=40e3;                        %centre frequency
l2 = (343/fc)/2;                %factor to convert from frequency to velocity
for k=1:length(X_bb)
    bbf1_ = X_bb{k,1}(1,:);
    bbf2_ = X_bb{k,1}(2,:);
    bbf3_ = X_bb{k,1}(3,:);

    %spectrogram conversion
    [P1,F,T]=pspectrum(bbf1_,fs,'spectrogram','FrequencyResolution',128,'MinThreshold',-60);
    [P2,~]=pspectrum(bbf2_,fs,'spectrogram','FrequencyResolution',128,'MinThreshold',-60);
    [P3,~]=pspectrum(bbf3_,fs,'spectrogram','FrequencyResolution',128,'MinThreshold',-60);
    
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
    
    
    X_post{k,1}=[dv1;dv2;dv3;diff1;diff2;diff3];            %data layout for LSTM
    X_post_cnn(1,:,:,k)=[dv1;dv2;dv3;diff1;diff2;diff3]';   %data layout for CNN
end
%save data
save('data_right.mat','X_post','X_post_cnn','Y');