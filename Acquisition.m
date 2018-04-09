classdef Acquisition < handle

    properties (Access = private)
        dataset,
        instantFinder,
        name
    end
    
    properties (Access = public)
        START_WITH_CAR_OFFSET = 5; %seconds
    end
    
    methods (Access = public)
        function this = Acquisition(fileName, log_source)
            if ~exist('log_source', 'var')
                log_source = this.LOG_SOURCE_DEFAULT;
            end
            this.name = fileName;
            import Dataset.*
            this.dataset = Dataset(this.loadData(log_source));
            import InstantFinder.*
            this.instantFinder = InstantFinder(this.dataset);
        end
        
        function name = getName(this)
            name = this.name;
        end
        
        function dataset = getDataset(this)
           dataset = this.dataset;
        end
        
        function instantFinder = getInstantFinder(this)
            instantFinder = this.instantFinder;
        end
        
        function this = setRunTimeWindow(this)
            runInterval = this.dataset.getDampers().getRunInterval();
            this.dataset.setStartSamples(runInterval(1));
            this.dataset.setEndSamples(runInterval(2));
        end
        
        function this = setStartWithCar(this)
            this.dataset.setStartTime(this.getStartTime() - this.START_WITH_CAR_OFFSET);
        end
        
        function startTime = getStartTime(this, optionalStartIndex)
            if ~exist('optionalStartIndex', 'var')
                optionalStartIndex = 1;
            end
            starts = this.instantFinder.getStart();
            startTime = starts(optionalStartIndex) / this.dataset.getSamplingFrequency();
        end
    end
    
    methods (Access = private)
        function loadedData = loadData(this, log_source)
            import LogsManager.*
            if log_source == LogsManager.LOG_SOURCE_DEFAULT
                loadedData = this.loadDefault();
            elseif log_source == LogsManager.LOG_SOURCE_INCA
                loadedData = this.loadInca();
            else
                throw(MException('Acquisition:invalidSource', 'Log source not valid'));
            end
        end

        function data = loadDefault(this)
            raw_data = load(this.name);
            data = raw_data.ECU;
        end

        function data = loadInca(this)
            incaFiles = this.readIncaFiles();
            biggest = 0;
            for i=1:length(incaFiles)
                if(incaFiles{i}.Samples > biggest)
                    table = incaFiles{i};
                    biggest = incaFiles{i}.Samples;
                end
            end

            %for i=1:length(incaFiles)
            %    file = incaFiles{i};
            %    if(file.Samples < biggest)
            %        data = file.Data;
            %        for c=1:length(data)
            %        incaFiles{i}.Time
            %    end
            %end
            
            data = table.Data;
        end

        function incaFiles = readIncaFiles(this)
            i = 1;
            tableList = {};
            fileName = this.genIncaName(i);
            while (exist(fileName, 'file') == 2)
                fileText = fileread(fileName);

                tokens = regexp(fileText, 'Group_[0-9]+=\s\[\s*((\s|.)*)\];', 'tokens');
                groupText = strrep(tokens{1}{1}, ';', '');
                dataMatrix = strread(groupText);

                tokens = regexp(fileText, '(\S+)\s*=\s*([0-9]+)\s*;', 'tokens');

                T = table;

                for p = 2:length(tokens)
                    varName = strrep(tokens{p}{1}, 'qiXCPqj1', '');
                    T{:, varName} = dataMatrix(:,str2num(tokens{p}{2}));
                end

                tableList{i} = {};
                tableList{i}.Name = fileName;
                tableList{i}.Samples = str2num(tokens{1}{2});
                tableList{i}.Data = T;

                i = i + 1;
                fileName = this.genIncaName(i);
            end
            incaFiles = tableList;
        end

        function name = genIncaName(this, i)
            name = strcat(this.name, '_', int2str(i), '.m');
        end
    end
end

