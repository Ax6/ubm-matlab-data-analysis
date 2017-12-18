classdef Brakes
    %BRAKE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = public)
        MEDIAN_WINDOW = 5;
    end
    
    properties (Access = private)
        dataset;
        pFront;
        pRear;
        filter;
    end
    
    methods
        function this = Brakes(dataset)
            %BRAKE Construct an instance of this class
            %   Detailed explanation goes here
            import IMUFilter.*
            this.dataset = dataset;
            this.filter = IMUFilter();
            this.filter.MEDIAN_WINDOW = this.MEDIAN_WINDOW;
            if(ismember('PbrakeFrontBar', this.dataset.getData().Properties.VariableNames))
                this.dataset.VCUResample({'PbrakeFrontBar','PbrakeFrontBar'});
                this.pFront = this.dataset.getData().PbrakeFrontBar;
                this.pRear = this.dataset.getData().PbrakeRearBar;
            end
        end
        
        function frontPressure = getFrontPressure(this)
            frontPressure = this.getFiltered(this.pFront);
        end
        
        function rearPressure = getRearPressure(this)
            rearPressure = this.getFiltered(this.pRear);
        end
    end
    
    methods (Access = private)
        function filtered = getFiltered(this, data)
            this.filter.setData(data);
            filtered = this.filter.getMedian();
        end
    end
end

