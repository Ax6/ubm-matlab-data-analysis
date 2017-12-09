classdef Accelerometer < handle
    %ACCELEROMETER
    %   Accelerometer data
    
    properties (Access = private)
        dataset;
        filter;
        X;
        Y;
        Z;
        filterType = 'Sgolay';
    end
    
    methods (Access = public)
        function this = Accelerometer(dataset)
            %ACCELEROMETER Construct an instance of this class
            import IMUFilter.*
            this.dataset = dataset;
            this.filter = IMUFilter();
            this.filter.setType(this.filterType);
            if(ismember('AccXg', this.dataset.getData().Properties.VariableNames))
                this.X = this.dataset.getData().AccXg;
                this.Y = this.dataset.getData().AccYg;
                this.Z = this.dataset.getData().AccZg;
            end
        end
        function roll = getRoll(this)
            roll = this.getY();
        end
        function yaw = getYaw(this)
            yaw = this.getZ();
        end
        function pitch = getPitch(this)
            pitch = this.getX();
        end
        function dataX = getX(this)
            %dataX = this.getFiltered(this.X);
            dataX = -this.getFiltered(this.X);
        end
        function dataY = getY(this)
            %dataY = this.getFiltered(this.Y);
            dataY = this.getFiltered(this.Z);
        end
        function dataZ = getZ(this)
            %dataZ = this.getFiltered(this.Z);
            dataZ = this.getFiltered(this.Y);
        end
        function filter = getFilter(this)
            filter = this.filter;
        end
    end
    methods (Access = private)
        function filtered = getFiltered(this, data)
            this.filter.setData(data);
            filtered = this.filter.get();
        end
    end
end

