classdef InstantFinder < handle
    %STARTFINDER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = private)
        dataset;
        PEAK_PROMINENCE = 0.5;
        ACC_PEAK_SCALE_COEFF = 150;
        START_FINDER_WINDOW = 0.4; %Seconds
        VALUE_AROUND_POINT_WINDOW = 3; %Seconds
        ZERO_ACCELERATION_TOLERANCE = 0.1; %g
        ZERO_SPEED_TOLERANCE = 3; %km/h
        F_SAMPLING;
        ACCELERATION_DISTANCE = 75;
        filter;
    end
    
    methods (Access = public)
        function this = InstantFinder(dataset)
            import SwissFilter.*
            this.dataset = dataset;
            this.F_SAMPLING = dataset.getSamplingFrequency();
            this.filter = SwissFilter();
        end
        
        function start = getStart(this)
            possibleStarts = this.getPossibleStarts();
            if length(possibleStarts) > 1
                start = this.filterStarts(possibleStarts);
            else
                start = (possibleStarts);
            end
            if isempty(start)
                start = (1);
            end
        end
        
        function possibleStarts = getPossibleStarts(this)
            peaks = this.getStartPeaks();
            possibleStarts = this.evaluatePossibleStarts(peaks);
        end
        
        function movingStart = getMovingStart(this)
            startSample = this.getStart();
            speed = this.dataset.getSpeed();
            forward = find((speed(startSample:end)) > 0);
            movingStart = forward(1) + startSample;
        end
        
        function accelerationTime = getAccelerationTime(this)
            movingStart = this.getMovingStart();
            accelerationEnd = this.getAccelerationEnd();
            accelerationTime = (accelerationEnd - movingStart) / this.dataset.F_SAMPLING;
        end
        
        function accelerationEnd = getAccelerationEnd(this)
            startSample = this.getStart();
            speed = this.dataset.getSpeed();
            usefulSamples = speed(startSample:end);
            space = cumtrapz(usefulSamples ./ (3.6 * this.dataset.F_SAMPLING));
            endSample = find(space > this.ACCELERATION_DISTANCE);
            accelerationEnd = endSample(1) + startSample;           
        end
        
    end
    
    methods (Access = private)
         function peaks = getStartPeaks(this)
            peaks = this.getPeaks(this.getScaledForPeaksClutch());
            clutchPeaks = peaks{2}; %Negative peaks
            peaks = this.getPeaks(this.getScaledForPeaksAcceleration());
            accPeaks = peaks{1};%Positive peaks
            peaks = {clutchPeaks, accPeaks};
        end
        function possibleStarts = evaluatePossibleStarts(this, peaks)
            halfWindow = this.START_FINDER_WINDOW * this.F_SAMPLING / 2;
            evaluations = peaks{1} > (peaks{2} - halfWindow)' & peaks{1} < (peaks{2} + halfWindow)';
            accPeaks = peaks{2};
            peaksMatch = accPeaks(sum(evaluations, 1) > 0);
            possibleStarts = peaksMatch([halfWindow*2, diff(peaksMatch)'] >= halfWindow*2); %Remove too close matches
        end
        
        function start = filterStarts(this, possibleStarts)
            v = this.getValuesAround(possibleStarts, -this.dataset.getAccelerometer().getPitch());
            s = this.getValuesAround(possibleStarts, this.dataset.getSpeed());
            selector1 = v(:,1) < this.ZERO_ACCELERATION_TOLERANCE & v(:,1) > -this.ZERO_ACCELERATION_TOLERANCE;
            selector2 = s(:,1) < this.ZERO_SPEED_TOLERANCE & s(:,1) > -this.ZERO_SPEED_TOLERANCE;
            startFromZeroStarts = selector1 & selector2;
            v = v(startFromZeroStarts,:);
            possibleStarts = possibleStarts(startFromZeroStarts);
            start = possibleStarts;
            %start = possibleStarts(accDeltas > max(accDeltas)/sqrt(2));
        end
        
        function values = getValuesAround(this, instants, data)
            halfWindow = this.VALUE_AROUND_POINT_WINDOW * this.F_SAMPLING / 2;
            %Add half window before and after, avoiding negative and
            %exceeding indexing
            data = [zeros(halfWindow, 1)', data', zeros(halfWindow, 1)'];
            instants = instants + halfWindow; %Shift instants
            afterWindow = repmat(instants, 1, halfWindow) + repmat(1:1:halfWindow, length(instants), 1); 
            beforeWindow = afterWindow - (halfWindow + 1);
            % [before;after]
            values = [mean(data(beforeWindow), 2), mean(data(afterWindow), 2)];
        end
        
        function acceleration = getScaledForPeaksAcceleration(this)
            a1 = max(0, -this.dataset.getAccelerometer().getPitch());
            a1 = a1.^2;
            acceleration = a1.* this.ACC_PEAK_SCALE_COEFF;
        end
        function clutch = getScaledForPeaksClutch(this)
            clutch = this.dataset.getClutch();
        end
        function peaks = getPeaks(this, data)
            this.filter.setType('Median');
            this.filter.MEDIAN_WINDOW = this.F_SAMPLING / 10;
            dDataRaw = this.diffAdjust(diff(data));
            dData = this.filter.setData(dDataRaw).get();
            [~, positivePeaks] = findpeaks(abs(max(0, dData)).^2, 'MinPeakProminence', this.PEAK_PROMINENCE);
            [~, negativePeaks] = findpeaks(abs(min(0, dData)).^2, 'MinPeakProminence', this.PEAK_PROMINENCE);
            peaks = {positivePeaks, negativePeaks};
        end
        
        function d = diffAdjust(~, d)
            d(end+1) = d(end);
        end
    end
end

