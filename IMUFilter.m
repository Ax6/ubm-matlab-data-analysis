%% Class with general purpose filters aimed for testing and development
% data to filter can be either passed to constructor or to '.setData(data)'
% Available filters (usable with '.setType(fltType)')
% fltType: (Default = Sgolay)
%   "Sgolay" | "LMS" | "MA" | "Median" | "LowPass"
% '.get()' returns filtered data with the choosen fltType
classdef IMUFilter < handle
    properties
        originalData;
        dataSize;
        tStart;
        tEnd;
        dataInterval = 0;
        compareData;
        compareLegend = {'Original Data'};
        MA_WEIGHTS = 0.2:-0.01:0.1;
        FIR_ORDER = 100;
        FIR_BAND = [.25, .75];
        LMS_STEP = 0.05;
        MEDIAN_WINDOW = 20;
        LOW_PASS_CUTOFF = 20;
        LOW_PASS_ORDER = 70;
        SGOLAY1 = 3;
        SGOLAY2 = 33;
        defaultType = 'Sgolay';
        F_SAMPLING = 100;
    end
    methods (Access = public)
        %Constructor
        function this = IMUFilter(originalData)
           if exist('originalData', 'var')
               this.setData(originalData);
           end
        end
        function this = setData(this, originalData)
             this.originalData = originalData;
            this.dataSize = size(this.originalData);
            this.dataSize = this.dataSize(1);
            this.tStart = 0;
            this.tEnd = this.getDuration();
        end
        %Filtering methods
        function this = setType(this, type)
            this.defaultType = type;
        end
        function filtered = get(this)
            filtered = this.(strcat('get',this.defaultType))();
        end
        function filtered = getLMS(this)
            [length,~] = size(this.getData());
            firFilter = dsp.FIRFilter('Numerator', fir1(this.FIR_ORDER, this.FIR_BAND)); 
            lmsFilter = dsp.LMSFilter('Length',length,'Method','Normalized LMS','StepSize', this.LMS_STEP);
            moreData = firFilter(this.getData()) + this.getData();
            filtered = lmsFilter(this.getData(), moreData);
        end
        function filtered = getMA(this)
            filtered = filter(this.MA_WEIGHTS, sum(this.MA_WEIGHTS), this.getData());
        end
        function filtered = getMedian(this)
            filtered = medfilt1(this.getData(), this.MEDIAN_WINDOW);
        end
        function filtered = getSgolay(this)
            filtered = sgolayfilt(this.getData(), this.SGOLAY1, this.SGOLAY2);
        end
        function filtered = getLowPass(this)
            Fnorm = this.LOW_PASS_CUTOFF/(this.F_SAMPLING/2);
            df = designfilt('lowpassfir','FilterOrder',this.LOW_PASS_ORDER,'CutoffFrequency',Fnorm); 
            filtered = filter(df, this.getData());
        end
        %Misc and plot
        function addCompare(this, data, legend)
            if (~exist('legend','var'))
                legend = 'Compare Data';
            end
            this.compareLegend{end+1} = legend;
            this.compareData(end+1,:) = data;
        end
        function plotCompare(this)
            t = this.getTimeAxis();
            plot(t, this.getData(), '--');
            [compareDataSize, ~] = size(this.compareData);
            for i = 1:compareDataSize
                hold on
                plot(t, this.compareData(i,:), '-');
            end
            legend(this.compareLegend)
            %this.compareData = [];
            %this.compareLegend = {'Original Data'};
        end
        function setStart(this, tStart)
            this.tStart = tStart;
        end
        function setEnd(this, tEnd)
            this.tEnd = tEnd;
            if tEnd > this.getDuration()
                this.tEnd = this.getDuration();
            end
        end
        function t = getTimeAxis(this)
            timeInterval = this.getTimeInterval();
            t = timeInterval(1):1/this.F_SAMPLING:timeInterval(2);
        end
        function dataInterval = getDataInterval(this)
            dataInterval = floor((this.getTimeInterval() .* this.F_SAMPLING) + 1);
        end
        function timeInterval = getTimeInterval(this)
            timeInterval = [this.tStart, this.tEnd];
        end
        function time = getDuration(this)
            time = ((length(this.originalData) - 1) / this.F_SAMPLING);
        end
        function data = getData(this)
            interval = this.dataInterval;
            if ~this.dataInterval
                interval = this.getDataInterval();
            end
            data = this.originalData(interval(1):interval(2));
        end
    end
end