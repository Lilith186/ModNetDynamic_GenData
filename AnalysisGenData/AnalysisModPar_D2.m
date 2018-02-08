%% Statistical analysis of the 'SimpAdEx' model parameters for D2
% This worksheet contains all code and further explanations to perform statistical
% analyses of the model parameters for D2

%% Loading and processing data
% We load the data containing all parameters

load('EverythingInOneFile34.mat');

%%
% For the subsequent analyses, we only need some of the information.
% Therefore, we generate a new data structure / data array:

pharma = reshape(pharma,[690 1]);
type = reshape(type,[690 1]);
LoV = ["genotype","age2","cell_type2","layer","species","pharma","type"];

for i=1:690
    for j=1:size(LoV,2)
        if eval("~isa(" + LoV(j) + "{" + i + ",1},'char')")
            eval(LoV(j) + "{" + i + ",1}='unknown';")
        end
    end
end

Data{:,1} = genotype;
Data{:,2} = age2;
Data{:,3} = cell_type2;
Data{:,4} = layer;
Data{:,5} = species;
Data{:,6} = pharma;
Data{:,7} = type;
Data{:,8} = C;         
Data{:,9} = gL;
Data{:,10} = tau;
Data{:,11} = EL;
Data{:,12} = sf;
Data{:,13} = Vth;
Data{:,14} = Vr;
Data{:,15} = Vup;
Data{:,16} = tcw;
Data{:,17} = b;

%% 
% Create new data frame that contains D2-data only

Data_cont = Data(:,[2:5,8:17]);
Data_cont = cellfun(@(x) x(ind_D2_control), Data_cont, 'UniformOutput', false);
Data_agon = Data(:,[2:5,8:17]);
Data_agon = cellfun(@(x) x(ind_D2_agonist), Data_agon, 'UniformOutput', false);
ColNam = ["age","cell_type","layer","species","C","gL","tau","EL","sf","Vth","Vr","Vup","tcw","b"];

%%
% In a first step we look at the number of data points with respect to
% specific conditions (age, cell type, layer, species)

N_cont = size(Data_cont{1,1},1);
disp(['The control data set contains ' num2str(N_cont) ' data points'])
class_age_cont = unique(Data_cont{1,1});
disp(['The following age categories are present for control: ' strjoin(class_age_cont,', ')])
N1 = sum(cellfun(@isempty,strfind(Data_cont{1,1},'old')));
disp([num2str(N1) ' data points belong to the category "old"'])
class_celltype_cont = unique(Data_cont{1,2});
disp(['The following cell types are present for control: ' strjoin(class_celltype_cont,', ')])
class_layer_cont = unique(Data_cont{1,3});
disp(['The following layers are present for control: ', strjoin(class_layer_cont,', ')])
class_species_cont = unique(Data_cont{1,4});
disp(['The recordings come from the follwoing species: ', strjoin(class_species_cont,', ')])
disp([' '])
N_agon = size(Data_agon{1,1},1);
disp(['The agonist data set contains ' num2str(N_agon) ' data points'])
class_age_agon = unique(Data_agon{1,1});
disp(['The following age categories are present for agonist: ' strjoin(class_age_agon,', ')])
N2 = sum(cellfun(@isempty,strfind(Data_agon{1,1},'old')));
disp([num2str(N2) ' data points belong to the category "old"'])
class_celltype_agon = unique(Data_agon{1,2});
disp(['The following cell types are present for agonist: ' strjoin(class_celltype_agon,', ')])
class_layer_agon = unique(Data_agon{1,3});
disp(['The following layers are present for control: ' strjoin(class_layer_agon,', ')])
class_species_agon = unique(Data_agon{1,4});
disp(['The recordings come from the follwoing species: ' strjoin(class_species_agon,', ')])

%% Analysis of the entire D2 data set by pooling over young and old animals
% We pool data from 'old' and 'young' animals together (as the number of data points is quite small) and
% generate the model parameter histograms to eyeball the sample
% distributions and to get a first impression of differences between
% control and agonist.

