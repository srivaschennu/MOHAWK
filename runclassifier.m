function [clsyfyr,models] = runclassifier(features,labels,type,varargin)

param = finputcheck(varargin, {
    'mode', 'string', {'cv','holdout','train'}, 'cv'; ...
    'runpca', 'string', {'true','false'}, 'false'; ...
    'rand', 'string', {'true','false'}, 'false'; ...
    });

clsyfyropt = {'Standardize',true};
innercv = {'Leaveout','on'};

switch type
    case 'knn'
        Nvals = 1:10;
        hyperparam = {Nvals};
        
    case 'svm-linear'
        Cvals = [.001 .01 .1 .2 .5 1 2 10];
        hyperparam = {Cvals};
        
    case 'svm-rbf'
        Cvals = [.001 .01 .1 .2 .5 1 2 10];
        Kvals = [.001 .01 .1 .2 .5 1 2 10];
        hyperparam = {Cvals, Kvals};
        
    case 'tree'
        Lvals = 1:15;
        hyperparam = {Lvals};
        
    case 'nbayes'
        hyperparam = {};
end

rng('default');

clsyfyr.truelabels = labels;

if strcmp(param.mode,'cv')
    numcvfolds = 4;
    outercv = cvpartition(labels,'KFold',numcvfolds);
    numfolds = 20;
    for f = 2:numfolds/numcvfolds
        outercv(f) = repartition(outercv(f-1));
    end
    clsyfyr.predlabels = NaN(size(labels,1),numfolds/numcvfolds);
elseif strcmp(param.mode,'holdout')
    holdout = 0.3;
    outercv = cvpartition(labels,'HoldOut',holdout);
    numfolds = 25;
    for f = 2:numfolds
        outercv(f) = repartition(outercv(f-1));
    end
    clsyfyr.predlabels = NaN(size(labels,1),numfolds);
elseif strcmp(param.mode,'train')
    outercv = cvpartition(labels,'resubstitution');
    numfolds = 1;
    clsyfyr.predlabels = NaN(size(labels));
else
    error('Unrecognised mode');
end

% PCA - Keep enough components to explain the desired amount of variance.
explainedVarianceToKeepAsFraction = 95/100;

%% search through parameters for best cross-validated classifier

if size(features,2) > 1 && strcmp(param.runpca,'true')
    fprintf('Calculating Principal Components...\n');
    [pcaCoeff, pcaScores, ~, ~, explained] = pca(features,'Centered',true);
    numPCAComponentsToKeep = find(cumsum(explained)/sum(explained) >= explainedVarianceToKeepAsFraction, 1);
    features = pcaScores(:,1:numPCAComponentsToKeep);
    clsyfyr.pcaCoeff = pcaCoeff(:,1:numPCAComponentsToKeep);
else
    clsyfyr.pcaCoeff = [];
end

models = cell(1,numfolds);
fprintf('Outer fold');
for f = 1:numfolds
    fprintf(' %d',f);
    
%     if strcmp(param.rand,'true')
%         labels = labels(randperm(length(labels)));
%     end
    
    if strcmp(param.mode,'holdout')
        trainidx = training(outercv(f));
        testidx = test(outercv(f));
    elseif strcmp(param.mode,'cv')
        trainidx = training(outercv(floor((f-1)/numcvfolds)+1),mod((f-1),numcvfolds)+1);
        testidx = test(outercv(floor((f-1)/numcvfolds)+1),mod((f-1),numcvfolds)+1);
    end
    
    perf = gridsearch(features(trainidx,:), labels(trainidx), ...
        type, innercv, clsyfyropt, hyperparam);
    [~,maxidx] = max(perf(:));
    
    switch type
        case 'knn'
            bestN = ind2sub(size(perf),maxidx);
%             model = fitensemble(features(training(cvp,c),:), labels(training(cvp,c)), 'Subspace', 100, ...
%                 templateKNN(clsyfyropt{:},'NumNeighbors', Nvals(bestN)));            
            model = fitcecoc(features(trainidx,:), labels(trainidx), 'Prior', 'uniform', ...
                'Learners', templateKNN(clsyfyropt{:},'NumNeighbors', Nvals(bestN)));
            
        case 'svm-linear'
            [bestC] = ind2sub(size(perf),maxidx);
            model = fitcecoc(features(trainidx,:), labels(trainidx), 'Prior', 'uniform', ...
                'Learners', templateSVM(clsyfyropt{:},'BoxConstraint',Cvals(bestC)));
            
        case 'svm-rbf'
            [bestC,bestK] = ind2sub(size(perf),maxidx);
            model = fitcecoc(features(trainidx,:), labels(trainidx), 'Prior', 'uniform', ...
                'Learners', templateSVM(clsyfyropt{:},'KernelFunction','RBF',...
                'BoxConstraint',Cvals(bestC),'KernelScale',Kvals(bestK)));
            
        case 'tree'
            bestL = ind2sub(size(perf),maxidx);
