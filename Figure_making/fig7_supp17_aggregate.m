%% load files and prepare
clear;clc;close all
% load('c220510_00_all_nunchuck_data.mat');
load('c230513_03_all_nunchuck_data.mat')
linker_names={'37PP0At','37PP0At_LS','37PP0At_newSEs','37PP0At_noT_new','37PP0n0At',...
    '37PP1n0At','37PP0At_cont_study','37PP0At_long_movies','37PP0At_fresh','37PP0At_1week','37PP0At_1week_0.2ul_MBN'};

% find indices to all movies, excluding outliers
movie_indices=[];
for i=1:length(linker_names)
    movie_indices=[movie_indices,find_in_structure(data.linker,linker_names{i})];
end
% 37PP0At
% movie_indices = [635,  637,  645,  653, 1467, 1474, 1487, 1514, 1518,1520, 1521,...
%        1524, 1525, 1526, 1527, 1532, 1533, 1535, 1536, 1538, 1539, 1542,...
%        1545, 1549, 1551, 1552, 1553, 1554, 1561,... % 37nsIHF starts after
%        1248, 1249, 1251, 1258, 1259, 1260, 1938, 1941, 1945, 1947, 1952,...
%        1954, 1955, 1963, 1965, 1967, 1968, 1973, 1976, 1978, 1982, 1983,...
%        1987, 1990, 1994]+1;

% 37alt
movie_indices = [
       1248, 1249, 1251, 1258, 1259, 1260, 1938, 1941, 1945, 1947, 1952,...
       1954, 1955, 1963, 1965, 1967, 1968, 1973, 1976, 1978, 1982, 1983,...
       1987, 1990, 1994]+1;

%% get bend angles and fit
N_FRAMES_MAX = 3000;
all_angles = [];
n_truncated = 0;
for idx = movie_indices
    bend_angles = abs(data.nnba{idx});
    if isempty(bend_angles)
        bend_angles = abs(data.mba{idx});
    end
    % Keep only the first 3000 frames
    if length(bend_angles) > N_FRAMES_MAX
        bend_angles = bend_angles(1:N_FRAMES_MAX);
        n_truncated = n_truncated + 1;
    end
    all_angles = [all_angles, bend_angles];
end
clear bend_angles
fprintf('%d / %d movies truncated to %d frames\n', ...
        n_truncated, length(movie_indices), N_FRAMES_MAX);

bend_angles = all_angles;

edges=(0:5:180);
[binned_data]=histcounts(bend_angles,edges);
bin_centers=edges(1:end-1)+2.5;
c=5*sum(histcounts(bend_angles,edges));
weights=1./binned_data;
weights(weights==Inf)=1;
norm=sum(binned_data);

% perform TFnormal2 fit
%Order:  c,  m1,  m2,   n,    sigma1   sigma2
m1=0;
sigma1=46;
start =   [c  m1   90  1000  sigma1     40];
lower =   [c  m1   0      0  sigma1     10];
upper =   [c  m1  180     c/2  sigma1    100];
[fit2,gof2] = TFNormal2_210628(bin_centers,binned_data,weights,start,lower,upper);

fit2.c=fit2.c/norm;
fit2.n=fit2.n/norm;
sigma2=fit2.sigma2;
m2=fit2.m2;

% TFnormal2 bootstrapping (looser filter: c2 ~= 0.5 only)
[std_mu2,std_sigma2,std_C1,std_C2,mean_mu2,mean_sigma2,...
    mean_C1,mean_C2,mu2_boot,sigma2_boot,C1_boot,C2_boot,r2,n_accepted]=...
    bootstrap_TFnormal2_220323(bend_angles,gof2.rsquare,500,m1,sigma1);

fprintf('Bootstrap: %d / 500 iterations accepted\n', n_accepted);

%% derived quantities for display
c2_fit     = fit2.n / fit2.c;                          % bent fraction from main fit
ratio_boot = C2_boot ./ (C1_boot + C2_boot);           % per-iteration bent fraction
std_c2     = std(ratio_boot, 'omitnan');               % correct: respects C1<->C2 correlation
mean_c2_boot = mean(ratio_boot, 'omitnan');            % sanity check vs c2_fit

