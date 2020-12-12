clear;
clc;
close all;
load data_LR_no_rot;
reset(gpuDevice(1));

%split data into training/validation and testing
folds = 3;
c = cvpartition(Y_lr,'KFold',folds);
xtrainval = X_post_cnn(:,:,:,c.training(1));
xtest = X_post_cnn(:,:,:,c.test(1));
ytrainval = Y_lr(c.training(1));
ytest = Y_lr(c.test(1));

%10-fold cross-validation
folds = 10;
c = cvpartition(ytrainval,'KFold',folds);
acc=[];
acc_best=0;
acc_worst=100;
for k=1:folds
    %split training and validation data
    xtrain = xtrainval(:,:,:,c.training(k));
    xvalidation = xtrainval(:,:,:,c.test(k));
    ytrain = ytrainval(c.training(k));
    yvalidation = ytrainval(c.test(k));

    %training options
    epoch=10;
    miniBatchSize = 64;
    options = trainingOptions('adam', ...
        'ExecutionEnvironment','auto', ...
        'MaxEpochs',epoch, ...
        'MiniBatchSize',miniBatchSize, ...
        'ValidationData',{xvalidation,yvalidation}, ...
        'Shuffle','every-epoch', ...
        'InitialLearnRate',0.0019276, ...
        'ValidationFrequency',1);

    %CNN layers
    layers = [
        imageInputLayer([1 408 6],"Name","imageinput")
        convolution2dLayer(20,8,"Name","conv_1","Padding","same")
        batchNormalizationLayer("Name","batchnorm_1")
        reluLayer("Name","relu_1")
        maxPooling2dLayer(2,"Name","maxpool_1","Padding","same")
        convolution2dLayer(10,16,"Name","conv_2","Padding","same")
        batchNormalizationLayer("Name","batchnorm_2")
        reluLayer("Name","relu_2")
        maxPooling2dLayer(2,"Name","maxpool_2","Padding","same")
        convolution2dLayer(5,32,"Name","conv_3","Padding","same")
        batchNormalizationLayer("Name","batchnorm_3")
        reluLayer("Name","relu_3")
        maxPooling2dLayer(2,"Name","maxpool_3","Padding","same")
        fullyConnectedLayer(12,"Name","fc")
        softmaxLayer("Name","softmax")
        classificationLayer("Name","classoutput")];

    net = trainNetwork(xtrain,ytrain,layers,options);                       %network training
    ypred = classify(net,xtest);                                            %predict gestures from test data
    cm = confusionchart(ytest,ypred);                                       %create confusion matrix
    
    %find best and worst network from cross-validation
    acc_temp=mean(diag(cm.NormalizedValues));                               
    if acc_temp>=acc_best
        acc_best=acc_temp;
        best_net=net;
    end
    if acc_temp<=acc_worst
        acc_worst=acc_temp;
        worst_net=net;
    end
    
    %save the accuracy for each gesture
    acc(k,:)=diag(cm.NormalizedValues);
end
%%
close all;
acc_mean_fold=mean(acc,2)';                                                 %mean accuracy for each fold
acc_mean_folds=mean(acc_mean_fold);                                         %mean accuracy from all the folds
s=[ 'Fold Mean:' newline, num2str(acc_mean_fold), newline newline,...
    'Folds mean:' newline, num2str(acc_mean_folds)];
disp(s);

%Save to file
fid = fopen('lstm4.txt','wt');
fprintf(fid, s);
fclose(fid);

%plot box and whisker plot for each gesture
figure('Position',[100 100 700 350]);
% boxplot(acc,'Labels',{'in','out','left','right','up','down'});
boxplot(acc,'Labels',{'in_R','in_L','out_R','out_L','left_R','left_L','right_R','right_L','up_R','up_L','down_R','down_L'});
ylabel('Accuracy');
xlabel('Gesture');
grid on;
grid minor;
xtickangle(30);
saveas(gcf,'lstm4_cv.png');

%plot cofusion matrix from best fold
figure('Position',[100 100 700 350]);
ypred = classify(best_net,xtest);
cm = confusionchart(ytest,ypred);
cm.ColumnSummary = 'column-normalized';
cm.RowSummary = 'row-normalized';
saveas(gcf,'cm_lstm4_best.png');

%plot cofusion matrix from worst fold
figure('Position',[100 100 700 350]);
ypred = classify(worst_net,xtest);
cm = confusionchart(ytest,ypred);
cm.ColumnSummary = 'column-normalized';
cm.RowSummary = 'row-normalized';
saveas(gcf,'cm_lstm4_worst.png');