%             model = fitensemble(features(training(cvp,c),:), labels(training(cvp,c)), 'AdaBoostM2', 100, ...
%                 templateTree('MinLeafSize', Lvals(bestL)));            
            model = fitcecoc(features(trainidx,:), labels(trainidx), 'Prior', 'uniform', ...
                'Learners', templateTree('MinLeafSize', Lvals(bestL)));
            
        case 'nbayes'
            model = fitcecoc(features(trainidx,:), labels(trainidx), 'Prior', 'uniform', ...
                'Learners', templateNaiveBayes('DistributionNames', 'kernel'));
            
    end
    
    if strcmp(param.mode,'holdout')
        clsyfyr.predlabels(testidx,f) = predict(model, features(testidx,:));
    else    
        clsyfyr.predlabels(testidx,floor((f-1)/numcvfolds)+1) = predict(model, features(testidx,:));
    end
    
    models{f} = model;
end
fprintf('\nDone.\n');

for f = 1:size(clsyfyr.predlabels,2)
    cm = confusionmat(labels(~isnan(clsyfyr.predlabels(:,f))),...
        clsyfyr.predlabels(~isnan(clsyfyr.predlabels(:,f)),f),...
        'order',unique(labels(~isnan(clsyfyr.predlabels(:,f)))));
    clsyfyr.cm(:,:,f) = cm;
    cm  = cm + eps;
    cm = cm ./ repmat(sum(cm,2),1,size(cm,2));
    clsyfyr.perf(f) = mean(diag(cm));
end

clsyfyr.funcopt = param;
clsyfyr.clsyfyropt = clsyfyropt;
clsyfyr.cvopt = innercv;
if strcmp(param.mode,'cv')
    clsyfyr.numfolds = numfolds/numcvfolds;
else
    clsyfyr.numfolds = numfolds;
end
end

function perf = gridsearch(features,labels,type,cvopt,clsyfyropt,hyperparam)

switch type
    case 'knn'
        Nvals = hyperparam{1};
        perf = zeros(size(Nvals));
        for n = 1:length(Nvals)
%             model = fitensemble(features,labels,'Subspace',100,...
%                 templateKNN(clsyfyropt{:},'NumNeighbors',Nvals(n)),cvopt{:});
            model = fitcecoc(features,labels,cvopt{:}, 'Prior', 'uniform', ...
                'Learners',templateKNN(clsyfyropt{:},'NumNeighbors',Nvals(n)));
            perf(n) = getperf(model,labels);
        end
        
    case 'svm-linear'
        Cvals = hyperparam{1};
        perf = zeros(length(Cvals));
        for c = 1:length(Cvals)
            model = fitcecoc(features,labels,cvopt{:}, 'Prior', 'uniform', ...
                'Learners',templateSVM(clsyfyropt{:},'BoxConstraint',Cvals(c)));
            perf(c) = getperf(model,labels);
        end
        
    case 'svm-rbf'
        Cvals = hyperparam{1};
        Kvals = hyperparam{2};
        perf = zeros(length(Cvals),length(Kvals));
        for c = 1:length(Cvals)
            for k = 1:length(Kvals)
                model = fitcecoc(features,labels,cvopt{:}, 'Prior', 'uniform', ...
                    'Learners',templateSVM(clsyfyropt{:},'KernelFunction','RBF',...
                    'BoxConstraint',Cvals(c),'KernelScale',Kvals(k)));
                perf(c,k) = getperf(model,labels);
            end
        end
        
    case 'tree'
        Lvals = hyperparam{1};
        perf = zeros(size(Lvals));
        for l = 1:length(Lvals)
%             model = fitensemble(features,labels,'AdaBoostM2',100,...
%                 templateTree('MinLeafSize',Lvals(l)),cvopt{:});            
            model = fitcecoc(features,labels,cvopt{:}, 'Prior', 'uniform', ...
                'Learners',templateTree('MinLeafSize',Lvals(l)));
            perf(l) = getperf(model,labels);
        end
        
    case 'nbayes'
        model = fitcecoc(features,labels,cvopt{:}, 'Prior', 'uniform', ...
            'Learners',templateNaiveBayes('DistributionNames','kernel'));
        perf = getperf(model,labels);
end
end

function perf = getperf(model,labels)
predlabels = kfoldPredict(model);
cm = confusionmat(labels,predlabels,'order',unique(labels));
cm = cm ./ repmat(sum(cm,2),1,size(cm,2));
perf = mean(diag(cm));
end