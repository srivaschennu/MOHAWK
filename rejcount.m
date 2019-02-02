function rejdata = rejcount(listname)

loadsubj
loadpaths

subjlist = eval(listname);

subjlist = table2cell(subjlist);

rejdata = subjlist(:,[1 3]);
for s = 1:size(scd adfasdfubjlist,1)
    basename = subjlist{s,1};
    EEG = pop_loadset('filepath',filepath,'filename',[basename '.set'],'loadmode','info');
    EEG.rejepoch = EEG.rejepoch(EEG.rejepoch < 60);
    rejdata{s,3} = ((60 + length(EEG.rejepoch)) * 10)/60;
    rejdata{s,4} = length(EEG.rejchan);
end