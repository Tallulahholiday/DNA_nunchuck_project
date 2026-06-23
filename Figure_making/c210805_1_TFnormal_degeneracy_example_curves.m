clear;clc;close all;
axis_font=20;text_font=20;

p=180;
xlim([0,p]);
hold on
x=[0:0.1:180];

sigma=50;
m=0;
y1=(1/sqrt(2*p*sigma^2))*(exp(-(x-m).^2/(2*sigma^2))+exp(-(-x-m).^2/(2*sigma^2))+...
    exp(-(2*p-x-m).^2/(2*sigma^2))+exp(-(-2*p+x-m).^2/(2*sigma^2)));
sigma=45;
m=20;
% y2=1.103*(exp(-(x-m).^2/(2*sigma^2))+exp(-(-x-m).^2/(2*sigma^2))+exp(-(2*p-x-m).^2/(2*sigma^2))+exp(-(-2*p+x-m).^2/(2*sigma^2)));
y2=(1/sqrt(2*p*sigma^2))*(exp(-(x-m).^2/(2*sigma^2))+exp(-(-x-m).^2/(2*sigma^2))+...
    exp(-(2*p-x-m).^2/(2*sigma^2))+exp(-(-2*p+x-m).^2/(2*sigma^2)));

%add them up to get TFnormal
plot(x,y1,'Color',rgb('Red'),'LineWidth',2);
plot(x,y2,'Color',rgb('Blue'),'LineWidth',2,'LineStyle','--');
xticks([0,90,180]);
xticklabels({strcat('0',char(176)),strcat('90',char(176)),strcat('180',char(176))});
box on;
% ylim([0,2.2]);

xlabel('\theta','FontSize',text_font);
ylabel('TFnormal','FontSize',text_font);
set(gca,'ytick',[]);%do not tick y axis
set(gca, 'FontSize', axis_font);%setting axis font
set(gcf,'units','normalized');%for fitting the generated figure to the size of screen
set(gcf,'outerposition',[0 0 0.55 0.7]);
lgd=legend(strcat('\mu = 0',char(176),', \sigma = 50',char(176)),...
    strcat('\mu = 20',char(176),', \sigma = 45',char(176)),'Location','northeast');
lgd.FontSize = 24;