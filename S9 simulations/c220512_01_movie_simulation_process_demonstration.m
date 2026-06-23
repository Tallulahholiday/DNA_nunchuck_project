% %% load files for paper 2, find movie indices
% clear;clc;close all
% load('c220510_00_all_nunchuck_data.mat');
% load('c220119_4_pulled_NN_test_results.mat');
% 
% bin_edges=(0:5:180);
% bin_centers=bin_edges(1:end-1)+2.5;
% 
% idx=1411;
% idx=1436
% mu=data.fit{idx}.m;
% sigma=data.fit{idx}.sigma;
% movie_length=round(length(data.nnba{idx})*data.delay(idx));
% linker=data.linker{idx};
% set_idx=find_in_structure(set_data.name,linker);
% NN=set_data.NN{set_idx};
% if strcmp(NN,'hand') | strcmp(NN,'NN13')
%     NN_angles=NN_angles_13;
%     real_angles=real_angles_13;
% elseif strcmp(NN,'NN22')
%     NN_angles=NN_angles_22;
%     real_angles=real_angles_22;
% elseif strcmp(NN,'NN22_100')
%     NN_angles=NN_angles_22100;
%     real_angles=real_angles_22100;
% elseif strcmp(NN,'AlexNet_test4_28')
%     NN_angles=NN_angles_28;
%     real_angles=real_angles_28;
% end
% 
% %make TFnormal using mu and sigma
% weights=exp(-(-bin_centers-mu).^2/(2*sigma^2))+exp(-(2*180-bin_centers-mu).^2/(2*sigma^2))+...
%     exp(-(bin_centers-mu).^2/(2*sigma^2))+exp(-(-2*180+bin_centers-mu).^2/(2*sigma^2));
% weights=weights/(sum(weights));%normalize
% % draw angles to construct an imaged movie
% drawn_angles=randsample(bin_centers,movie_length,true,weights);
% % do an NN mapping to imitate analysis by NN
% binned_data=histcounts(drawn_angles,bin_edges);
% drawn_NN_angles=[];
% for i_bin=1:size(bin_edges,2)-1
%     bin_center=bin_centers(i_bin);
%     idx_real_angles=[find(real_angles==bin_center-0.5),find(real_angles==-bin_center+0.5)];
%     drawn_NN_angles=[drawn_NN_angles,randsample(NN_angles(idx_real_angles),binned_data(i_bin),true)];
% end
% 
% %fit
% binned_data=histcounts(drawn_NN_angles,bin_edges);
% c=5*sum(binned_data);
% start = [c mu sigma];
% lower = [c 0 0];
% upper = [c 180 200];
% fit_weights=1./binned_data;
% fit_weights(fit_weights==Inf)=1;
% [fit,gof]=TFnormal_211201(bin_centers,binned_data,fit_weights,start,lower,upper);

%% plot
close
load('c220512_01_example.mat');
set(gcf,'units','normalized');
set(gcf,'outerposition',[0 0 0.6 0.35]);

subplot(1,3,1);%original bend angle histogra,
histogram(abs(data.nnba{idx}),bin_edges,'FaceColor',rgb('CornFlowerBlue'));
hold on
h=plot(data.fit{idx});
legend off
set(h,'linewidth',2,'color','r');
str={strcat("\mu: ",num2str(round(data.fit{idx}.m,2,'significant')),char(176)),...
        strcat("\sigma: ",num2str(round(data.fit{idx}.sigma,2,'significant')),char(176))};
text(0.55,0.75,str,'Units','normalized','FontSize',15,'Interpreter','tex');
xlim([0,180]);
xlabel('bend angle');
ylabel('frames');
title('original bend angles with fit','interpreter','none');
set(gca,'fontsize',15);
ax = gca;
ax.XTickLabel = strcat(ax.XTickLabel,char(176));

subplot(1,3,2);%sampled bend angles
histogram(drawn_angles,bin_edges,'FaceColor',rgb('CornFlowerBlue'));
xlim([0,180]);
ylim([0,max(histcounts(drawn_angles,bin_edges))*1.2]);
xlabel('bend angle');
ylabel('frames');
title('bend angles from step 3 of simulation','interpreter','none');
set(gca,'fontsize',15);
ax = gca;
ax.XTickLabel = strcat(ax.XTickLabel,char(176));

subplot(1,3,3);%NN analyzed bend angles
histogram(drawn_NN_angles,bin_edges,'FaceColor',rgb('CornFlowerBlue'));
xlim([0,180]);
ylim([0,max(histcounts(drawn_NN_angles,bin_edges))*1.2]);
start = [c 90 40];
lower = [c 0 0];
upper = [c 180 10000];
[fit,gof] = TFNormal_custom_weights_210509(bin_centers,binned_data,weights,start,lower,upper);
hold on
h=plot(fit);
legend off
set(h,'linewidth',2,'color','r');
str={strcat("\mu: ",num2str(round(fit.m,2,'significant')),char(176)),...
        strcat("\sigma: ",num2str(round(fit.sigma,2,'significant')),char(176))};
text(0.55,0.75,str,'Units','normalized','FontSize',15,'Interpreter','tex');
xlabel('bend angle');
ylabel('frames');
title('bend angles from step 4 of simulation','interpreter','none');
set(gca,'fontsize',15);
ax = gca;
ax.XTickLabel = strcat(ax.XTickLabel,char(176));



%% function "TFnormal_211201"
function [fitresult,gof] = TFnormal_211201(bin_centers,BinnedData,weights,start,lower,upper)

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