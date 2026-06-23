%% load files for paper 2, find movie indices
clear;clc;close all
first_two_linker_names_comb={'37bp_0At'};
load('c230513_03_all_nunchuck_data.mat');
fontsize=15;

%% find all movies that don't fit well to TFnormal1
low1=24.1;high1=39.9;%68% CI for TFnormal fit with 32 DOF (2 bins removed)
for idx=1:length(data.name)
    gof=data.gof{idx};
    if gof.sse<low1 | gof.sse>high1
        data.TFnormal1_no_good(idx)=1;
    else
        data.TFnormal1_no_good(idx)=0;
    end
end

%%
for i=1:2
    if i==1
        linker_name=first_two_linker_names_comb{i};
        indices=find_in_structure(data.linker_name_combined,linker_name);
        indices=indices(data.TFnormal1_no_good(indices)==0);%look at only movies that were fit well by TFnormal1
        
        % get angles
        aggregate_angles=[];
        num_movies=0;% count nunchucks that pass the small-mu threshold
        for idx=indices
            if ~isempty(data.simulation_mu{idx})
                mus=data.simulation_mu{idx};
                zero_mu_count=sum((mus<10));
                angles=data.nnba{idx};
                bin_edges=[0:5:180];
                bin_centers=bin_edges(1:end-1)+2.5;
                if isempty(angles)
                    angles=data.mba{idx};
                end
                if zero_mu_count>0.68*500
                    num_movies=num_movies+1;
                    if data.delay(idx)==0.5
                        aggregate_angles=[aggregate_angles,abs(angles(1:2:end))];
                    elseif data.delay(idx)<0.2
                        aggregate_angles=[aggregate_angles,abs(angles(1:10:end))];
                    else
                        aggregate_angles=[aggregate_angles,abs(angles)];
                    end
                end
            end
        end
        
    elseif i==2
        linker_names={'37PP_nsIHF_MBN','37PP_nsIHF_new','37PP_nsIHF_2023'};
        indices=[];
        for j=1:length(linker_names)
            indices=[indices,find_in_structure(data.linker,linker_names{j})];
        end
        indices=setdiff(indices,data.idx_outlier);
        indices=indices(data.TFnormal1_no_good(indices)==0);
        
        aggregate_angles=[];
        num_movies=0;% count nunchucks that pass the small-mu threshold
        for idx=indices
            if ~isempty(data.simulation_mu{idx})
                mus=data.simulation_mu{idx};
                zero_mu_count=sum((mus<10));
                angles=data.nnba{idx};
                bin_edges=[0:5:180];
                bin_centers=bin_edges(1:end-1)+2.5;
                if isempty(angles)
                    angles=data.mba{idx};
                end
                if zero_mu_count>0.68*500
                    num_movies=num_movies+1;
                    aggregate_angles=[aggregate_angles,abs(angles(2:10:end))];
                end
            end
        end
    end
    
    % perform fit
    binned_data=histcounts(aggregate_angles,bin_edges);
    c=5*sum(binned_data);
    %     start = [c 30 50];
    start = [c 0 50];
    lower = [c 0 0];
    upper = [c 180 200];
    fit_weights=1./binned_data;
    fit_weights(fit_weights==Inf)=1;
    [fit,gof]=TFnormal_220127(bin_centers,binned_data,fit_weights,start,lower,upper);
    disp(fit);

    % bootstrap to get the uncertainty (std) on mu and sigma
    iterations=500;
    [std_sigma,mean_sigma_boot,std_mu,mean_mu_boot]=bootstrap_220207(aggregate_angles,gof.rsquare,iterations);

    % plot
    subplot(2,2,i);
    binned = histcounts(aggregate_angles,bin_edges);
    bin_counts=binned/sum(binned);
    histogram('BinEdges',bin_edges,'BinCounts',bin_counts,'FaceColor',rgb('CornFlowerBlue'));
    hold on
    err_bar = sqrt(binned)/length(find(~isnan(aggregate_angles)));
    errorbar([2.5:5:177.5],bin_counts,err_bar,'.','MarkerSize',5,'Color',rgb('Blue'),'LineWidth',1);
    xlim([0,180]);
    fit_to_plot=fit;
    fit_to_plot.c=fit_to_plot.c/length(find(~isnan(aggregate_angles)));
    h=plot(fit_to_plot,'r');
    set(h,'linewidth',2);
    
    % central values = fit to the ORIGINAL aggregate data (fit.m, fit.sigma)
    % uncertainties    = std across the bootstrap iterations (std_mu, std_sigma)
    str={strcat("# frames: "+sum(~isnan(aggregate_angles))),...
        strcat("# nunchucks: ",num2str(num_movies)),...
        strcat("\mu: ",num2str(round(fit.m,0,'decimals')),"\pm",num2str(round(std_mu,1,'significant')),char(176)),...
        strcat("\sigma: ",num2str(round(fit.sigma,2,'significant')),"\pm",num2str(round(std_sigma,1,'significant')),char(176))};
    text(0.38,0.67,str,'Units','normalized','FontSize',15,'Interpreter','tex');
    
    legend off
    xlabel('bend angle');
    ylabel('frequency');
    set(gca,'fontsize',fontsize);
    set(gcf,'units','normalized');
    set(gcf,'outerposition',[0.2 0.1 0.35 0.55]);
    ax = gca;
    ax.XTickLabel = strcat(ax.XTickLabel,char(176));
    ylim([0,max(bin_counts)*1.2]);
    if i==1
        title('37 bp','interpreter','none');
    elseif i==2
        title('37 bp control','interpreter','none');
    end
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

%% function "bootstrap_220207"
function [std_sigma,mean_sigma,std_mu,mean_mu]=bootstrap_220207(angle_data,r_cutoff,iterations)
for bootrun=1:iterations
    sample=randsample(angle_data,length(angle_data),true);%"true" means with replacement
    edges=(0:5:180);
    centers=edges(1:end-1)+2.5;
    c=5*sum(histcounts(sample,edges));
    counts=histcounts(sample,edges);
    
    %error and weights
    weights=1./counts;%weight for a bin with N counts is = N
    weights(weights==Inf)=1;
    
    start = [c 0 50];
    lower = [c 0 0];
    upper = [c 180 200];% sigma upper bound = 200 to match the main fit in this script
    [fitresult,gof] = TFnormal_220127(centers,counts,weights,start,lower,upper);
    
    if gof.rsquare>r_cutoff-0.05
        sigma_boot(bootrun) = fitresult.sigma;
        mu_boot(bootrun) = fitresult.m;
    else
        sigma_boot(bootrun) = nan;
        mu_boot(bootrun) = nan;
    end
end
mean_sigma = nanmean(sigma_boot);
std_sigma = nanstd(sigma_boot);
mean_mu = nanmean(mu_boot);
std_mu = nanstd(mu_boot);
end