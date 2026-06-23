%% load and prepare
clear;clc;close all
load('c230513_03_all_nunchuck_data.mat');
[movie_indices]=find_in_structure(data.linker,'37PP0At_long_movies');
movie_indices=movie_indices([1,2,3,5,7,9]);
movie_indices=movie_indices([2,5,3,4]);
fontsize=14;

%%
for i_subplot=1:length(movie_indices)
    idx=movie_indices(i_subplot);
    all_angles=abs(data.nnba{idx});
    length(all_angles)
    num_chunks=round_down(length(all_angles)/500);
    mus=[];sigmas=[];
    angles_cell = cell(1, num_chunks);
    %% first fit
    for i_chunk=1:num_chunks
        edges=(0:5:180);
        bin_centers=edges(1:end-1)+2.5;
        start_frame=1+500*(i_chunk-1);
        end_frame=start_frame+499;
        angles=all_angles(start_frame:end_frame);
        angles_cell{i_chunk} = angles;
        [binned_data]=histcounts(angles,edges);
        c=5*sum(histcounts(angles,edges));
        %error and weights
        weights=1./binned_data;
        weights(weights==Inf)=1;
        %quick fit
        start = [c 90 40];
        lower = [c 0 0];
        upper = [c 180 10000];
        [fit,gof] = TFNormal_custom_weights_210509(bin_centers,binned_data,weights,start,lower,upper);
        curve_evaluated=fit(bin_centers)';
        diff=abs(curve_evaluated-binned_data);
        [sorted_diff,sort_idx]=sort(diff);
        outlier_bin_idx=[sort_idx(end),sort_idx(end-1)];
        bin_centers(outlier_bin_idx)=[];
        binned_data(outlier_bin_idx)=[];
        weights(outlier_bin_idx)=[];
        
        %% perform free-mu fit (mu unrestricted with starting point = 90)
        start = [c 90 40];
        lower = [c 0 0];
        upper = [c 180 10000];
        [fit_free,gof_free] = TFNormal_custom_weights_210509(bin_centers,binned_data,weights,start,lower,upper);
        mus=[mus,fit_free.m];
        sigmas=[sigmas,fit_free.sigma];
    end
    %% pairwise KS tests
    num_pairs = nchoosek(num_chunks, 2);
    pairs = nchoosek(1:num_chunks, 2);
    ks_pvalues = zeros(num_pairs, 1);
    ks_stats = zeros(num_pairs, 1);
    
    fprintf('\nMovie %d (index %d): %d chunks, %d pairs\n', i_subplot, idx, num_chunks, num_pairs);
    for ip = 1:num_pairs
        c1 = pairs(ip, 1);
        c2 = pairs(ip, 2);
        [~, p, ks2stat] = kstest2(angles_cell{c1}, angles_cell{c2});
        ks_pvalues(ip) = p;
        ks_stats(ip) = ks2stat;
        fprintf('  Chunks %d vs %d: D = %.4f, p = %.4e\n', c1, c2, ks2stat, p);
    end
    %% plot result
    subplot(2,2,i_subplot);
    box on
    hold on
    set(gcf,'units','normalized');%for fitting the generated figure to the size of screen
    set(gcf,'outerposition',[0.1 0.1 0.4 0.4]);
    set(gca,'FontSize',fontsize);
    plot([250:500:500*length(mus)-250],mus,'o','MarkerSize',15,'MarkerFaceColor',rgb('Salmon'),...
        'MarkerEdgeColor','none');
    plot([250:500:500*length(mus)-250],mus,'_','MarkerSize',8,'MarkerEdgeColor','k');
    for i=1:length(mus)
        line([(500*i-250),(500*i-250)],[mus(i),mus(i)+sigmas(i)],'color','k','linewidth',2);
    end
    ylim([0,110]);
    xlim([0,4500]);
    xlabel('time (sec)');
    ylabel('\mu and \sigma');
    pause(0.2);
    ax = gca;
    ax.YTickLabel = strcat(ax.YTickLabel,char(176));
end

%% function "TFNormal_custom_weights_210509"
function [fitresult,gof,coeffs,conf] = TFNormal_custom_weights_210509(bin_centers,BinnedData,weights,start,lower,upper)

%prepare the fit
[xData, yData] = prepareCurveData(bin_centers,BinnedData);

%define the fit
ft = fittype('(c/sqrt(2*pi*sigma^2))*(exp(-(-x-m)^2/(2*sigma^2))+exp(-(2*180-x-m)^2/(2*sigma^2))+exp(-(x-m)^2/(2*sigma^2))+exp(-(-2*180+x-m)^2/(2*sigma^2)))','independent', 'x', 'dependent', 'y' );
opts = fitoptions( 'Method', 'NonlinearLeastSquares','StartPoint' ,start,'Lower' ,lower, 'Upper', upper,...
    'MaxFunEvals',1000000,'MaxIter',1000000);
opts.Weights = weights;
opts.Display = 'Off';

% Fit model to data
[fitresult, gof] = fit( xData, yData, ft, opts );
coeffs = coeffvalues(fitresult);
conf=confint(fitresult);
end