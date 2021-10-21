%% Initialization
clear ; close all; clc

%% ImportData
% ��ʼ��������
filename = '.\Pipeline.csv';
delimiter = ',';
startRow = 2;

% ����������Ϊ�ı���ȡ:
% �й���ϸ��Ϣ������� TEXTSCAN �ĵ���
formatSpec = '%q%q%q%q%q%q%[^\n\r]';

% ���ı��ļ���
fileID = fopen(filename,'r');

% ���ݸ�ʽ��ȡ�����С�
% �õ��û������ɴ˴������õ��ļ��Ľṹ����������ļ����ִ����볢��ͨ�����빤���������ɴ��롣
dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'TextType', 'string', 'HeaderLines' ,startRow-1, 'ReturnOnError', false, 'EndOfLine', '\r\n');

% �ر��ı��ļ���
fclose(fileID);

% ��������ֵ�ı���������ת��Ϊ��ֵ��
% ������ֵ�ı��滻Ϊ NaN��
raw = repmat({''},length(dataArray{1}),length(dataArray)-1);
for col=1:length(dataArray)-1
    raw(1:length(dataArray{col}),col) = mat2cell(dataArray{col}, ones(length(dataArray{col}), 1));
end
numericData = NaN(size(dataArray{1},1),size(dataArray,2));

for col=[1,2,6]
    % ������Ԫ�������е��ı�ת��Ϊ��ֵ���ѽ�����ֵ�ı��滻Ϊ NaN��
    rawData = dataArray{col};
    for row=1:size(rawData, 1)
        % ����������ʽ�Լ�Ⲣɾ������ֵǰ׺�ͺ�׺��
        regexstr = '(?<prefix>.*?)(?<numbers>([-]*(\d+[\,]*)+[\.]{0,1}\d*[eEdD]{0,1}[-+]*\d*[i]{0,1})|([-]*(\d+[\,]*)*[\.]{1,1}\d+[eEdD]{0,1}[-+]*\d*[i]{0,1}))(?<suffix>.*)';
        try
            result = regexp(rawData(row), regexstr, 'names');
            numbers = result.numbers;
            
            % �ڷ�ǧλλ���м�⵽���š�
            invalidThousandsSeparator = false;
            if numbers.contains(',')
                thousandsRegExp = '^\d+?(\,\d{3})*\.{0,1}\d*$';
                if isempty(regexp(numbers, thousandsRegExp, 'once'))
                    numbers = NaN;
                    invalidThousandsSeparator = true;
                end
            end
            % ����ֵ�ı�ת��Ϊ��ֵ��
            if ~invalidThousandsSeparator
                numbers = textscan(char(strrep(numbers, ',', '')), '%f');
                numericData(row, col) = numbers{1};
                raw{row, col} = numbers{1};
            end
        catch
            raw{row, col} = rawData{row};
        end
    end
end


% �����ݲ��Ϊ��ֵ���ַ����С�
rawNumericColumns = raw(:, [1,2,6]);
rawStringColumns = string(raw(:, [3,4,5]));


% ������ֵԪ���滻Ϊ NaN
R = cellfun(@(x) ~isnumeric(x) && ~islogical(x),rawNumericColumns); % ���ҷ���ֵԪ��
rawNumericColumns(R) = {NaN}; % �滻����ֵԪ��

% �����������
PipelineData = raw;
% �����ʱ����
clearvars filename delimiter startRow formatSpec fileID dataArray ans raw col numericData rawData row regexstr result numbers invalidThousandsSeparator thousandsRegExp rawNumericColumns rawStringColumns R;

%% Data preprocessing
DETECT_EQUIP_NO = cell2mat(PipelineData(:,1));
POSITION_NO = cell2mat(PipelineData(:,2));

BARCODE = string(PipelineData(:,3));

LOAD_CURRENT = string(PipelineData(:,4));
PF = string(PipelineData(:,5));

AVE_ERR = cell2mat(PipelineData(:,6));

ITEM_NO = zeros(size(LOAD_CURRENT));
for i = 1:length(LOAD_CURRENT)
    if LOAD_CURRENT(i) == '05' && PF(i) == '01'
        ITEM_NO(i) = 1;
    elseif LOAD_CURRENT(i) == '05' && PF(i) == '07'
        ITEM_NO(i) = 2;
    elseif LOAD_CURRENT(i) == '07' && PF(i) == '07'
        ITEM_NO(i) = 3;
    elseif LOAD_CURRENT(i) == '08' && PF(i) == '01'
        ITEM_NO(i) = 4;
    elseif LOAD_CURRENT(i) == '08' && PF(i) == '07'
        ITEM_NO(i) = 5;
    elseif LOAD_CURRENT(i) == '09' && PF(i) == '01'
        ITEM_NO(i) = 6;
    elseif LOAD_CURRENT(i) == '00' && PF(i) == '01'
        ITEM_NO(i) = 7;
    elseif LOAD_CURRENT(i) == '00' && PF(i) == '07'
        ITEM_NO(i) = 8;
    elseif LOAD_CURRENT(i) == '01' && PF(i) == '01'
        ITEM_NO(i) = 9;
    elseif LOAD_CURRENT(i) == '01' && PF(i) == '07'
        ITEM_NO(i) = 10;  
    else
        ITEM_NO(i) = 0; 
    end
end

%% Data classification

dataset = zeros(20,60,3);
num = zeros(12000,1);

for i = 1:20
    for j = 1:60
        % feature extraction
        a = DETECT_EQUIP_NO == i; 
        b = POSITION_NO == j; 
        for k = 1:10
            c = ITEM_NO == k;
            index = find((a&b&c)==1);
            error = AVE_ERR(index);

            num(((i-1)*60+j-1)*10+k) = length(index);

            mu = mean(error);
            sigma = std(error);
            skew = skewness(error);
            kurt = kurtosis(error);


            dataset(i,j,k) = mu;
            dataset(i,j,k+10) = sigma;
            dataset(i,j,k+20) = skew;
            dataset(i,j,k+30) = kurt;
        end
    end
end

%% Data visualization

% X1 = zeros(60,2);
% X1(:,1) = dataset(1,:,1);
% X1(:,2) = dataset(1,:,2);
% 
% X2 = zeros(60,2);
% X2(:,1) = dataset(2,:,1);
% X2(:,2) = dataset(2,:,2);

X = dataset;
figure;

axis([-0.1 0.1 -0.1 0.1 -0.1 0.1]);
grid;
xlabel('item1 (error%)');
ylabel('item3 (error%)');
zlabel('item4 (error%)');

hold on
palette = hsv(20);

for i = 1:20
    fprintf('Program paused. Press enter to continue.\n');
    pause;
    scatter3(X(i, :, 1), X(i, :, 7), X(i, :, 8), 15, palette(i,:));
    
end



hold off











