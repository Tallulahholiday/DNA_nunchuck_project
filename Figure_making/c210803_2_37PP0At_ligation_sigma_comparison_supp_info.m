%% load data
clear;clc;close all;
load('all_nunchuck_data.mat');
load('error_percentage.mat');%this could be generated with code "c210428_1_determine_y_error_due_to_NN.m"
linker_names={'37PP0At','37PP0At_LS','37PP0At_newSEs','37PP0At_noT_new','37PP0n0At',...
    '37PP1n0At','37PP0At_cont_study','37PP0At_long_movies','37PP0At_fresh','37PP0At_1week','37PP0At_1week_0.2ul_MBN'};
axis_font=16;text_font=20;

%% find movie indices for seed-unligated and ligated cases, keeping only TFnormal1 movies
movie_indices=[];
for i=1:length(linker_names)-3
    movie_indices=[movie_indices,find_in_structure(data.linker,linker_names{i})];%find all indices for this linker type
end
movie_indices_unligated=setdiff(movie_indices,data.idx_outliers);%remove large-mu-small-sigma outliers
idx_TFnormal2=movie_indices_unligated(find(data.TFnormal2_or_not(movie_indices_unligated)==1));
movie_indices_unligated=setdiff(movie_indices_unligated,idx_TFnormal2);

movie_indices=[];
for i=length(linker_names)-2:length(linker_names)
    movie_indices=[movie_indices,find_in_structure(data.linker,linker_names{i})];%find all indices for this linker type
end
movie_indices_ligated=setdiff(movie_indices,data.idx_outliers);%remove large-mu-small-sigma outliers
idx_TFnormal2=movie_indices_ligated(find(data.TFnormal2_or_not(movie_indices_ligated)==1));
movie_indices_ligated=setdiff(movie_indices_ligated,idx_TFnormal2);
clear movie_indices

%% make aggregated set of unligated 37PP0At and fit to TFnormal1 with mu=0, bootstrap and plot
all_unligated_angles=[];
for idx=movie_indices_unligated
    angles=abs(data.nnba{idx});
    if isempty(angles)
        angles=abs(data.mba{idx});
    end
    all_unligated_angles=[all_unligated_angles,angles];
end
%preprare to fit
edges=(0:5:180);
[binned_data]=histcounts(all_unligated_angles,edges);
binned_data_cp=binned_data;
bin_centers=edges(1:end-1)+2.5;
bin_centers_cp=bin_centers;
c=5*sum(histcounts(all_unligated_angles,edges));
%error and weights
NN_error=error_percentage.*binned_data(1:28);%this only goes up to bin_center = 137.5 degrees
sqrt_error=sqrt(binned_data);
y_uncertainty=sqrt(NN_error.^2+(sqrt_error(1:28)).^2);
y_uncertainty(29:36)=sqrt_error(29:36);
weights=1./(y_uncertainty.^2);
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
%now we've removed 2 bins, do the actual fit
start = [c 0 40];
lower = [c 0 0];
upper = [c 0 1000];
[fit,gof] = TFNormal_custom_weights_210509(bin_centers,binned_data,weights,start,lower,upper);
r2=gof.rsquare;
sse=gof.sse;
%bootstrap
iterations=200;
[std_sigma,mean_sigma]=bootstrap_210606(all_unligated_angles,gof.rsquare,iterations,error_percentage);
%plot histogram
subplot(1,2,1);
histogram(all_unligated_angles,edges,'FaceColor',rgb('LightCoral'));
hold on;
errorbar(bin_centers_cp,binned_data_cp,y_uncertainty,'.','MarkerSize',15,'Color',rgb('Red'),'LineWidth',1.5);
xlim([0,180]);
%plot fit
plot(fit,'k');
legend('off');
str={strcat("# nunchucks: "+length(movie_indices_unligated)),...
    strcat("\sigma: ",num2str(round(mean_sigma,2,'significant')),"\pm",num2str(round(std_sigma,2,'significant')),char(176))};
