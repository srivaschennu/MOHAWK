function [clust_job,clsyfyrinfo,outputs] = runclassifierjob(listname,runmode,funcname,funcargs,varargin)

param = finputcheck(varargin, {
    'group', 'string', [], 'crsdiagwithcmd'; ...
    'groups', 'integer', [], [0 1]; ...
    'regroup', 'integer', [], []; ...
    'groupnames', 'cell', {}, {'UWS','MCS-'}; ...
    'downsample', 'string', {'true','false'}, 'false'; ...
    'covariates', 'string', {'true','false'}, 'false'; ...
    'suffix', 'string', '', ''; ...
    });

if strcmp(runmode,'serial') && isempty(param.suffix)
    error('File name suffix must be specified in serial mode.');
end

% runmode = serial, local or phoenix
loadpaths
loadsubj

%     'runclassifier' '{''svm-rbf'' ''runpca'' ''false'' ''mode'' ''cv''}'
%     'runclassifier' '{''knn'' ''runpca'' ''true'' ''mode'' ''cv''}'
%     'runclassifier' '{''tree'' ''runpca'' ''false'' ''mode'' ''cv''}'
%     'runclassifier' '{''nn'' ''runpca'' ''true'' ''mode'' ''cv''}'
%     'runclassifier' '{''nbayes'' ''runpca'' ''true'' ''mode'' ''cv''}'
    
%     'runclassifier' '{''svm-rbf'' ''runpca'' ''false'' ''mode'' ''train''}'
%     'runclassifier' '{''knn'' ''runpca'' ''true'' ''mode'' ''train''}'
%     'runclassifier' '{''tree'' ''runpca'' ''false'' ''mode'' ''train''}'
%     'runclassifier' '{''nn'' ''runpca'' ''true'' ''mode'' ''train''}'
%     'runclassifier' '{''nbayes'' ''runpca'' ''true'' ''mode'' ''train''}'

loadpaths
loadsubj

subjlist = eval(listname);

loadcovariates

% load 173to91.mat

groupvar = eval(param.group);

if ~isempty(param.regroup)
    groupvar(groupvar == param.regroup(1)) = param.regroup(2);
end

trange = 0.9:-0.1:0.1;

bands = {
    'delta'
    'theta'
    'alpha'
    };

featlist = {
    'power',1
    'power',2
    'power',3
    'median',1
    'median',2
    'median',3
    'clustering',1
    'clustering',2
    'clustering',3
    'characteristic path length',1
    'characteristic path length',2
    'characteristic path length',3
    'centrality',1
    'centrality',2
    'centrality',3
    'degree',1
    'degree',2
    'degree',3
    'modularity',1
    'modularity',2
    'modularity',3
    'participation coefficient',1
    'participation coefficient',2
    'participation coefficient',3
    'modular span',1
    'modular span',2
    'modular span',3
    };

selgroupidx = ismember(groupvar,param.groups);
groupvar = groupvar(selgroupidx);
[~,~,groupvar] = unique(groupvar);
groupvar = groupvar-1;

%% -- INITIALISATION

% -- Add current MATLAB path to worker path
curpath = path;
matlabpath = strrep(curpath,pathsep,''';''');
matlabpath = eval(['{''' matlabpath '''}']);
workerpath = cat(1,{pwd},matlabpath);

if exist('rawpath','var')
    workerpath = cat(1,{rawpath},workerpath);
end

if exist('filepath','var')
    workerpath = cat(1,{filepath},workerpath);
end

workerpath = strrep(workerpath,'M:\','\\csresws.kent.ac.uk\exports\home\');
workerpath = strrep(workerpath,'U:\','\\unicorn\');

%% -- MAIN SEQUENCE

if strcmp(runmode,'local')
    hpc_profile = 'local';
elseif strcmp(runmode,'phoenix')
    hpc_profile = 'HPCServerProfile1';
elseif strcmp(runmode,'aws')
    hpc_profile = 'aws';
end

clust_job = [];
if ~strcmp(runmode,'serial')
    disp('Connecting to Cluster.');
    clust = parcluster(hpc_profile);
    if isfield(clust,'State') && ~strcmp(clust.State,'online')
        fprintf('Starting %s...\n',hpc_profile);
        clust.start;
        wait(clust, 'online');
    end
    
    hostname = get(clust,'Host');
    disp(['Cluster selected: ' hostname]);
    disp(['No of Workers: ' num2str(clust.NumWorkers)]);
    
    disp('Creating job, attaching files.');
    clust_job = createJob(clust,'AdditionalPaths',workerpath');
    %clust_job.AutoAttachFiles = false;      % Important, this speeds things up

    disp('Creating input for tasks.');

    disp('Creating tasks, adding to job... ');
end

taskidx = 1;
funcname = str2func(funcname);
outputs = {};
for f = 1:size(featlist,1)
    fprintf('Feature set: ');
    disp(featlist(f,:));
    measure = featlist{f,1};
    bandidx = featlist{f,2};
    
    features = getfeatures(listname,measure,bandidx,'trange',trange);
    features = features(selgroupidx,:,:);
    
    features = permute(features,[1 3 2]);
    
    if strcmp(param.downsample,'true') && size(features,2) > 1
        features = features(:,keepidx,:);
    end
    
    if strcmp(param.covariates,'true')
        covariates = getfeatures(listname,'demo');
        covariates = covariates(selgroupidx,:);
    else
        covariates = [];
    end
    
    for d = 1:size(features,3)
        clsyfyrparam{taskidx,1} = featlist{f,1};
        clsyfyrparam{taskidx,2} = bands{featlist{f,2}};
        clsyfyrparam{taskidx,3} = trange(d);
        clsyfyrparam{taskidx,4} = funcargs;

        args = [{[covariates features(:,:,d)], groupvar}, funcargs];
        
        if strcmp(runmode,'serial')
            outputs = cat(1,outputs,funcname( args{:} ));
        else
            tasks(taskidx) = createTask(clust_job, funcname, 1, args, 'CaptureDiary', true);
        end
        taskidx = taskidx + 1;
    end
end

clsyfyrinfo.clsyfyrparam = clsyfyrparam;
clsyfyrinfo.groups = param.groups;
clsyfyrinfo.groupnames = param.groupnames;
clsyfyrinfo.bands = bands;
clsyfyrinfo.trange = trange;
clsyfyrinfo.funcparam = param;

if strcmp(runmode,'serial')
    savefile = sprintf('%sclsyfyr_%s_%s_%s.mat',filepath,param.group,listname,param.suffix);
    save(savefile,'clsyfyrinfo');
    for o = 1:size(outputs,2)
        eval(sprintf('output%d = outputs(:,o);',o));
        save(savefile,sprintf('output%d',o),'-append');
    end
    return;
end

fprintf('created %d tasks.\n',length(tasks(:)));

disp('Submitting job to cluster queue.');
submit(clust_job);

disp('Done.');
