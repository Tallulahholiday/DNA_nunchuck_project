clear;clc;close all;
load('c230513_03_all_nunchuck_data.mat');
all_linker_names=...
    {'27bp_0At',...
    '37bp_0At',...
    '37bp_0At_ligated',...
    '37bp_0At_ligated + MBN',...
    '37bp_nsIHF',...
    '47bp_0At',...
    '58bp_0At',...
    '58bp_0At + rFB',...
    '58bp_0At_ligated + MBN'};
col=4;row=6;%number of subplots

%% determine whether a movie is fit to TFnormal1
low1=24.1;high1=39.9;%68% CI for TFnormal fit with 32 DOF (2 bins removed)
for idx=1:length(data.name)
    gof=data.gof{idx};
    if gof.sse<low1 | gof.sse>high1
        data.TFnormal1_no_good(idx)=1;
    else
        data.TFnormal1_no_good(idx)=0;
    end
end

%% plot
output_dir = '/Users/ruiyao/Desktop/Nunchuck Analysis/figures/';

for i_linker = 1:length(all_linker_names)
    linker_name = all_linker_names{i_linker};
    [movie_indices] = find_in_structure(data.linker_paper2, linker_name);
    idx_TFnormal_no = movie_indices(find(data.TFnormal1_no_good(movie_indices) == 1));
    idx_TFnormal_yes = setdiff(movie_indices, idx_TFnormal_no);

    num_figure = 1;

    % Create figure with fixed pixel size (not normalized)
    fig = figure('Units','pixels','Position',[50 50 1800 1000],'Color','w');
    % NOTE: do NOT set 'Visible','off' — getframe needs a visible figure
    for i_movies_total = 1:length(movie_indices)
        idx = movie_indices(i_movies_total);
        edges = (0:5:180);
        angles = abs(data.nnba{idx});
        if isempty(angles)
            angles = abs(data.mba{idx});
        end
        [binned_data] = histcounts(angles, edges);
        bin_center = edges(1:end-1) + 2.5;
        y_uncertainty = sqrt(binned_data);

        subplot_idx = i_movies_total - col * row * (num_figure - 1);
        subplot(col, row, subplot_idx);

        axis_font = 10; text_font = 10;

        if ismember(idx, idx_TFnormal_yes)
            face_color = [1, 0.7, 0.7];
        elseif ismember(idx, idx_TFnormal_no)
            face_color = rgb('LightGreen');
        end

        histogram(angles, edges, 'FaceColor', face_color);
        hold on;
        errorbar(bin_center, binned_data, y_uncertainty, '.', ...
            'MarkerSize', 5, 'Color', rgb('Grey'), 'LineWidth', 1);

        % plot fit
        % plot fit — replace plot(fit) entirely
        if ismember(idx, idx_TFnormal_yes)
            fitobj = data.fit{idx};
            x_fit = linspace(0, 180, 200);
            y_fit = feval(fitobj, x_fit);
            plot(x_fit, y_fit, 'LineWidth', 1.5, 'Color', rgb('Red'));
            str = sprintf('\\mu: %d%s\n\\sigma: %d%s', ...
                round(fitobj.m), char(176), round(fitobj.sigma), char(176));
            text(0.95, 0.95, str, ...
                'Units', 'normalized', ...
                'FontSize', text_font, ...
                'Color', rgb('Crimson'), ...
                'VerticalAlignment', 'top', ...
                'HorizontalAlignment', 'right');
        end

        ylabel('frames', 'FontSize', axis_font);
        xlabel('bend angle', 'FontSize', axis_font);
        xlim([0, 180]);
        ylim([0, max(binned_data) * 1.3]);  % extra headroom for text
        set(gca, 'FontSize', axis_font);
        ax = gca;
        ax.XTickLabel = strcat(ax.XTickLabel, char(176));

        if mod(i_movies_total, col*row) == 0 || i_movies_total == length(movie_indices)
            drawnow;  % force MATLAB to finish rendering
            frame = getframe(fig);
            plot_name = strcat(linker_name,' histograms, fig'," ",num2str(num_figure),'.png');
            imwrite(frame.cdata, fullfile(output_dir, plot_name));
            close(fig);
            num_figure = num_figure + 1;

            if i_movies_total < length(movie_indices)
                fig = figure('Units','pixels','Position',[50 50 1800 1000],'Color','w');
            end
        end
    end
end