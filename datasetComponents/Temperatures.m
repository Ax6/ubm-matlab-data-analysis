classdef Temperatures < handle
    %TEMPERATURES Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        scamb1;
        scamb2;
        cool1;
        cool2;
        cool3;
        dataset;
        filter;
    end
    
    methods
        function this = Temperatures(dataset)
            this.dataset = dataset;
            import IMUFilter.*
            this.filter = IMUFilter();
        end
        
        function temp = getScamb1(this)
            temp = this.getFiltered(this.dataset.getData().TScamb1);
        end
        
        function temp = getScamb2(this)
            temp = this.getFiltered(this.dataset.getData().TScamb2);
        end
        
        function temp = getCool1(this)
            temp = this.getFiltered(this.dataset.getData().TCool1);
        end
        
        function temp = getCool2(this)
            temp = this.getFiltered(this.dataset.getData().TCool2);
        end
        
        function temp = getCool3(this)
            temp = this.getFiltered(this.dataset.getData().TCool3);
        end
    end
    
    methods (Access = private)
        function filtered = getFiltered(this, data)
            this.filter.setData(data);
            filtered = this.filter.get();
        end
    end
end

