features = [];

load freqlist.mat

rawpower = zeros(size(allspec,1),size(freqlist,1),length(chanlocs));
for f = 1:size(freqbins,1)
    [~, bstart] = min(abs(freqbins-freqlist(f,1)));
    [~, bstop] = min(abs(freqbins-freqlist(f,2)));
    [~,peakindex] = max(mean(allspec(:,:,bstart:bstop),2),[],3);
    rawpower(f,:) = allspec(:,:,bstart+peakindex-1);
end

features = cat(2, features, mean(rawpower,3), std(rawpower,[],3));
features = cat(2, features, mean(bandpower,3), std(bandpower,[],3));