figure()
for i=1:10
    subplot(2,5,i)
    EMin = min([Data_cont{1,4+i},Data_agon{1,4+i}]);
    EMax = max([Data_cont{1,4+i},Data_agon{1,4+i}]);
    edges = linspace(EMin,EMax,6);
    histogram(Data_cont{1,4+i},edges,'FaceColor','b','Normalization','pdf')
    hold on;
    histogram(Data_agon{1,4+i},edges,'FaceColor','r','Normalization','pdf')
    [f1,x1] = ksdensity(Data_cont{1,4+i});
    [f2,x2] = ksdensity(Data_agon{1,4+i});
    plot(x1,f1,'b','LineWidth',2)
    plot(x2,f2,'r','LineWidth',2)
    title(ColNam(4+i))
    xlim([EMin,EMax])
end
set(gcf,'units','centimeters','position',[1,1,25,15])
snapnow, close

%% 
% By eyeball inspection, most distributions seem to be nonnormal. Also, the
% distributions of control and agonist conditions look quite alike. We cannot
% expect hugh differences in mean, median or standard deviation. This can
% also be seen in a boxplot summary:

figure()
for i=1:10
    subplot(2,5,i)
    Val = [Data_cont{1,4+i},Data_agon{1,4+i}];
    Label = [ones(1,length(Data_cont{1,4+i})),2*ones(1,length(Data_agon{1,4+i}))];
    boxplot(Val,Label,'Labels',{'control','agonist'},'Whisker',10)%,'Notch','on')hold on
    hold on;
    plot([mean(Val(Label==1)),mean(Val(Label==2))], 'xr')
    title(ColNam(4+i))
end
set(gcf,'units','centimeters','position',[1,1,25,15])
snapnow, close

%% 
% Finally, we need to check if the mean and variance of the control and agonist
% distributions are significantly different. We do so by running a
% two-sample t-test (in case the distributions are halfway normal) and a
% Wilcoxon rank sum test (for non-normal distributions) for the mean, and
% a Bartlett�s, Brown-Forsythe and Levene�s test for the variance.

H_mean_t = zeros(1,10);
H_mean_rank = zeros(1,10);
H_var_brown = zeros(1,10);
H_var_levene = zeros(1,10);
H_var_bart = zeros(1,10);
for i=1:10
    x = Data_cont{1,4+i};
    y = Data_agon{1,4+i};
    % Check mean ...
    [h,~,ci,~] = ttest2(x,y,'VarType','unequal'); 
    H_mean_t(i) = h;
    [~,h] = ranksum(x,y);
    H_mean_rank(i) = h;
    % Check variance ...
    [p,~] = vartestn([x,y]',[zeros(1,length(x)),ones(1,length(y))]','TestType','BrownForsythe','Display','off');
    if p<0.05
        H_var_brown(i) = 1;
    end
    [p,~] = vartestn([x,y]',[zeros(1,length(x)),ones(1,length(y))]','TestType','LeveneQuadratic','Display','off');
    if p<0.05
        H_var_levene(i) = 1;
    end
    [p,~] = vartestn([x,y]',[zeros(1,length(x)),ones(1,length(y))]','TestType','Bartlett','Display','off');
    if p<0.05
        H_var_bart(i) = 1;
    end
end

id1 = find(H_mean_t==1);
id2 = find(H_mean_rank==1);

if (isempty(id1) && isempty(id2))
    disp('No mean is significantly different')
else
    for i=1:length(id1)
        disp(join(['According to a two-sample t-test, the mean of the' ColNam(4+id1(i)) 'distribution is significantly different between control and agonist']))
    end
    for i=1:length(id2)
        disp(join(['According to a Wilcoxon rank sum test, the mean of the' ColNam(4+id2(i)) 'distribution is significantly different between control and agonist']))
    end
