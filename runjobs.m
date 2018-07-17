[clust_job1,clsyfyrinfo1] = runclassifierjob('allsubj','phoenix','trainclassifier',{'tree','runpca','true','mode','cv'},'groups',[0 1],'groupnames',{'UWS','MCS-'});
[clust_job2,clsyfyrinfo2] = runclassifierjob('allsubj','phoenix','trainclassifier',{'tree','runpca','true','mode','cv'},'groups',[1 2],'groupnames',{'MCS-','MCS+'},'regroup',[0 1]);
[clust_job3,clsyfyrinfo3] = runclassifierjob('allsubj','phoenix','trainclassifier',{'tree','runpca','true','mode','cv'},'groups',[2 3],'groupnames',{'MCS+','EMCS'},'regroup',[5 3]);


[clust_job4,clsyfyrinfo4] = runclassifierjob('allsubj','phoenix','trainclassifier',{'tree','runpca','true','mode','train'},'groups',[0 1],'groupnames',{'UWS','MCS-'});
[clust_job5,clsyfyrinfo5] = runclassifierjob('allsubj','phoenix','trainclassifier',{'tree','runpca','true','mode','train'},'groups',[1 2],'groupnames',{'MCS-','MCS+'},'regroup',[0 1]);
[clust_job6,clsyfyrinfo6] = runclassifierjob('allsubj','phoenix','trainclassifier',{'tree','runpca','true','mode','train'},'groups',[2 3],'groupnames',{'MCS+','EMCS'},'regroup',[5 3]);

saveclassifier(clust_job1,clsyfyrinfo1,'allsubj_tree_UWS_MCS-_cv');
saveclassifier(clust_job2,clsyfyrinfo2,'allsubj_tree_MCS-_MCS+_cv');
saveclassifier(clust_job3,clsyfyrinfo3,'allsubj_tree_MCS+_EMCS_cv');
saveclassifier(clust_job4,clsyfyrinfo4,'allsubj_tree_UWS_MCS-_train');
saveclassifier(clust_job5,clsyfyrinfo5,'allsubj_tree_MCS-_MCS+_train');
saveclassifier(clust_job6,clsyfyrinfo6,'allsubj_tree_MCS+_EMCS_train');