text(0.4,0.75,str,'Units','normalized','FontSize',text_font,'Interpreter','tex');
%plot properties
xlabel('bend angle (degrees)','FontSize',text_font,'Interpreter','tex');
ylabel('number of frames','FontSize',text_font,'Interpreter','tex');
title('37bp_0At, unligated seeds','Interpreter','none');
set(gca, 'FontSize', axis_font);%setting axis font
set(gcf,'units','normalized');%for fitting the generated figure to the size of screen
set(gcf,'outerposition',[0.1 0.1 0.6 0.4]);

%% make aggregated set of ligated 37PP0At and fit to TFnormal1 with mu=0, bootstrap and plot
all_ligated_angles=[];
for idx=movie_indices_ligated
    angles=abs(data.nnba{idx});
    if isempty(angles)
        angles=abs(data.mba{idx});
    end
    all_ligated_angles=[all_ligated_angles,angles];
end
%preprare to fit
edges=(0:5:180);
[binned_data]=histcounts(all_ligated_angles,edges);
binned_data_cp=binned_data;
bin_centers=edges(1:end-1)+2.5;
bin_centers_cp=bin_centers;
c=5*sum(histcounts(all_ligated_angles,edges));
%error and weights
NN_error=error_percentage.*binned_data(1:28);%this only goes up to bin_center = 137.5 degrees
sqrt_error=sqrt(binned_data);
y_uncertainty=sqrt(NN_error.^2+(sqrt_error(1:28)).^2);
y_uncertainty(29:36)=sqrt_error(29:36);
weights=1./(y_uncertainty.^2);
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
%now we've removed 2 bins, do the actual fit
start = [c 0 40];
lower = [c 0 0];
upper = [c 0 1000];
[fit,gof] = TFNormal_custom_weights_210509(bin_centers,binned_data,weights,start,lower,upper);
r2=gof.rsquare;
sse=gof.sse;
%bootstrap
iterations=200;
[std_sigma,mean_sigma]=bootstrap_210606(all_ligated_angles,gof.rsquare,iterations,error_percentage);
%plot histogram
subplot(1,2,2);
histogram(all_ligated_angles,edges,'FaceColor',rgb('LightGreen'));
hold on;
errorbar(bin_centers_cp,binned_data_cp,y_uncertainty,'.','MarkerSize',15,'Color',rgb('MediumSeaGreen'),'LineWidth',1.5);
xlim([0,180]);
%plot fit
plot(fit,'k');
legend('off');
str={strcat("# nunchucks: "+length(movie_indices_ligated)),...
    strcat("\sigma: ",num2str(round(mean_sigma,2,'significant')),"\pm",num2str(round(std_sigma,2,'significant')),char(176))};
text(0.4,0.75,str,'Units','normalized','FontSize',text_font,'Interpreter','tex');
%plot properties
xlabel('bend angle (degrees)','FontSize',text_font,'Interpreter','tex');
ylabel('number of frames','FontSize',text_font,'Interpreter','tex');
title('37bp_0At, ligated seeds','Interpreter','none');
set(gca, 'FontSize', axis_font);%setting axis font

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

%% function "bootstrap_210606"
function [std_sigma,mean_sigma]=bootstrap_210606(angle_data,r_cutoff,iterations,error_percentage)
for bootrun=1:iterations
    bootrun
    sample=randsample(angle_data,length(angle_data),true);%"true" means with replacement
    edges=(0:5:180);
    centers=edges(1:end-1)+2.5;
    c=5*sum(histcounts(sample,edges));
    counts=histcounts(sample,edges);
    
    %error and weights
    NN_error=error_percentage.*counts(1:28);%this only goes up to bin_center = 137.5 degrees
    sqrt_error=sqrt(counts);
    %error propagation:
    y_uncertainty=sqrt(NN_error.^2+(sqrt_error(1:28)).^2);
    y_uncertainty(29:36)=sqrt_error(29:36);
    weights=1./(y_uncertainty.^2);%weight for a bin with N counts is = N
    weights(weights==Inf)=1;
    
    start = [c 0 40];
    lower = [c 0 0];
    upper = [c 0 10000];
    [fitresult,gof] = TFNormal_custom_weights_210509(centers,counts,weights,start,lower,upper);
    
    if gof.rsquare>r_cutoff-0.05
        sigma_boot(bootrun) = fitresult.sigma;
    else
        sigma_boot(bootrun) = nan;
    end
end
mean_sigma = nanmean(sigma_boot);
std_sigma = nanstd(sigma_boot);
end