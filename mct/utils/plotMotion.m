function plotMotion(i, c_m, k, n, floor_image, cands_homo_percam)
    chunks = reshape(c_m,k,n);
    figure; hold on;
    %openfig(floor_image); hold on;
    colormap(summer);
    for t = 1:size(cands_homo_percam{i},2)
        for j = 1:k
            sz = 20;
            scatter(cands_homo_percam{i}{t}(j,1), cands_homo_percam{i}{t}(j,2),sz,chunks(j,t),'square','filled');
        end
    end
    colorbar;
end
