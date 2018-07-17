function checkjob(clust_job)

taskstates = {clust_job.Tasks.State}';
uniqstates = unique(taskstates);
for u = 1:length(uniqstates)
    fprintf('%d tasks %s.\n',sum(strcmp(uniqstates{u},taskstates)),uniqstates{u});
end