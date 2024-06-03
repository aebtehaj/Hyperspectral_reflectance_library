clc; clear; close all;
%%
% Get the full path of the currently running file
currentFilePath = mfilename('fullpath');

% Extract the directory from the full path
currentDirectory = fileparts(fileparts(currentFilePath));

% Netcdf file directory 
directoryPath = fullfile(currentDirectory, 'data_NETCDF');

% Display the result
disp(['Directory of the NETCDF file: ', directoryPath]);

%% load all net cdf files
% Set the current working directory to the script folder
cd(directoryPath);

% List all the NETCDF file 
fileList = dir(fullfile(directoryPath, '*.nc4'));

% sort the netcdf files based on the observation number
observationNumbers = cellfun(@(x) sscanf(x, 'O%d'), {fileList.name});

% Sort the fileList based on observation numbers while maintaining the original order
[~, sortOrder] = sort(observationNumbers);
NetcdfFileList = fileList(sortOrder);

% Display the number of netcdf files
disp(['Number of all netcdf files: ' num2str(numel(NetcdfFileList))]);

%defining three mapping for classification based on polymer types, water background and the combination  
polymerCount = containers.Map({'PET', 'HDPE', 'LDPE', 'PP', 'EPSF', 'Mix', 'Weathered'}, zeros(1, 7));
waterTypeCount = containers.Map({'C', 'T', 'F'}, zeros(1, 3));
combinationCount = containers.Map;

% Iterate through the files and count the polymer occurrences
for i = 1:numel(NetcdfFileList)
    fileName = NetcdfFileList(i).name;    
    % Extract polymer name from the file name
    polymerName = regexp(fileName, '(PET|HDPE|LDPE|EPSF|PP|Mix|Weathered)', 'match', 'once');
    % Update the counter for the corresponding polymer
    if isKey(polymerCount, polymerName)
        polymerCount(polymerName) = polymerCount(polymerName) + 1;
    end
    % Extract water type from the file name based on the first letter after the second underscore
    waterTypeLetter = regexp(fileName, '_[^_]*_([CTF])[^_]*_', 'tokens', 'once');
    % Check if the extraction was successful and update the counter for the corresponding water type
    if isKey(waterTypeCount, waterTypeLetter{1})
        waterTypeCount(waterTypeLetter{1}) = waterTypeCount(waterTypeLetter{1}) + 1;
    end
    % Update the counter for the polymer-water type combination
    combinationKey = [polymerName '_' waterTypeLetter{1}];
    if isKey(combinationCount, combinationKey)
        combinationCount(combinationKey) = combinationCount(combinationKey) + 1;
    else
        combinationCount(combinationKey) = 1;
    end
end

% Display the counts for each polymer in table format
disp('Number of netcdf files for polymer type:');
polymerTypes = {'PET', 'HDPE', 'LDPE', 'PP', 'EPSF', 'Mix', 'Weathered'};
polymerCounts = cellfun(@(polymer) num2str(polymerCount(polymer)), polymerTypes, 'UniformOutput', false);
T = table(polymerTypes', cellfun(@str2double, polymerCounts)', 'VariableNames', {'Polymer', 'Count'});
disp(T);

% Display the counts for each water type in table format
disp('Number of netcdf files for water type:');
waterTypes={'C','T','F'};
waterTypesName = {'Clear', 'Turbid', 'Foamy'};
waterCounts = cellfun(@(water) num2str(waterTypeCount(water)), waterTypes, 'UniformOutput', false);
T1 = table(waterTypesName', cellfun(@str2double, waterCounts)', 'VariableNames', {'WaterType', 'Count'});
disp(T1);

% Initialize a table to store the counts with row names
T2 = table('Size', [7, 3], 'VariableTypes', {'double', 'double', 'double'}, 'VariableNames', {'C', 'T', 'F'}, 'RowNames', {'PET', 'HDPE', 'LDPE', 'EPSF', 'PP', 'Mix', 'Weathered'});

