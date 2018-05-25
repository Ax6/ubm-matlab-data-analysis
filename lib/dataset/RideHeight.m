classdef RideHeight < handle
    %HEIGHT
    %   height data
    
    properties (Access = public)
        dataset;
        frontLeft;
        frontRight;
        rearLeft;
        rearRight;
        filter;
        DEFAULT_FILTER = 'Median';
        MEDIAN_WINDOW = 150;
    end
    
    methods (Access = public)
        function this = RideHeight(dataset)
            %HEIGHT Construct an instance of this class
            import SwissFilter.*
            this.filter = SwissFilter();
            this.filter.setType(this.DEFAULT_FILTER);
            this.filter.MEDIAN_WINDOW = this.MEDIAN_WINDOW;
            this.dataset = dataset;
            if(ismember('FLHeightmm', this.dataset.getData().Properties.VariableNames))
                this.frontLeft = this.dataset.getData().FLHeightmm;
                this.frontRight = this.dataset.getData().FRHeightmm;
                this.rearLeft = this.dataset.getData().RLHeightmm;
                this.rearRight = this.dataset.getData().RRHeightmm;
            end
        end
        function rideHeight = get(this)
            rideHeight = this.getFrontMax();
        end
        function rideHeight = getFrontMax(this)
            rideHeight = max([this.frontLeft';this.frontRight']);
        end
        function rideHeight = getFrontMin(this)
            rideHeight = min([this.frontLeft';this.frontRight']);
        end
        function rideHeight = getFrontAverage(this)
            rideHeight = mean([this.frontLeft';this.frontRight']);
        end
        function rideHeight = getFrontRight(this)
            rideHeight = this.getFiltered(this.frontRight);
        end
        function rideHeight = getRearRight(this)
            rideHeight = this.getFiltered(this.rearRight);
        end
        function rideHeight = getRearLeft(this)
            rideHeight = this.getFiltered(this.rearLeft);
        end
    end
    
    methods (Access = private)
        function filtered = getFiltered(this, data)
            this.filter.setData(data);
            filtered = this.filter.get(); 
        end
    end
end