end

id1 = find(H_var_bart==1);
id2 = find(H_var_brown==1);
id3 = find(H_var_levene==1);

if (isempty(id1) && isempty(id2))
    disp('No varaince is significantly different')
else
    for i=1:length(id1)
        disp(join(['According to a Bartlett�s test, the variance of the' ColNam(4+id1(i)) 'distribution is significantly different between control and agonist']))
    end
    for i=1:length(id2)
        disp(join(['According to a Brown-Forsythe test, the variance of the' ColNam(4+id2(i)) 'distribution is significantly different between control and agonist']))
    end
    for i=1:length(id3)
        disp(join(['According to a Levene�s test, the variance of the' ColNam(4+id3(i)) 'distribution is significantly different between control and agonist']))
    end
end

%%
% As some of the parameters are not independent, and in general the
% distribution can be regarded as multivariate, we perform a MANOVA test
% (under the probably wrong assumptions that the data comes from a n-dim
% normal distribution). As we have two groups (control and agonist),
% MANOVA is equivalent and the test reduces to Hotelling's T-square.

x = []; y = [];
for i=[1,2,4,5,6,7,9,10]
    x = [x Data_cont{1,4+i}'];
    y = [y Data_agon{1,4+i}'];   
end

z = [x;y];
group = [zeros(1,length(x)),ones(1,length(y))];
[~,p,~] = manova1(z,group);
[~,P] = HotellingsT2(x,y,0.05,0);

if (p<0.05 && P<0.05)
    disp("According to the MANOVA/Hotellings T2 test, the vector sample means are significantly different.")
elseif (p>=0.05 && P<0.05)
    disp("According to the MANOVA test, the vector of means of control and agonist conditions are not significantly different.")
elseif (p<0.05 && P>=0.05)
    disp("According to the Hotellings T2 test, the vector of means of control and agonist conditions are not significantly different.")
else
    disp("According to the MANOVA/Hotellings T2 test, the vector of means of control and agonist conditions are not significantly different.")
end

%% Pairwise analysis of D2 by equalizing the number of data points
% Actually, the control-agonist experiment were paired. Consequently, a
% paired t-test and Wilcoxon signed rank test should be used to investigate
% further the differences in mean and median, respectively. Therefore, we
% need to equalize the number of observations.

[in_all,ia,ib] = intersect(cell_index_fit(ind_D2_control),cell_index_fit(ind_D2_agonist));
ind_control=ind_D2_control(ia);
ind_agonist=ind_D2_agonist(ib);

Data_cont = Data(:,[2:5,8:17]);
Data_cont = cellfun(@(x) x(ind_control), Data_cont, 'UniformOutput', false);
Data_agon = Data(:,[2:5,8:17]);
Data_agon = cellfun(@(x) x(ind_agonist), Data_agon, 'UniformOutput', false);
%isequal(filename(ind_control),filename(ind_agonist))

%%
% We plot the histograms again

figure()
for i=1:10
    subplot(2,5,i)
    EMin = min([Data_cont{1,4+i},Data_agon{1,4+i}]);
    EMax = max([Data_cont{1,4+i},Data_agon{1,4+i}]);
    edges = linspace(EMin,EMax,10);
    histogram(Data_cont{1,4+i},edges,'FaceColor','b','Normalization','pdf')
    hold on;
    histogram(Data_agon{1,4+i},edges,'FaceColor','r','Normalization','pdf')
    [f1,x1] = ksdensity(Data_cont{1,4+i});
    [f2,x2] = ksdensity(Data_agon{1,4+i});
    plot(x1,f1,'b','LineWidth',2)
    plot(x2,f2,'r','LineWidth',2)
    title(ColNam(4+i))
    xlim([EMin,EMax])
end
set(gcf,'units','centimeters','position',[1,1,25,15])
snapnow; close

%%
% and summarize the statistics in a boxplot

figure()
for i=1:10
    subplot(2,5,i)
    Val = [Data_cont{1,4+i},Data_agon{1,4+i}];
    Label = [ones(1,length(Data_cont{1,4+i})),2*ones(1,length(Data_agon{1,4+i}))];
    boxplot(Val,Label,'Labels',{'control','agonist'},'Whisker',10)%,'Notch','on')hold on
    hold on;
    for j=1:length(ind_control)
        plot([1,2],[Data_cont{1,4+i}(j),Data_agon{1,4+i}(j)],'ro-','MarkerFaceColor',[1,0.5,0.5])
    end
    %plot([mean(Val(Label==1)),mean(Val(Label==2))], 'xr')
    title(ColNam(4+i))
end
set(gcf,'units','centimeters','position',[1,1,25,15])
snapnow; close;

%%
% Now, we can repeat the hypothesis testing and check for significance

H_mean_t = zeros(1,10);
H_mean_rank = zeros(1,10);
H_var_brown = zeros(1,10);
H_var_levene = zeros(1,10);
H_var_bart = zeros(1,10);
for i=1:10
    x = Data_cont{1,4+i};
    y = Data_agon{1,4+i};
    % Check mean ...
    [h,~,ci,~] = ttest(x,y); 
    H_mean_t(i) = h;
    [~,h] = signrank(x,y);
    H_mean_rank(i) = h;
    % Check variance ...
    [p,~] = vartestn([x,y]',[zeros(1,length(x)),ones(1,length(y))]','TestType','BrownForsythe','Display','off');
    if p<0.05
        H_var_brown(i) = 1;
    end
    [p,~] = vartestn([x,y]',[zeros(1,length(x)),ones(1,length(y))]','TestType','LeveneQuadratic','Display','off');
    if p<0.05
        H_var_levene(i) = 1;
    end
    [p,~] = vartestn([x,y]',[zeros(1,length(x)),ones(1,length(y))]','TestType','Bartlett','Display','off');
    if p<0.05
        H_var_bart(i) = 1;
    end
end

id1 = find(H_mean_t==1);
id2 = find(H_mean_rank==1);

if (isempty(id1) && isempty(id2))
    disp('No mean is significantly different')
else
    for i=1:length(id1)
        disp(join(['According to a paired t-test, the mean of the' ColNam(4+id1(i)) 'distribution is significantly different between control and agonist']))
    end
    for i=1:length(id2)
        disp(join(['According to a Wilcoxon signed rank test, the mean of the' ColNam(4+id2(i)) 'distribution is significantly different between control and agonist']))
    end
end

id1 = find(H_var_bart==1);
id2 = find(H_var_brown==1);
id3 = find(H_var_levene==1);

if (isempty(id1) && isempty(id2))
    disp('No varaince is significantly different')
else
    for i=1:length(id1)
        disp(join(['According to a Bartlett�s test, the variance of the' ColNam(4+id1(i)) 'distribution is significantly different between control and agonist']))
    end
    for i=1:length(id2)
        disp(join(['According to a Brown-Forsythe test, the variance of the' ColNam(4+id2(i)) 'distribution is significantly different between control and agonist']))
    end
    for i=1:length(id3)
        disp(join(['According to a Levene�s test, the variance of the' ColNam(4+id3(i)) 'distribution is significantly different between control and agonist']))
    end
end

%%
% Finally we perform a multivariate paired Hotellings T2 test to check if the mean between control and
% agonist sample distributions is significantly different.

x = []; y = [];
for i=[1,2,4,5,6,7,9,10]
    x = [x Data_cont{1,4+i}'];
    y = [y Data_agon{1,4+i}'];
end

[~,P] = HotellingsT2(x,y,0.05,1);

if P<0.05
    disp("According to the paired Hotellings T2 test, the vector sample means are significantly different.")  
else
    disp("According to the paired Hotellings T2 test, the vector of means of control and agonist conditions are not significantly different.")
end
