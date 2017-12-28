classdef Dataset < handle
    %DATASET Summary of this class goes here
    %   Detailed explanation goes here
    properties
        originalData;
        accelerometer;
        gyroscope;
        speed;
        steeringAngle;
        brakes;
        dampers;
        clutch;
        temperatures;
        frontHeight;
        rearHeight;
        rideHeight;
        filter;
        %
        dataInterval = 0;
        F_SAMPLING = 100;
        tStart;
        tEnd;
        VCU_ECU_SYNC_ENABLED = true;
        VCU_ECU_SYNCED = false;
        VCULength;
        ECULength;
        VCUCoeff;
        ECUCoeff;
        VCUTurnOnOffset = 1;
    end
    
    methods (Access = public)
        function this = Dataset(originalData)
            %DATASET Construct an instance of this class
            import IMUFilter.*
            this.originalData = originalData;
            this.ECUVCUSyinc();
            this.tStart = 0;
            this.tEnd = this.getDuration();
            this.generate();
            this.filter = IMUFilter();
            import Speed.*
            this.speed = Speed(this);
            import Dampers.*
            this.dampers = Dampers(this);
        end
        function this = ECUVCUSyinc(this)
            if this.canSyncECUVCU()
                this.genECUVCUSyncCoefficents();
                if ismember('ClutchPosPneum', this.originalData.Properties.VariableNames)
                    this.VCUResample({'ClutchPosPneum'});
                end
                if ismember('Gear', this.originalData.Properties.VariableNames)
                    this.VCUResample({'Gear'});
                    this.originalData.Gear = round(this.originalData.Gear);
                end
                this.VCU_ECU_SYNCED = true;
            end
        end
        function data = getData(this)
            interval = this.dataInterval;
            if ~this.dataInterval
                interval = this.getDataInterval();
            end
            data = this.originalData(interval(1):interval(2),:);
        end
        function data = getOriginalData(this)
            data = this.originalData;
        end
        function f = getSamplingFrequency(this)
            f = this.F_SAMPLING;
        end
        function t = getTimeAxis(this)
            timeInterval = this.getTimeInterval();
            t = 0:1/this.F_SAMPLING:(timeInterval(2) - timeInterval(1));
        end
        function tStart = getStartTime(this)
            tStart = this.tStart;
        end
        
        function setStartTime(this, startTime)
            this.tStart = startTime;
            if this.tStart < 0
                this.tStart = 0;
            end
            this.generate();
        end
        
        function setEndTime(this, endTime)
            this.tEnd = endTime;
            if this.tEnd > this.getDuration()
                this.tEnd = this.getDuration();
            end
            this.generate();
        end
        
        function setStartSamples(this, startSamples)
            this.setStartTime(startSamples / this.F_SAMPLING);
        end
        
        function setEndSamples(this, endSamples)
             this.setEndTime(endSamples ./ this.F_SAMPLING);
        end
        
        function accelerometer = getAccelerometer(this)
            accelerometer = this.accelerometer;
        end
        function gyroscope = getGyroscope(this)
            gyroscope = this.gyroscope;
        end
        function speed = getSpeed(this)
            speed = this.speed.get();
        end
        function steeringAngle = getSteeringAngle(this)
            steeringAngle = this.steeringAngle.get();
        end
        function throttle = getThrottle(this)
            throttle = this.getData().Throttle;
        end
        function brake = getBrakes(this)
            brake = this.brakes;
        end
        function dampers = getDampers(this)
            dampers = this.dampers;
        end
        function clutch = getClutch(this)
            clutch = this.getData().ClutchPosPneum;
        end
        function gears = getGears(this)
            gears = this.getData().Gear;
        end
        function rpm = getRPM(this)
            %rpm = this.getData().RPM;
            this.filter.setType('Median');
            this.filter.setData(this.getData().RPM);
            rpm = this.filter.get();
        end
        function temperatures = getTemperatures(this)
            temperatures = this.temperatures;
        end
        function speed = getRideHeight(this)
            speed = this.rideHeight.get();
        end
        function dataRange = getDataRange(this)
            interval = this.getDataInterval();
            dataRange = interval(1):interval(2);
        end
        function this = VCUResample(this, variables)
            if ~this.VCU_ECU_SYNC_ENABLED || ~this.VCU_ECU_SYNCED
                return
            end
            arrayData = table2array(this.originalData(:,variables));
            resampled = this.getVCUResampled(arrayData);
        	this.originalData(:,variables) = array2table(resampled);
        end
        function resampled = getVCUResampled(this, data)
            if length(data) < this.VCULength + this.VCUTurnOnOffset
                data = [data; zeros(this.VCULength + this.VCUTurnOnOffset - length(data), size(data, 2))];
            end
            data = data(this.VCUTurnOnOffset:(this.VCULength + this.VCUTurnOnOffset),:);
            rightSignal = resample(data, this.ECUCoeff, this.VCUCoeff);
            if length(rightSignal) < this.ECULength
               %Correct in case coefficients proporsion affects array size
               rightSignal(end+1,:) = rightSignal(end,:);
            end
            resampled = rightSignal(1:this.ECULength, :);
        end
    end
    
    methods (Access = private)
        function flag = canSyncECUVCU(this)
           flag = ismember('PbrakeFrontBar', this.originalData.Properties.VariableNames);
        end
        function this = genECUVCUSyncCoefficents(this)
            % We suppose that ECU is time correct. (lol)
            vcuSignal = this.originalData.PbrakeFrontBar;
            dVcuSignal = diff(vcuSignal);
            indexes = find(dVcuSignal < 0);
            shutdown = indexes(end);
            this.VCULength = shutdown;
            this.ECULength = length(vcuSignal);
            this.VCUCoeff = this.VCULength;
            this.ECUCoeff = this.ECULength;
            if this.ECUCoeff * this.VCUCoeff > 2^31 %Maximum working parameters
                this.ECUCoeff = floor(sqrt(2^31 * (this.ECUCoeff / this.VCUCoeff)));
                this.VCUCoeff = floor(2^31 / this.ECUCoeff);
            end
        end
        function dataInterval = getDataInterval(this)
            dataInterval = floor((this.getTimeInterval() .* this.F_SAMPLING) + 1);
        end
        function timeInterval = getTimeInterval(this)
            timeInterval = [this.tStart, this.tEnd];
        end
        function time = getDuration(this)
            time = ((height(this.originalData) - 1) / this.F_SAMPLING);
        end
        function T = structToTable(~, S)
            SNames = fieldnames(S);
            T = table();
            for loopIndex = 1:numel(SNames) 
                T(:,end+1) = table(S.(SNames{loopIndex}));
            end
            T.Properties.VariableNames = SNames;
        end
        function this = generate(this)
            import Accelerometer.*
            import Gyroscope.*
            import SteeringAngle.*
            import Brakes.*
            import RideHeight.*
            this.accelerometer = Accelerometer(this);
            this.gyroscope = Gyroscope(this);
            this.steeringAngle = SteeringAngle(this);
            this.brakes = Brakes(this);
            this.temperatures = Temperatures(this);
            this.rideHeight = RideHeight(this);
        end
    end
end