fprintf('c2 (main fit)        = %.4f\n', c2_fit);
fprintf('c2 (bootstrap mean)  = %.4f\n', mean_c2_boot);
fprintf('c2 std (bootstrap)   = %.4f\n', std_c2);

%% plot
binned=histcounts(bend_angles,edges);
bin_counts=binned/sum(binned);

histogram('BinEdges',edges,'BinCounts',bin_counts,'FaceColor','#D3D3D3');
hold on
err_bar = sqrt(binned)/length(find(~isnan(bend_angles)));
errorbar([2.5:5:177.5],bin_counts,err_bar,'.','MarkerSize',5,'Color',[0.4 0.4 0.4],'LineWidth',1,'CapSize',12);

h=plot(fit2);
set(h,'linewidth',6,'color','r');
% ground state
fplot(@(x)...
    ((fit2.c-fit2.n)/sqrt(2*pi*sigma1^2))*(exp(-(-x-m1)^2/(2*sigma1^2))+exp(-(2*180-x-m1)^2/(2*sigma1^2))...
    +exp(-(x-m1)^2/(2*sigma1^2))+exp(-(-2*180+x-m1)^2/(2*sigma1^2))),...
    [0,180],'Color',[0 0.447 0.741],'LineWidth',6);
% bent state
fplot(@(x)...
    (fit2.n/sqrt(2*pi*sigma2^2))*(exp(-(-x-m2)^2/(2*sigma2^2))+exp(-(2*180-x-m2)^2/(2*sigma2^2))...
    +exp(-(x-m2)^2/(2*sigma2^2))+exp(-(-2*180+x-m2)^2/(2*sigma2^2))),...
    [0,180],'Color',[0.929 0.694 0.125],'LineWidth',6);

legend off

% ── Display: C2 from main fit, uncertainty from bootstrap ─────────────────────
str = {strcat("\mu_2: ", num2str(round(fit2.m2,2,'significant')), ...
              "\pm", num2str(round(std_mu2,0,'decimals')), char(176)), ...
       strcat("\sigma_2: ", num2str(round(fit2.sigma2,2,'significant')), ...
              "\pm", num2str(round(std_sigma2,0,'decimals')), char(176)), ...
       strcat("C_2: ", num2str(round(c2_fit,2,'significant')), ...
              "\pm", num2str(round(std_c2,2,'decimals'))), ...
       strcat(num2str(norm), ' Frames')};
text(0.45,0.65,str,'Units','normalized','FontSize',36,'Interpreter','tex');

xlim([0,180]);
ylim([0,0.1]);
ax = gca;
ax.XTickLabel = strcat(ax.XTickLabel,char(176));
xlabel('bend angle');
ylabel('frequency');
set(gca,'fontsize',40);
pbaspect([1.3 1 1]);

set(gcf,'units','normalized');
set(gcf,'outerposition',[0.1 0.1 0.15 0.28]);
set(gca, 'XTick', 0:50:150, 'XTickLabel', {'0°', '50°', '100°', '150°'}, ...
    'XLim', [0 180], 'YLim', [0 0.1], 'YTick', 0:0.02:0.1, ...
    'TickDir', 'in', 'Box', 'on', ...
    'XColor', 'k', 'YColor', 'k');

set(gcf, 'Color', 'w')
ax = gca;
ax.Title.String = '';

%% function "bootstrap_TFnormal2_220323"
function [std_mu2,std_sigma2,std_C1,std_C2,mean_mu2,mean_sigma2,...
    mean_C1,mean_C2,mu2_boot,sigma2_boot,C1_boot,C2_boot,r2,n_accepted]=...
    bootstrap_TFnormal2_220323(angle_data,r_cutoff,iterations,m1,sigma1) 

sample_size = length(angle_data);
mu2_boot    = nan(1, iterations);
sigma2_boot = nan(1, iterations);
C1_boot     = nan(1, iterations);
C2_boot     = nan(1, iterations);
r2          = nan(1, iterations);
accepted    = false(1, iterations);

