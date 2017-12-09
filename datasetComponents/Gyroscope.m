classdef Gyroscope < handle
    %GYROSCOPE
    %   Gyroscope data
    
    properties (Access = public)
        dataset;
        filter;
        X;
        Y;
        Z;
        OFFSET_X;
        OFFSET_Y;
        OFFSET_Z;
    end
    
    methods (Access = public)
        function this = Gyroscope(dataset)
            %GYROSCOPE Construct an instance of this class
            import IMUFilter.*
            this.dataset = dataset;
            this.filter = IMUFilter();
            this.filter.setType('Median');
            if(ismember('GyroXrad', this.dataset.getData().Properties.VariableNames))
                this.X = this.dataset.getData().GyroXrad;
                this.Y = this.dataset.getData().GyroYrad;
                this.Z = this.dataset.getData().GyroZrad;
                this.calibrate();
            end
        end
        function filter = getFilter(this)
            filter = this.filter;
        end
        function dataX = getX(this)
            dataX = -this.getFiltered(this.X) - this.OFFSET_X;
        end
        function dataY = getY(this)
            dataY = this.getFiltered(this.Z) - this.OFFSET_Z;
        end
        function dataZ = getZ(this)
            dataZ = this.getFiltered(this.Y) - this.OFFSET_Y;
        end
        function dataYaw = getYaw(this)
            dataYaw = this.getZ();
        end
    end
    methods (Access = private)
        function filtered = getFiltered(this, data)
            this.filter.setData(data);
            filtered = this.filter.get();
        end
        
        function this = calibrate(this)
            originalData = this.dataset.getOriginalData();
            this.OFFSET_X = median(originalData.GyroXrad(originalData.AccXg < 0.05));
            this.OFFSET_Y = median(originalData.GyroYrad(originalData.AccYg < 0.05));
            this.OFFSET_Z = median(originalData.GyroZrad(originalData.AccZg < 0.05));
        end
    end
end

