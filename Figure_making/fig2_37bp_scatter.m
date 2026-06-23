%% load files for paper 2, find movie indices
clear;clc;close all
all_linker_names_comb={'37bp_0At'};
% load('c220330_02_all_nunchuck_data.mat');
load('c230513_03_all_nunchuck_data.mat')
%% complete data to full length
fields=fieldnames(data);
len2=length(data.name);
markersize=70;

for i=1:length(fields)
    len1=length(getfield(data,fields{i}));
    if len1<len2
        try
            eval(strcat('data.',fields{i},'(len1+1:len2)=cell(1,',num2str(len2-len1),');'));
        catch
            eval(strcat('data.',fields{i},'(len1+1:len2)=zeros(1,',num2str(len2-len1),');'));
        end
    end
end

low1=24.1;high1=39.9;%95% CI for TFnormal fit with 32 DOF (2 bins removed)
for idx=1:1834
    gof=data.gof{idx};
    if gof.sse<low1 | gof.sse>high1
        data.TFnormal1_no_good(idx)=1;
    else
        data.TFnormal1_no_good(idx)=0;
    end
end

%% make scatter plot for each linker
num_small_mu=0;num_large_mu=0;
for i=1:length(all_linker_names_comb)
    if i==1
        set(gcf,'units','normalized');%for fitting the generated figure to the size of screen
        set(gcf,'outerposition',[0.1 0.1 0.25 0.4]);
    end
    linker_name=all_linker_names_comb{i};
    indices=find_in_structure(data.linker_name_combined,linker_name);
    indices=indices(data.TFnormal1_no_good(indices)==0);%look at only movies that were fit well by TFnormal1
    
    mus_small=[];sigmas_small=[];mus_large=[];sigmas_large=[];mus_def_small=[];sigmas_def_small=[];
    for idx=indices
        if ~isempty(data.simulation_mu{idx})%we still need to do this filtering step because TFnormal2-fitted movies were never tested for whether "TFnormal1_no_good", and these movies were still not simulated
            %now we are only dealing with movies for which we are less than 68% sure that TFnormal1 is a bad model
            zero_mu_count=sum((data.simulation_mu{idx}<10));
            if zero_mu_count>500*0.68
                mus_def_small=[mus_def_small,data.fit{idx}.m];
                sigmas_def_small=[sigmas_def_small,data.fit{idx}.sigma];
                num_small_mu=num_small_mu+1;
            elseif zero_mu_count>25 % this is using 95% CI
                mus_small=[mus_small,data.fit{idx}.m];
                sigmas_small=[sigmas_small,data.fit{idx}.sigma];
                num_small_mu=num_small_mu+1;
            else
                mus_large=[mus_large,data.fit{idx}.m];
                sigmas_large=[sigmas_large,data.fit{idx}.sigma];
                num_large_mu=num_large_mu+1;
            end
        end
    end
    scatter(mus_small,sigmas_small,markersize,'o','MarkerEdgeColor',rgb('Blue'),'MarkerFaceColor','none');
    hold on
%     scatter(mus_def_small,sigmas_def_small,markersize,'o','MarkerEdgeColor',rgb('Blue'),'MarkerFaceColor','none');
%     scatter(mus_large,sigmas_large,markersize,'o','MarkerEdgeColor',rgb('Blue'),'MarkerFaceColor','none');
    scatter(mus_def_small,sigmas_def_small,markersize,'o','MarkerEdgeColor',rgb('Blue'),'MarkerFaceColor',rgb('LightSkyBlue'));
    scatter(mus_large,sigmas_large,markersize,'v','MarkerEdgeColor',rgb('Crimson'),'MarkerFaceColor',rgb('Pink'));
    xlim([0,80]);
    ylim([0,80]);
    box on
    ax = gca;pause(0.2);
%     title('37 bp');
    set(gca,'fontsize',14);
    ax.XTickLabel = strcat(ax.XTickLabel,char(176));
    ax.YTickLabel = strcat(ax.YTickLabel,char(176));
    pause(0.1);
    xlabel('mean bend angle \mu');
    ylabel('std bend angle \sigma');
end