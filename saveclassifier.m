function saveclassifier(clust_job,clsyfyrinfo,suffix,varargin)

param = finputcheck(varargin, {
    'group', 'string', [], 'crsdiagwithcmd'; ...
    'sendmail', 'string', {'true','false'}, 'true'; ...
    });

loadpaths

if strcmp(param.sendmail,'true')
    %% setup e-mail preferences
    setpref('Internet','E_mail','sc785@kent.ac.uk');
    setpref('Internet','SMTP_Server','smtp.kent.ac.uk');
    setpref('Internet','SMTP_Username','sc785');
    setpref('Internet','SMTP_Password','CheBr0N1@3$');
    props = java.lang.System.getProperties;
    props.setProperty('mail.smtp.auth','true');
    props.setProperty('mail.smtp.socketFactory.class', 'javax.net.ssl.SSLSocketFactory');
    props.setProperty('mail.smtp.socketFactory.port','465');
end

disp('Waiting for tasks to finish.');
wait(clust_job);

if ~strcmp(clust_job.State,'finished')
    error('Job %d did finish correctly, state is %s.',clust_job.ID,clust_job.State);
end

disp('Fetching outputs.');
jobOut = fetchOutputs(clust_job);
jobOut = vertcat(jobOut{:});

savefile = sprintf('%sclsyfyr_%s_%s.mat',filepath,param.group,suffix);
save(savefile,'clsyfyrinfo');
for o = 1:size(jobOut,2)
    eval(sprintf('output%d = jobOut(:,o);',o));
    save(savefile,sprintf('output%d',o),'-append');
end

if strcmp(param.sendmail,'false')
    return
end

toemail = 'sc785@kent.ac.uk';
subject = sprintf('Job %d finished.',clust_job.ID);
body = sprintf('\nJob: %d\n',clust_job.ID);
body = sprintf('%sCluster: %s\n',body,clust_job.Parent.Profile);
body = sprintf('%sStart time: %s\n',body,clust_job.StartTime);
body = sprintf('%sFinish time: %s\n',body,clust_job.FinishTime);

sendmail(toemail,subject,body);
