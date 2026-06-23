%% load file, find movie indices
clear;clc;close all
load('c230512_06_all_nunchuck_data.mat');
load('c220119_4_pulled_NN_test_results.mat');
linker_names={'37PP_nsIHF_MBN','37PP_nsIHF_new','37PP_nsIHF_2023'};
movie_indices=[];
for i=1:length(linker_names)
    movie_indices=[movie_indices,find_in_structure(data.linker,linker_names{i})];
end
movie_indices=setdiff(movie_indices,data.idx_outlier);

%% add delay time
data.delay(movie_indices)=1/9.7;

%% find effective delay time
for idx=movie_indices
    delay=data.delay(idx);
    movie_length=length(find(~isnan(data.nnba{idx})));
    data.effective_length(idx)=round(movie_length*delay);
end

%% for each movie, run 500 simulations based on its mu, sigma and length
bin_edges=(0:5:180);
bin_centers=bin_edges(1:end-1)+2.5;

for idx=movie_indices
    idx
    mu=data.fit{idx}.m;
    sigma=data.fit{idx}.sigma;
    movie_length=data.effective_length(idx);
%     set_idx=find_in_structure(set_data.name,linker);
%     NN=set_data.NN{set_idx};
%     if strcmp(NN,'hand') | strcmp(NN,'NN13')
%         NN_angles=NN_angles_13;
%         real_angles=real_angles_13;
%     elseif strcmp(NN,'NN22')
%         NN_angles=NN_angles_22;
%         real_angles=real_angles_22;
%     elseif strcmp(NN,'NN22_100')
%         NN_angles=NN_angles_22100;
%         real_angles=real_angles_22100;
%     elseif strcmp(NN,'AlexNet_test4_28')
        NN_angles=NN_angles_28;
        real_angles=real_angles_28;
%     end
    
    clear simulation_fits simulation_gofs
    parfor iteration=1:500
        %make TFnormal using mu and sigma
        weights=exp(-(-bin_centers-mu).^2/(2*sigma^2))+exp(-(2*180-bin_centers-mu).^2/(2*sigma^2))+...
            exp(-(bin_centers-mu).^2/(2*sigma^2))+exp(-(-2*180+bin_centers-mu).^2/(2*sigma^2));
        weights=weights/(sum(weights));%normalize
        % draw angles to construct an imaged movie
        drawn_angles=randsample(bin_centers,movie_length,true,weights);
        % do an NN mapping to imitate analysis by NN
        binned_data=histcounts(drawn_angles,bin_edges);
        drawn_NN_angles=[];
        for i_bin=1:size(bin_edges,2)-1
            bin_center=bin_centers(i_bin);
            idx_real_angles=[find(real_angles==bin_center-0.5),find(real_angles==-bin_center+0.5)];
            drawn_NN_angles=[drawn_NN_angles,randsample(NN_angles(idx_real_angles),binned_data(i_bin),true)];
        end
        
        %fit
        binned_data=histcounts(drawn_NN_angles,bin_edges);
        c=5*sum(binned_data);
        start = [c mu sigma];
        lower = [c 0 0];
        upper = [c 180 200];
        fit_weights=1./binned_data;
        fit_weights(fit_weights==Inf)=1;
        [fit,gof]=TFnormal_211201(bin_centers,binned_data,fit_weights,start,lower,upper);
        simulation_fits{iteration}=fit;
        simulation_gofs{iteration}=gof;
    end
    data.simulation_fits{idx}=simulation_fits;
    data.simulation_gofs{idx}=simulation_gofs;
end

save('c230513_01_all_nunchuck_data.mat','data','set_data');

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