%% COMPARE CONTINGENCIES AND IMPULSE RESPONSES ACROSS INTEREST RATE POLICIES
% Parametrization is taken from parameters.m files in Examples

clear;
close all;
clc;

cfg.root = '../../';
addpath([cfg.root 'Source']);
addpath([cfg.root 'Replication/Common']);
addpath('Data');
cfg.path = 'Examples/nyfed';


%% SET PARAMETERS
%               1      2      3     4       5       6          7      8       9       10        11       12            13
cfg.models = {'TTR0','TTRP','ATR','SUP','NGDPT','CumNGDPT','TTRSm1','TTRm1','TTRp1','AIT20','NYFEDrule','HDNGDPTINF','PLT'};
cfg.V       = {'y','pi','R','hat_P','hat_N','yhd','yhdpi'}; % variables to plot
cfg.n_mod   = length(cfg.models);     % number of models
cfg.n_var   = length(cfg.V);          % number of vars to plot
cfg.taumax  = 200;                    % max no. of contingencies
cfg.l2      = 21;                     % max length of regime 2
cfg.cont    = 32;                     % contingency to select
cfg.horizon = 55;                     % time horizon for IRF plots

set(0,'DefaultFigureVisible','off');  % suppress figures


%% INIT CONTAINERS 
R.wl    = zeros(cfg.n_mod,1);            
R.e_zlb = zeros(cfg.n_mod,1);
R.c     = zeros(floor((cfg.taumax+cfg.l2)*1.1),cfg.n_var,cfg.n_mod);
R.v     = zeros(cfg.n_mod,3);
R.i     = zeros(cfg.n_mod,2);
R.irf   = zeros(floor((cfg.taumax+cfg.l2)*1.1),cfg.n_var,cfg.n_mod);


for m = 1:length(cfg.models)
    if strcmp(string(cfg.models(m)),'TTR0') || strcmp(string(cfg.models(m)),'TTRm1') || strcmp(string(cfg.models(m)),'TTRp1')
        run(strcat(cfg.root,cfg.path,'/TTR/do_',string(cfg.models(m)),'.m'));
    elseif strcmp(string(cfg.models(m)),'TTRSm1')
        run(strcat(cfg.root,cfg.path,'/TTRS/do_',string(cfg.models(m)),'.m'));
    elseif strcmp(string(cfg.models(m)),'AIT20') || strcmp(string(cfg.models(m)),'AIT40')
        run(strcat(cfg.root,cfg.path,'/AIT/do_',string(cfg.models(m)),'.m'));
    elseif strcmp(string(cfg.models(m)),'TTRPp') 
        run(strcat(cfg.root,cfg.path,'/TTRP/do_',string(cfg.models(m)),'.m'));
    else
        run(strcat(cfg.root,cfg.path,'/',string(cfg.models(m)),'/do_',string(cfg.models(m)),'.m'));
    end
    
    [R.wl(m), R.e_zlb(m), R.c(:,:,m), R.v(m,:), R.i(m,:), R.irf(:,:,m)] = out(ResM,IR,k,T_tilde,vars,param,cfg.V,cfg.cont,'nyfed');    fprintf(strcat(string(cfg.models(m)),' done\n'))
    clearvars -except R cfg m
end


%% PRINT SUMMARY TABLE
T = [R.wl R.e_zlb R.v R.i];
T = T./T(11,:);
T(11,:) = [R.wl(11) R.e_zlb(11) R.v(11,:) R.i(11,:)];
cfg.mod_lab = {'TTR','TTRP','ATR','SUP','NGDPT','HD-NGDPT','TTRS-1','TTR-1','TTR+1','AIT','FRBNY Rule','SDTR','PLT'};
T = array2table(T,...
    'VariableNames',{'Welfare Loss','E[ZLB]','Vol y','Vol \pi','Vol R','Impact x','Impact \pi'},...
    'RowNames',cfg.mod_lab)


%% PLOT THE 'cont' CONTINGENCY AND THE AVERAGE IRF IN EACH MODEL

