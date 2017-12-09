classdef Dampers < handle
    %DAMPERS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        dataset;
        frontLeft;
        frontRight;
        rearLeft;
        rearRight;
        filter;
        CALIBRATION_WINDOW = 2000;
        RUN_FILTER_WINDOW = 3000;
        FL_OFFSET = 0;
        FR_OFFSET = 0;
        RL_OFFSET = 0;
        RR_OFFSET = 0;
        FL_FUEL = 0;
        FR_FUEL = 0;
        RL_FUEL = 0;
        RR_FUEL = 0;
    end
    
    methods (Access = public)
        function this = Dampers(dataset)
            %DAMPERS Construct an instance of this class
            %   Detailed explanation goes here
            this.dataset = dataset;
            if(ismember('DamperFL', this.dataset.getData().Properties.VariableNames))
                this.dataset.originalData.DamperFLmm = this.dataset.originalData.DamperFL;
                this.dataset.originalData.DamperFRmm = this.dataset.originalData.DamperFR;
                this.dataset.originalData.DamperRLmm = this.dataset.originalData.DamperRL;
                this.dataset.originalData.DamperRRmm = this.dataset.originalData.DamperRR;
                this.dataset.originalData.DamperFL = [];
                this.dataset.originalData.DamperFR = [];
                this.dataset.originalData.DamperRL = [];
                this.dataset.originalData.DamperRR = [];
            end
            if(ismember('DamperFLmm', this.dataset.getData().Properties.VariableNames))
                this.frontLeft = this.dataset.getOriginalData().DamperFLmm;
                this.frontRight = this.dataset.getOriginalData().DamperFRmm;
                this.rearLeft = this.dataset.getOriginalData().DamperRLmm;
                this.rearRight = this.dataset.getOriginalData().DamperRRmm;
                this.calibrate();
            end
            import IMUFilter.*
            this.filter = IMUFilter();
            this.filter.setType('Median');
        end
        
        function dampers = getAll(this)
            dampers = [this.getFrontLeft(), this.getFrontRight(), ...
                       this.getRearLeft(), this.getRearRight()];
        end
        
        function frontLeft = getFrontLeft(this)
            frontLeft = this.getFiltered(this.getRawFrontLeft()) - this.FL_OFFSET;
        end
        
        function frontRight = getFrontRight(this)
            frontRight = this.getFiltered(this.getRawFrontRight()) - this.FR_OFFSET;
        end
        
        function rearLeft = getRearLeft(this)
            rearLeft = this.getFiltered(this.getRawRearLeft()) - this.RL_OFFSET;
        end
        
        function rearRight = getRearRight(this)
            rearRight = this.getFiltered(this.getRawRearRight()) - this.RR_OFFSET;
        end
        
        function rawFrontLeft = getRawFrontLeft(this)
            data = this.frontLeft + this.FL_FUEL;
            rawFrontLeft = data(this.dataset.getDataRange());
        end
        
        function rawFrontRight = getRawFrontRight(this)
            data = this.frontRight + this.FR_FUEL;
        	rawFrontRight = data(this.dataset.getDataRange());
        end
        
        function rawRearLeft = getRawRearLeft(this)
            data = this.rearLeft + this.RL_FUEL;
            rawRearLeft = data(this.dataset.getDataRange());
        end
        
        function rawRearRight = getRawRearRight(this)
            data = this.rearRight + this.RR_FUEL;
            rawRearRight = data(this.dataset.getDataRange());
        end
        
        function filter = getFilter(this)
            filter = this.filter;
        end
        
        function runInterval = getRunInterval(this)
            i1 = this.getRunIntervalFromData(this.frontLeft);
            i2 = this.getRunIntervalFromData(this.frontRight);
            i3 = this.getRunIntervalFromData(this.rearLeft);
            i4 = this.getRunIntervalFromData(this.rearRight);
            i = [i1, i2, i3, i4];
            runInterval = [min(i), max(i)];
        end
        
        function this = applyFuelCorrection(this)
            this.FL_FUEL = this.getFuelCorrection(this.frontLeft);
            this.FR_FUEL = this.getFuelCorrection(this.frontRight);
            this.RL_FUEL = this.getFuelCorrection(this.rearLeft);
            this.RR_FUEL = this.getFuelCorrection(this.rearRight);
        end
        
        function fuelCorrection = getFuelCorrection(this, data, diffDampPerRPM)
            runInterval = this.getRunIntervalFromData(data);
            rpm = this.dataset.originalData.RPM;
            if ~exist('diffDampPerRPM', 'var')
                diffDampPerRPM = this.getDiffDampPerRPM(data, runInterval);
            end
            dampStartOffset = sum(rpm(1:runInterval(1))) * diffDampPerRPM;
            fuelCorrection = (cumtrapz(rpm) .* diffDampPerRPM) - dampStartOffset;
        end
        
        function diffDampPerRPM = getDiffDampPerRPM(data, runInterval)
            startRange = this.getCalibrationWindow(runInterval(1), true, length(data));
            finishRange = this.getCalibrationWindow(runInterval(2), false, length(data));
            startMed = median(data(startRange));
            finishMed = median(data(finishRange));
            diffDamp = startMed - finishMed;
            rpm = this.dataset.originalData.RPM;
            diffDampPerRPM = diffDamp / sum(rpm(runInterval(1):runInterval(2)))
        end
    end
    
    methods (Access = public)
        function filtered = getFiltered(this, data)
            this.filter.setData(data);
            filtered = this.filter.get(); 
        end
        
        function this = calibrate(this)
            FL_COEFF = 1.6837e-09;
            FR_COEFF = -7.3140e-10;
            RL_COEFF = -1.8736e-09;
            RR_COEFF = 1.0113e-09;
            rpm = this.dataset.originalData.RPM;
   
            %ffl = this.getFuelCorrection(this.frontLeft);
            %ffr = this.getFuelCorrection(this.frontRight);
            %frl = this.getFuelCorrection(this.rearLeft);
            %frr = this.getFuelCorrection(this.rearRight);
            ffl = this.getFuelCorrection(this.rearRight, FL_COEFF);
            ffr = this.getFuelCorrection(this.rearRight, FR_COEFF);
            frl = this.getFuelCorrection(this.rearRight, RL_COEFF);
            frr = this.getFuelCorrection(this.rearRight, RR_COEFF);
            
            this.frontLeft = this.frontLeft + ffl;
            this.frontRight = this.frontRight + ffr;
            this.rearLeft = this.rearLeft + frl;
            this.rearRight = this.rearRight + frr;
            
            this.FL_OFFSET = this.getCalibrationOffset(this.frontLeft);
            this.FR_OFFSET = this.getCalibrationOffset(this.frontRight);
            this.RL_OFFSET = this.getCalibrationOffset(this.rearLeft);
            this.RR_OFFSET = this.getCalibrationOffset(this.rearRight);
            
            this.dataset.originalData.DamperFLmm = this.frontLeft - this.FL_OFFSET;
            this.dataset.originalData.DamperFRmm = this.frontRight - this.FR_OFFSET;
            this.dataset.originalData.DamperRLmm = this.rearLeft - this.RL_OFFSET;
            this.dataset.originalData.DamperRRmm = this.rearRight - this.RR_OFFSET;
        end
        
        function calibrationOffset = getCalibrationOffset(this, data)
            runInterval = this.getRunIntervalFromData(data);
            caliTest = this.caliTest(this.frontLeft', this.frontRight', this.rearLeft', this.rearRight');
            r1 = caliTest(1);
            t = this.dataset.getTimeAxis();
            calibrationWindow = this.getCalibrationWindow(r1, true, length(data));
            calibrationOffset = median(data(calibrationWindow));
        end
        function runInterval = getRunIntervalFromData(this, data)
            runInterval = [1, length(data)];
            runIndexes = this.getRunIndexesFromData(data);
            indexes = runIndexes(1, :);
            selected = [];
            if length(indexes) > 2
                indexes = [indexes(end - 1), indexes(end)];
            end
            for i = 1:length(indexes)
                calWindow = this.getCalibrationWindow(indexes(i), runIndexes(2, i), length(data));
                selected = [selected, calWindow];
            end
            if ~isempty(selected)
                runInterval = [selected(1), selected(end)];
            end
        end
        function runIndexes = getRunIndexesFromData(this, data)
            runWindowTime = this.getRunWindow(data);
            runWindowDeriv = diff(runWindowTime);
            indexes = find(runWindowDeriv);
            runIndexes = [indexes'; (runWindowDeriv(indexes) > 0)'];
        end
        function calibrationWindow = getCalibrationWindow(this, index, isStart, maxIndex)
            if ~exist('maxIndex', 'var')
                maxIndex = index + this.CALIBRATION_WINDOW;
            end
            calibrationWindow = (index + 1):(index + this.CALIBRATION_WINDOW);
            if isStart
                calibrationWindow = (index - this.CALIBRATION_WINDOW):(index - 1);
            end
            calibrationWindow = calibrationWindow(calibrationWindow > 0 & calibrationWindow <= maxIndex);
        end
        function runWindow = getRunWindow(this, data)
            dataDeriv = diff(data.*100);
            dataDeriv(end + 1) = dataDeriv(end);
            dataDeriv = medfilt1(abs(dataDeriv), this.RUN_FILTER_WINDOW);
            %dataDeriv = medfilt1(abs(dataDeriv), this.RUN_FILTER_WINDOW);            
            runWindow = dataDeriv > 0.5;
        end
        
        
        function intervalZone = caliTest (this, d1,d2,d3,d4)
    data = sum([abs(d1); abs(d2); abs(d3); abs(d4)]);
    diffDamp = diff(data.*100);
    diffDamp(end+1) = diffDamp(end);
    absDiffDamp = abs(diffDamp);
    absDiffDampFilt = medfilt1(absDiffDamp, 1000);  
    t = this.dataset.getTimeAxis();
    %plot(t, absDiffDampFilt);
    %hold on
    activeSamples = absDiffDampFilt > 0.5;
    %plot(t(activeSamples), absDiffDampFilt(activeSamples), 'bx');
    %hold on
    diffActive = diff(activeSamples);
    zones = [];
    for a = 1:(length(activeSamples) - 1)
        if diffActive(a) > 0
            zones(:, end + 1) = [0, a, a];
        end
        if activeSamples(a) && activeSamples(a+1)
            zones(1, end) = zones(1, end) + 1;
        end
        if diffActive(a) < 0
            zones(3, end) = a;
        end
    end
    if ~isempty(zones)
        [~, index] = max(zones(1, :));
        largestZone = zones(:, index);
        intervalZone = largestZone(2):largestZone(3);
    else
        intervalZone = 1:length(d1);
    end
end
    end
    
end

