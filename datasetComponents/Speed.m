classdef Speed < handle
    %SPEED
    %   Speed data
    
    properties (Access = public)
        dataset;
        frontLeft;
        frontRight;
        rearLeft;
        rearRight;
        filter;
    end
    
    methods (Access = public)
        function this = Speed(dataset)
            %SPEED Construct an instance of this class
            import IMUFilter.*
            this.filter = IMUFilter();
            this.filter.setType('Median');
            this.filter.MEDIAN_WINDOW = 11;
            
            this.dataset = dataset;
            if(ismember('SpeedFLKmh', this.dataset.getData().Properties.VariableNames))
                this.frontLeft = this.dataset.getData().SpeedFLKmh;
                this.frontRight = this.dataset.getData().SpeedFRKmh;
                this.rearLeft = this.dataset.getData().SpeedRLKmh;
                this.rearRight = this.dataset.getData().SpeedRRKmh;
            end
        end
        function rawSpeed = getRaw(this)
            rawSpeed = [this.frontLeft, this.frontRight, this.rearLeft, this.rearRight];
        end
        function frontLeft = getFrontLeft(this)
            frontLeft = this.getFiltered(this.frontLeft, 1, 1);
        end
        function frontRight = getFrontRight(this)
            frontRight = this.getFiltered(this.frontRight, 0, 1);
        end
        function rearLeft = getRearLeft(this)
            rearLeft = this.getFiltered(this.rearLeft, 1, 0);
        end
        function rearRight = getRearRight(this)
            rearRight = this.getFiltered(this.rearRight, 0, 0);
        end
        function rawFrontLeft = getRawFrontLeft(this)
            rawFrontLeft = this.frontLeft(this.dataset.getDataRange());
        end
        
        function rawFrontRight = getRawFrontRight(this)
        	rawFrontRight = this.frontRight(this.dataset.getDataRange());
        end
        
        function rawRearLeft = getRawRearLeft(this)
            rawRearLeft = this.rearLeft(this.dataset.getDataRange());
        end
        
        function rawRearRight = getRawRearRight(this)
            rawRearRight = this.rearRight(this.dataset.getDataRange());
        end
        function speed = get(this)
            speed = this.getFrontAverage();
        end
        function speed = getFrontAverage(this)
            speed = mean([this.getFrontRight()';this.getFrontLeft()'])';
        end
        function speed = getRearAverage(this)
            speed = mean([this.getRearRight()';this.getRearLeft()'])';
        end
        function filter = getFilter(this)
            filter = this.filter;
        end
    end
    methods (Access = private)
        function filtData = getFiltered(this, data, isLeft, isFront)
            filtered = this.removeOutliers(data);
            workingIntervals = this.getWorkingIntervals(filtered);
            calcLeft = this.calcOnWheelOpposite(isLeft, isFront);
            filtered(workingIntervals == 0) = calcLeft(workingIntervals == 0);
            filtData = medfilt1(filtered, 11);
        end
        function data = removeOutliers(~, data)
           data = filloutliers(data, 'linear', 'movmedian', 50); 
        end
        function workingIntervals = getWorkingIntervals(~, data)
            deriv = diff(data);
            deriv(1+end) = deriv(end);
            workingIntervals = (medfilt1(abs(deriv), 33) > 0);
        end
        function speed = calcOnWheelOpposite(this, oppositeIsRight, inputIsFront)
            gyroYaw = this.dataset.getGyroscope().getZ() ./ 10;
            if oppositeIsRight
                gyroYaw = -gyroYaw;
                if inputIsFront
                    data = this.removeOutliers(this.getRawFrontLeft());
                else
                    data = this.removeOutliers(this.getRawFrontRight());
                end
            else
                if inputIsFront
                    data = this.removeOutliers(this.getRawRearLeft());
                else
                    data = this.removeOutliers(this.getRawRearRight());
                end
            end
            speed = data + gyroYaw;
        end
    end
end