% Loop through all polymer-water type combinations
disp('Number of netcdf files for each polymer-water type combination:');
for polymerKey = {'PET', 'HDPE', 'LDPE', 'EPSF', 'PP', 'Mix', 'Weathered'}
    row = zeros(1, 3);
    for waterTypeKey = {'C', 'T', 'F'}
        combinationKey = [polymerKey{1} '_' waterTypeKey{1}];
        % Check if the combination exists in the map
        if isKey(combinationCount, combinationKey)
            count = combinationCount(combinationKey);
            % Update the corresponding entry in the row vector
            row(strcmp(waterTypeKey, {'C', 'T', 'F'})) = count;
        end
    end
    % Add the row to the table
    T2{polymerKey{1}, :} = row;
end

% Display the table
disp(T2);
%% Open specific netcdf file
%ask the user to input a random number from 1 to 2048 for opening netcdf file
prompt = {'Enter a number (from 1 to 2048) for displaying a spectrum:'};
dlgtitle = 'Observation number';
fieldsize = [1 45];
definput = {'1'};
answer = inputdlg(prompt,dlgtitle,fieldsize,definput);
k=str2num(answer{1});

material=regexp(NetcdfFileList(k).name, '^[^_]*_([^_]+)_', 'tokens', 'once');
background=regexp(NetcdfFileList(k).name, '_[^_]*_([CTF])[^_]*_', 'tokens', 'once');
waterTypeNames = containers.Map({'C', 'T', 'F'}, {'Clear', 'Turbid', 'Foamy'});     

%diplay the file content
disp(['Netcdf file content for file number: ' answer{1}]);
ncid = netcdf.open(NetcdfFileList(k).name, 'NOWRITE');
ncdisp(NetcdfFileList(k).name)
Plasticfraction=ncreadatt(NetcdfFileList(k).name,"/","Plastic fraction(%)");

%Put RGB image and labeled image sidy by side on the top and spectrum on the bottom
I1=ncread(NetcdfFileList(k).name,'RgbImage');
I2=ncread(NetcdfFileList(k).name,'LabeledImage');

figure
set(gcf,'Position',[107,184,1162,728])

%RGB image
subplot(2, 2, 1); imshow(I1); title({'\textbf  {RGB image}'},'FontSize',16,'Interpreter','Latex')

%Labeled images for clear and turbid backgrounds contain two classes, whereas those for a foamy background contain three
if contains(waterTypeNames(background{1}), 'Foamy') ==1
    Foamfraction=ncreadatt(NetcdfFileList(k).name,"/","Foam fraction(%)");
    custom_colormap = [0 0 0;0.5 0.5 0.5; 1 1 1]; % Black for 0 (flow), White for 1 (debris), Grey for 2 (foam)
    subplot(2, 2, 2); imshow(I2, [0 2], 'Colormap', custom_colormap); title({['\textbf  {Labeled image}','\textbf  {, Foam fraction(\%): }',num2str(Foamfraction)]},'FontSize',16,'Interpreter','Latex')   
else  
    %Binary image with flow and debris
    subplot(2, 2, 2); imshow(logical(I2)); title({'\textbf  {Labeled image}'},'FontSize',16,'Interpreter','Latex')
end

%Spectrum
subplot(2,2,[3 4]); 
    plot(350:2500, ncread(NetcdfFileList(k).name,'Reflectacne'),'-','color',[128/255,128/255,128/255],'LineWidth',2.5);
    xlabel('\bf {$\lambda$ [nm]}','FontSize',12,'FontWeight','bold','Interpreter','Latex');
    ylabel('\bf {Relectance}','FontSize',12,'FontWeight','bold','Interpreter','Latex');
    xlim([350 2500])
    set(gca,'fontweight','bold','fontsize',18);
    set(gca,'TickLabelInterpreter','latex');
    set(gca,'TickDir','out');
    grid on
    set(gca, 'LineWidth', 1.2)
    box on
    title({'\textbf  {Spectrum }'},'FontSize',18,'Interpreter','Latex');
sgtitle({['\textbf  {O\#}',answer{1},'\textbf  {, Polymer: }',material{1},'\textbf  {, Background: }',waterTypeNames(background{1}),'\textbf  {, Plastic fraction(\%): }',num2str(Plasticfraction)]},'FontSize',20,'Interpreter','Latex');

% Close the NETCDF file
netcdf.close(ncid);