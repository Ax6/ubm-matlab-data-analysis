classdef LogsManager < handle
    properties
        DEFAULT_DIRECTORY = './Data/log_files/';
        LOG_NAME_SEARCH = '*/mat/*.mat';
        fileList
        fileCount
        randomExtractedIndex = 1;
        randomExtracted;
        selectedLogs = struct('dates',{{}},'locations',{{}},'specialities',{{}},'drivers',{{}},'attempts',{{}});
        selectedVariables = {};
    end
    
    methods
        function this = LogsManager(inputDirectory)
            import Acquisition.*
            import Dataset.*
            directory = this.DEFAULT_DIRECTORY;
            if(exist('inputDirectory', 'var'))
                directory = inputDirectory;
            end
            
            addpath(directory);
            this.fileList = dir(strcat(directory, this.LOG_NAME_SEARCH));
            this.fileCount = length(this.fileList);
            this.generateRandomFileExtraction();
            fprintf('Log manager loaded, found: %i log files ', this.fileCount);
        end
        
        function this = setDates(this, dates)
            this.selectedLogs.dates = dates;
        end
        
        function this = setLocations(this, locations)
            this.selectedLogs.locations = locations;
        end
        
        function this = setSpecialities(this, specialities)
            this.selectedLogs.specialities = specialities;
        end
        
        function this = setDrivers(this, drivers)
            this.selectedLogs.drivers = drivers;
        end
        
        function this = setAttempts(this, attempts)
            this.selectedLogs.attempts = attempts;
        end
        
        function this = setVariables(this, variableNames)
            this.selectedVariables = variableNames;
        end
        
        function dataset = getMergedDataset(this)
            selected = this.getSelectedLogNames();
            originalData = table();
            for i=1:length(selected)
                originalData = [originalData; this.getSelectedData(selected{i})];
            end
            dataset = Dataset(originalData);
        end
        
        function acquisition = getAcquisition(this, name)
            if this.fileExist(name)
                acquisition = Acquisition(name);
            end
        end
        
        function acquisition = getRandomAcquisition(this)
            extracted = this.randomExtracted(this.randomExtractedIndex);
            acquisition = this.getAcquisition(this.getFileName(extracted));
            this.assignNextRandomIndex();
        end
        function data = getSelectedData(this, logName)
            originalData = this.getAcquisition(logName).getDataset().getOriginalData();
            if isempty(this.selectedVariables)
                data = originalData;
            else
                data = originalData(1:end,this.getExistingSelectedVariables(originalData));
            end
        end
        function existingVariables = getExistingSelectedVariables(this, data)
            existingVariables = {};
            for i = 1:length(this.selectedVariables)
                if ismember(this.selectedVariables{i}, data.Properties.VariableNames)
                   existingVariables{end + 1} =  this.selectedVariables{i};
                end
            end
        end
        function selected = getSelectedLogNames(this)
            regex = this.buildSelectionRegexp();
            matches = {};
            for i = 1:this.fileCount
                logName = this.fileList(i).name;                
                if ~isempty(regexp(logName, regex, 'ONCE'))
                    matches{end + 1} = logName; 
                end
            end
            selected = matches;
        end
    end
    
    methods (Access = private)
        function exists = fileExist(this, name)
            matName = strcat(name, '.mat');
            for i = 1:this.fileCount
                loadedName = this.getFileName(i);
                if strcmp(loadedName, name) || strcmp(loadedName, matName)
                    exists = true;
                    return;
                end
            end
            exists = false;
        end
        function name = getFileName(this, fileIndex)
            name = this.fileList(fileIndex).name;
        end
        function this = generateRandomFileExtraction(this)
            this.randomExtracted = randperm(this.fileCount);
        end
        function this = assignNextRandomIndex(this)
            this.randomExtractedIndex = this.randomExtractedIndex + 1;
            if this.randomExtractedIndex > this.fileCount
                this.generateRandomFileExtraction();
                this.randomExtractedIndex = 1;
            end
        end
        function regex = buildSelectionRegexp(this)
            regex = '';
            fields = fieldnames(this.selectedLogs);
            for i=1:numel(fields)
                regex = strcat(regex, this.getSelectionPiece(fields{i}), '_');
            end
            regex(end) = '';
        end
        function regexPiece = getSelectionPiece(this, piece)
            selectorsLength = length(this.selectedLogs.(piece));
            if selectorsLength
               regexPiece = '(';
               for i=1:selectorsLength
                   regexPiece = strcat(regexPiece, this.selectedLogs.(piece){i}, '|');
               end
               regexPiece(end) = ')';
            else
                regexPiece = '.*';
            end
        end
    end
end

