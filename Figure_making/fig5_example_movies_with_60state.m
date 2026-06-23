%% load files and prepare
clear;clc;close all
load('c230513_03_all_nunchuck_data.mat');
fontsize=15;
linewidth=1;
indices=[636,638,1468,1522,1526,1537,1540,1550,1552,1553,1554,1562];
indices=indices([4,7,8,9,11,12]);

i_subplot=1;
set(gcf,'units','normalized');%for fitting the generated figure to the size of screen
set(gcf,'outerposition',[0 0 0.6 0.6]);
for idx=indices
    %get angles and fit
    bend_angles=abs(data.nnba{idx});
    if isempty(bend_angles)
        bend_angles=abs(data.mba{idx});
    end
    edges=(0:5:180);
    [binned_data]=histcounts(bend_angles,edges);
    bin_centers=edges(1:end-1)+2.5;
    c=5*sum(histcounts(bend_angles,edges));
    weights=1./binned_data;
    weights(weights==Inf)=1;
    %TFnormal1
    start = [c 30 50];
    lower = [c 0 0];
    upper = [c 180 200];
    [fit,gof]=TFnormal_220127(bin_centers,binned_data,weights,start,lower,upper);
    fit.c=fit.c/length(find(~isnan(bend_angles)));
    disp(gof.sse)
    %TFnormal2
    %Order:  c,  m1,  m2,   n,    sigma1   sigma2
    m1=1.5407;
    sigma1=45.7487;
    start =   [c  m1   90  1000  sigma1     40];
    lower =  [c  m1   0       0     sigma1     10];
    upper = [c  m1  180    c     sigma1    100];
    [fit2,gof2] = TFNormal2_210628(bin_centers,binned_data,weights,start,lower,upper);
    fit2.c=fit2.c/length(find(~isnan(bend_angles)));
    fit2.n=fit2.n/length(find(~isnan(bend_angles)));
    n=fit2.n;
    c=5;
    sigma2=fit2.sigma2;
    m2=fit2.m2;
    
    %plot
    subplot(2,3,i_subplot);
    binned = histcounts(bend_angles,edges); 
    bin_counts=binned/sum(binned);
    color=rgb('DodgerBlue');
    histogram('BinEdges',edges,'BinCounts',bin_counts,'FaceColor',color);
    hold on
    err_bar = sqrt(binned)/length(find(~isnan(bend_angles)));
    errorbar([2.5:5:177.5],bin_counts,err_bar,'.','MarkerSize',5,'Color',rgb('Blue'),'LineWidth',1);
    %TFnormal2
    h=plot(fit2);
    set(h,'linewidth',2,'color','r');
    %TFnormal1
    l=plot(fit);
    set(l,'linewidth',2,'color','k');
    l.LineStyle = '--';
    %ground state
    fplot(@(x)...
        ((c-n)/sqrt(2*pi*sigma1^2))*(exp(-(-x-m1)^2/(2*sigma1^2))+exp(-(2*180-x-m1)^2/(2*sigma1^2))...
        +exp(-(x-m1)^2/(2*sigma1^2))+exp(-(-2*180+x-m1)^2/(2*sigma1^2))),...
        [0,180],'b','LineWidth',2);
    %bent state
    fplot(@(x)...
        (n/sqrt(2*pi*sigma2^2))*(exp(-(-x-m2)^2/(2*sigma2^2))+exp(-(2*180-x-m2)^2/(2*sigma2^2))...
        +exp(-(x-m2)^2/(2*sigma2^2))+exp(-(-2*180+x-m2)^2/(2*sigma2^2))),...
        [0,180],'g','LineWidth',2);
    
    legend off
    C2ratio=(fit2.n)/(fit2.c);
    str={strcat("\mu_2: ",num2str(round(fit2.m2,2,'significant')),char(176),"   ","\sigma_2: ",num2str(round(fit2.sigma2,2,'significant')),char(176)),...
        strcat("C_2: ",num2str(round(C2ratio*100,2,'significant')),"%"),...
        strcat("\mu: ",num2str(round(fit.m,2,'significant')),char(176),"   ","\sigma: ",num2str(round(fit.sigma,2,'significant')),char(176))};
    text(0.45,0.75,str,'Units','normalized','FontSize',fontsize,'Interpreter','tex');
    xlim([0,180]);
    xlabel('bend angles');
    ylabel('frequency');
    ax = gca;pause(0.1);
    ax.XTickLabel = strcat(ax.XTickLabel,char(176));
    set(gca,'fontsize',fontsize);
    
    i_subplot=i_subplot+1;
    set(gca,'FontSize',15,'linewidth',1);
end

%% function "TFnormal_220127"
function [fitresult,gof] = TFnormal_220127(bin_centers,BinnedData,weights,start,lower,upper)

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

%% function TFNormal2_210628
function [fitresult,gof,coeffs,conf] = TFNormal2_210628(bin_centers,BinnedData,weights,start,lower,upper)

%prepare the fit
[xData, yData] = prepareCurveData(bin_centers,BinnedData);

%define the fit
ft = fittype('((c-n)/sqrt(2*pi*sigma1^2))*(exp(-(-x-m1)^2/(2*sigma1^2))+exp(-(2*180-x-m1)^2/(2*sigma1^2))+exp(-(x-m1)^2/(2*sigma1^2))+exp(-(-2*180+x-m1)^2/(2*sigma1^2)))+((n)/sqrt(2*pi*sigma2^2))*(exp(-(-x-m2)^2/(2*sigma2^2))+exp(-(2*180-x-m2)^2/(2*sigma2^2))+exp(-(x-m2)^2/(2*sigma2^2))+exp(-(-2*180+x-m2)^2/(2*sigma2^2)))','independent', 'x', 'dependent', 'y' );
opts = fitoptions( 'Method', 'NonlinearLeastSquares','StartPoint',start,'Lower',lower,'Upper',upper,...
    'MaxFunEvals',1000000,'MaxIter',1000000);
opts.Weights = weights;
opts.Display = 'Off';

% Fit model to data
[fitresult,gof] = fit(xData,yData,ft,opts);
coeffs = coeffvalues(fitresult);
conf=confint(fitresult);
end