classdef SteeringAngle
    %STEERINGANGLE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = public)
        OFFSET = 0;%-47.9;
    end
    
    properties (Access = private)
        dataset;
        filter; 
    end
    
    methods
        function this = SteeringAngle(dataset)
            %STEERINGANGLE Construct an instance of this class
            this.dataset = dataset;
            this.dataset.VCUResample({'SteeringAngle'});
            import IMUFilter.*
            this.filter = IMUFilter();
        end
        
        function steeringAngle = get(this)
            this.filter.setData(this.dataset.getData().SteeringAngle);
            steeringAngle = this.getFiltered();
        end
    end
    
    methods (Access = private)
        function filtered = getFiltered(this)
            filtered = this.filter.getMedian() + this.OFFSET;
        end
    end
end

