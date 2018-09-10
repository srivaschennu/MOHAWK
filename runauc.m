function runauc(listname,varargin)

loadpaths

param = finputcheck(varargin, {
    'group', 'string', [], 'crsdiag'; ...
    'groupnames', 'cell', {}, {'UWS','MCS-','MCS+','EMCS','LIS','CTRL'}; ...
    });

featlist = {
    'power'                  [1]    '\delta'
    'power'                  [2]    'Relative power \theta'
    'power'                  [3]    '\alpha'
    'median'                 [1]    '\delta'
    'median'                 [2]    'Median dwPLI \theta'
    'median'                 [3]    '\alpha'
    'clustering'             [1]    '\delta'
    'clustering'             [2]    'Clustering coeff. \theta'
    'clustering'             [3]    '\alpha'
    'characteristic path length'     [1]    '\delta'
    'characteristic path length'     [2]    'Path length \theta'
    'characteristic path length'     [3]    '\alpha'
    'modularity'             [1]    '\delta'
    'modularity'             [2]    'Modularity \theta'
    'modularity'             [3]    '\alpha'
    'participation coefficient'     [1]    '\delta'
    'participation coefficient'     [2]    '\sigma(Participation coeff.) \theta'
    'participation coefficient'     [3]    '\alpha'
    'modular span'           [1]    '\delta'
    'modular span'           [2]    'Modular span \theta'
    'modular span'           [3]    '\alpha'
    };

for f = 1:size(featlist,1)
    %     load(sprintf('clsyfyr/clsyfyr_%s_%s_%s_%s.mat',featlist{f,1},featlist{f,2},bands{featlist{f,3}},param.group));
    %     if exist('clsyfyr','var')
    %         fnlist = fieldnames(clsyfyr);
    %         for fn = 1:length(fnlist)
    %             if ~isfield(clsyfyr,fnlist{fn})
    %                 clsyfyr = rmfield(clsyfyr,fnlist{fn});
    %             end
    %         end
    %     end
    %     clsyfyr(f,:) = clsyfyr;
    [~,~,statdata] = plotmeasure(listname,featlist{f,1},featlist{f,2},'noplot','on','group',param.group,'groupnames',param.groupnames);
    stats(f,:) = statdata;
end

save(sprintf('%s/stats_%s_%s.mat',filepath,listname,param.group),'stats','featlist');