parfor bootrun=1:iterations
    sample=randsample(angle_data,sample_size,true);
    edges=(0:5:180);
    [binned_data]=histcounts(sample,edges);
    bin_centers=edges(1:end-1)+2.5;
    c=5*sum(histcounts(sample,edges));
    weights=1./binned_data;
    weights(weights==Inf)=1;

    %            c   m1   m2          n      sigma1   sigma2
    start =   [  c   m1   rand*180    1000   sigma1   rand*90+10];
    lower =   [  c   m1   0           0      sigma1   10        ];
    upper =   [  c   m1   180         c/2      sigma1   100       ];
    [fit_this_run,gof_this_run] = TFNormal2_210628(bin_centers,binned_data,weights,start,lower,upper);

    % Loosened acceptance: only reject degenerate c2 ≈ 0.5
    c2_this = fit_this_run.n / fit_this_run.c;
    if abs(c2_this - 0.5) > 1e-3 && gof_this_run.rsquare > r_cutoff-0.05 && c2_this > 0.03
        mu2_boot(bootrun)    = fit_this_run.m2;
        sigma2_boot(bootrun) = fit_this_run.sigma2;
        C1_boot(bootrun)     = fit_this_run.c - fit_this_run.n;
        C2_boot(bootrun)     = fit_this_run.n;
        r2(bootrun)          = gof_this_run.rsquare;
        accepted(bootrun)    = true;
    end
end

mean_mu2    = mean(mu2_boot,'omitnan');
mean_sigma2 = mean(sigma2_boot,'omitnan');
mean_C1     = mean(C1_boot,'omitnan');
mean_C2     = mean(C2_boot,'omitnan');
std_mu2     = std(mu2_boot,'omitnan');
std_sigma2  = std(sigma2_boot,'omitnan');
std_C1      = std(C1_boot,'omitnan');
std_C2      = std(C2_boot,'omitnan');
n_accepted  = sum(accepted);
end

%% function TFNormal_custom_weights_210509
function [fitresult,gof,coeffs,conf] = TFNormal_custom_weights_210509(bin_centers,BinnedData,weights,start,lower,upper)

[xData, yData] = prepareCurveData(bin_centers,BinnedData);

ft = fittype('(c/sqrt(2*pi*sigma^2))*(exp(-(-x-m)^2/(2*sigma^2))+exp(-(2*180-x-m)^2/(2*sigma^2))+exp(-(x-m)^2/(2*sigma^2))+exp(-(-2*180+x-m)^2/(2*sigma^2)))','independent', 'x', 'dependent', 'y' );
opts = fitoptions( 'Method', 'NonlinearLeastSquares','StartPoint' ,start,'Lower' ,lower, 'Upper', upper,...
    'MaxFunEvals',1000000,'MaxIter',1000000);
opts.Weights = weights;
opts.Display = 'Off';

[fitresult, gof] = fit( xData, yData, ft, opts );
coeffs = coeffvalues(fitresult);
conf=confint(fitresult);
end

%% function TFNormal2_210628
function [fitresult,gof,coeffs,conf] = TFNormal2_210628(bin_centers,BinnedData,weights,start,lower,upper)

[xData, yData] = prepareCurveData(bin_centers,BinnedData);

ft = fittype('((c-n)/sqrt(2*pi*sigma1^2))*(exp(-(-x-m1)^2/(2*sigma1^2))+exp(-(2*180-x-m1)^2/(2*sigma1^2))+exp(-(x-m1)^2/(2*sigma1^2))+exp(-(-2*180+x-m1)^2/(2*sigma1^2)))+((n)/sqrt(2*pi*sigma2^2))*(exp(-(-x-m2)^2/(2*sigma2^2))+exp(-(2*180-x-m2)^2/(2*sigma2^2))+exp(-(x-m2)^2/(2*sigma2^2))+exp(-(-2*180+x-m2)^2/(2*sigma2^2)))','independent', 'x', 'dependent', 'y' );
opts = fitoptions( 'Method', 'NonlinearLeastSquares','StartPoint',start,'Lower',lower,'Upper',upper,...
    'MaxFunEvals',1000000,'MaxIter',1000000);
opts.Weights = weights;
opts.Display = 'Off';

[fitresult,gof] = fit(xData,yData,ft,opts);
coeffs = coeffvalues(fitresult);
conf=confint(fitresult);
end