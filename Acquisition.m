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
        function this = Acquisition(fileName)
            this.name = fileName;
            loadedData = load(fileName);
            import Dataset.*
            this.dataset = Dataset(loadedData.ECU);
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

    end
end

