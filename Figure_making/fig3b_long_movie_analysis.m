%% load and prepare
clear;clc;close all
load('c230513_03_all_nunchuck_data.mat');
[movie_indices]=find_in_structure(data.linker,'37PP0At_long_movies');
idx=movie_indices([2]);
fontsize=13;

%%
all_angles=abs(data.nnba{idx});
% num_chunks=round_down(length(all_angles)/500);

%% for each subset
for i_chunk=1:6
    edges=(0:5:180);
    bin_centers=edges(1:end-1)+2.5;
    start_frame=1+500*(i_chunk-1);
    end_frame=start_frame+499;
    angles=all_angles(start_frame:end_frame);
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
    
    %% plot result
    set(gcf,'units','normalized');%for fitting the generated figure to the size of screen
    set(gcf,'outerposition',[0 0 0.4 0.5]);
    subplot(2,3,i_chunk);
    color=rgb('CornFlowerBlue');
    %prepare histogram
    %     bin_counts = histcounts(abs(angles),edges,'Normalization', 'probability');
    binned = histcounts(abs(angles),edges);
    bin_counts = binned/sum(binned);
    histogram('BinEdges',edges,'BinCounts',bin_counts,'FaceColor',color);
    hold on
    err_bar = sqrt(binned)/length(~isnan(angles));
    errorbar([2.5:5:177.5],bin_counts,err_bar,'.','MarkerSize',5,'Color',rgb('Blue'),'LineWidth',1);
    fit_free.c=fit_free.c/sum(binned);
    h=plot(fit_free);
    legend off
    set(h,'linewidth',1.5,'color','k');
    str={strcat("\mu: ",num2str(round(fit_free.m,2,'significant')),char(176)),...
        strcat("\sigma: ",num2str(round(fit_free.sigma,2,'significant')),char(176))};
    text(0.55,0.75,str,'Units','normalized','FontSize',15,'Interpreter','tex');
    title(strcat(num2str(start_frame)," to ",num2str(end_frame)," sec"));
    xlim([0,180]);
    xlabel('bend angle ');
    ax = gca;
    ax.XTickLabel = strcat(ax.XTickLabel,char(176));
    ylabel('frequency');
    set(gca,'FontSize',fontsize);
    ylim([0,0.12]);
    %     set(gcf,'renderer','Painters')
    % print -depsc -tiff -r300 -painters <test>.eps
end
box on

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