clear;
clc;
close all;
load data_right_no_rot;
reset(gpuDevice(1));

%split data into training/validation and testing
folds = 3;
c = cvpartition(Y,'KFold',folds);
xtrainval = X_post_lstm(c.training(1));
xtest = X_post_lstm(c.test(1));
ytrainval = Y(c.training(1));
ytest = Y(c.test(1));

%split data into training and validation
folds = 10;
c = cvpartition(ytrainval,'KFold',folds);
xtrain = xtrainval(c.training(1));
xvalidation = xtrainval(c.test(1));
ytrain = ytrainval(c.training(1));
yvalidation = ytrainval(c.test(1));

%variables to optimise for
optimVars = optimizableVariable('Layers',[1 300],'Type','integer');

%function to run for optimisation
ObjFcn = makeObjFcn(xtrain,ytrain,xvalidation,yvalidation,xtest,ytest);

%bayes optimisation
BayesObject = bayesopt(ObjFcn,optimVars, ...
    'MaxTime',14*60*60, ...
    'IsObjectiveDeterministic',false, ...
    'UseParallel',false);

bestIdx = BayesObject.IndexOfMinimumTrace(end);
fileName = BayesObject.UserDataTrace{bestIdx};
savedStruct = load(fileName);
valError = savedStruct.valError;

[YPredicted,probs] = classify(savedStruct.trainedNet,xtest);
testError = 1 - mean(YPredicted == ytest);

NTest = numel(ytest);
testErrorSE = sqrt(testError*(1-testError)/NTest);
testError95CI = [testError - 1.96*testErrorSE, testError + 1.96*testErrorSE];

figure('Units','normalized','Position',[0.2 0.2 0.4 0.4]);
cm = confusionchart(ytest,YPredicted);
cm.Title = 'Confusion Matrix for Test Data';
cm.ColumnSummary = 'column-normalized';
cm.RowSummary = 'row-normalized';


%function to run for optimisation
function ObjFcn = makeObjFcn(XTrain,YTrain,XValidation,YValidation,XTest,YTest)
ObjFcn = @valErrorFun;
    function [valError,cons,fileName] = valErrorFun(optVars)
        layers = [
            sequenceInputLayer(6,"Name","sequence")
            lstmLayer(optVars.Layers,"Name","lstm1","OutputMode","sequence")
            batchNormalizationLayer("Name","batchnorm_1")
            bilstmLayer(optVars.Layers,"Name","bilstm","OutputMode","last")
            batchNormalizationLayer("Name","batchnorm_2")
            fullyConnectedLayer(6,"Name","fc")
            softmaxLayer("Name","softmax")
            classificationLayer("Name","classoutput")];

            epoch=15;
            miniBatchSize = 32;
            options = trainingOptions('adam', ... 
                'ExecutionEnvironment','auto', ...
                'MaxEpochs',epoch, ...
                'MiniBatchSize',miniBatchSize, ...
                'ValidationData',{XValidation,YValidation}, ...
                'Shuffle','every-epoch', ...
                'InitialLearnRate',0.0010949, ...
                'ValidationFrequency',1, ...
                'Verbose',false);
            
             trainedNet = trainNetwork(XTrain,YTrain,layers,options);
             YPredicted = classify(trainedNet,XTest);
             valError = 1 - mean(YPredicted == YTest);
             
             fileName = num2str(valError) + ".mat";
        save(fileName,'trainedNet','valError','options')
        cons = [];
    end
end