% Rescale impulse responses into annual rates, percentage points
N = {'c','irf'};
for i = 1:2
    eval(strcat('R.',string(N(i)),'(:,1,:) = 100*R.',string(N(i)),'(:,1,:);'))  % output gap
    eval(strcat('R.',string(N(i)),'(:,2,:) = 400*R.',string(N(i)),'(:,2,:);'))  % inflation
    eval(strcat('R.',string(N(i)),'(:,3,:) = 400*R.',string(N(i)),'(:,3,:);'))  % nominal interest rate
    eval(strcat('R.',string(N(i)),'(:,4,:) = 100*R.',string(N(i)),'(:,4,:);'))  % price level
    eval(strcat('R.',string(N(i)),'(:,5,:) = 100*R.',string(N(i)),'(:,5,:);'))  % nominal GDP
    eval(strcat('R.',string(N(i)),'(:,6,:) = 100*R.',string(N(i)),'(:,6,:);'))  % cum nominal GDP
    eval(strcat('R.',string(N(i)),'(:,7,:) = 100*R.',string(N(i)),'(:,7,:);'))  % cum nominal GDP
end
clearvars i


%% SETTINGS FOR FIGURES

set(0,'DefaultFigureVisible','on') 

var_labA = {'\hat{Y}','\pi','i'};
var_labB = {'\hat{P}','\hat{N}','\hat{\Gamma}','\hat{D}'};

mod_base  = [11,  3,  4,    6,   12];
col_base  = [13   9   11    5,   7];
line_base = {'-' '-.' ':'  ':'   '-'};

mod_extra  = [2,    7,  1,  8,   10,   9,    5    ,13 ];
col_extra  = [6,   10,  2,  8,   12,   14,   4     3 ];
line_extra = {':' '-.' '--' '-.' '--' '--'  '--'  '-'};


%% ADD STEADY STATE VALUE AS INITIAL ONE (FOR SOME VARIABLES)
n = {'hat_P','hat_N','yhd','yhdpi'}; % variables w/o this correction
nc = zeros(1,length(n));
for i = 1:length(n)
    nc(i) = find(strcmp(cfg.V,n(i))); % find their position
end

for i = 1:2
    eval(strcat('R.',string(N(i)),' = cat(1,R.',string(N(i)),'(end,:,:),R.',string(N(i)),');'))
    eval(strcat('R.',string(N(i)),'(1,nc,:) = 0;'))
end
clearvars i


%% PLOT THE 'cont' CONTINGENCY IN EACH MODEL

PanelA = R.c(:,1:3,mod_base);
PanelB = R.c(:,4:7,mod_base);

% Baseline table, first 3 vars (Panel A)
graph_models(PanelA,cfg.horizon,var_labA,cfg.mod_lab(mod_base),col_base,line_base,'nyfed',1,'startstring','07-03','add_data',1); 

% Baseline table, last 4 vars (Panel B)
graph_models(PanelB,cfg.horizon,var_labB,cfg.mod_lab(mod_base),col_base,line_base,'nyfed',1,'startstring','07-03','add_data',1);  


%-- Group Other Rules (for appendix)
PanelA = R.c(:,1:3,mod_extra);
PanelB = R.c(:,[4:7],mod_extra);

% Other rules table, first 4 vars (Panel A)
graph_models(PanelA,cfg.horizon,var_labA,cfg.mod_lab(mod_extra),col_extra,line_extra,'nyfed',1,'startstring','07-03','add_data',1);

% Other rules table, last 4 vars (Panel B)
graph_models(PanelB,cfg.horizon,var_labB,cfg.mod_lab(mod_extra),col_extra,line_extra,'nyfed',1,'startstring','07-03','add_data',1);    
clear PanelA PanelB

% Group ODP
%-- Group Baseline Rules
PanelA = R.irf(:,1:3,mod_base);
PanelB = R.irf(:,4:7,mod_base);

% Baseline table, first 4 vars (Panel A)
graph_models(PanelA,cfg.horizon,var_labA,cfg.mod_lab(mod_base),col_base,line_base,'nyfed',1,'startstring','07-03','add_data',0); 

% Baseline table, last 4 vars (Panel B)
graph_models(PanelB,cfg.horizon,var_labB,cfg.mod_lab(mod_base),col_base,line_base,'nyfed',1,'startstring','07-03','add_data',0);   

%-- Group Other Rules
PanelA = R.irf(:,1:3,mod_extra);
PanelB = R.irf(:,[4:7],mod_extra);

% Other rules table, first 4 vars (Panel A)
graph_models(PanelA,cfg.horizon,var_labA,cfg.mod_lab(mod_extra),col_extra,line_extra,'nyfed',1,'startstring','07-03','add_data',0); 
% 
% % Other rules table, last 4 vars (Panel B)
graph_models(PanelB,cfg.horizon,var_labB,cfg.mod_lab(mod_extra),col_extra,line_extra,'nyfed',1,'startstring','07-03','add_data',0);     

clearvars -except R cfg T