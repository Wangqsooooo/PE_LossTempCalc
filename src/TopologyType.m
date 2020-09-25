classdef TopologyType
    enumeration
        Unknown
        TwoLevel_HalfBridge
        ThreeLevel_ANPC
    end
    
    methods
        function flag = isAvailableModulation(obj, modulationtype)
            arguments
                obj
                modulationtype ModulationType
            end
            switch obj
                case TopologyType.TwoLevel_HalfBridge
                    flag = (modulationtype == ModulationType.TwoLevel_SPWM) ...
                        || (modulationtype == ModulationType.TwoLevel_SVM);
                case TopologyType.ThreeLevel_ANPC
                    flag = (modulationtype == ModulationType.ThreeLevel_ANPC_DualCurrentPath) ...
                        || (modulationtype == ModulationType.ThreeLevel_ANPC_SingleCurrentPath);
                otherwise
                    flag = 0;
            end
        end
        function list = printModulation(obj)
            switch obj
                case TopologyType.TwoLevel_HalfBridge
                    list = string([ModulationType.TwoLevel_SPWM; ...
                        ModulationType.TwoLevel_SVM]);
                case TopologyType.ThreeLevel_ANPC
                    list = string([ModulationType.ThreeLevel_ANPC_DualCurrentPath; ...
                        ModulationType.ThreeLevel_ANPC_SingleCurrentPath]);
                otherwise
                    disp('No Predefined Modulation Method!');
                    list = [];
            end
        end
        function [path, order] = DefinedTopologyPathAndOrder(obj)
            switch obj
                case TopologyType.TwoLevel_HalfBridge
                    path = 'material\text\TwoLevel_HalfBridge.txt';
                    order = 1:2;
                case TopologyType.ThreeLevel_ANPC
                    path = 'material\text\ThreeLevel_ANPC.txt';
                    order = 1:6;
                otherwise
                    error('Unknown topology!');
            end
        end
        function result = isDefinedTopologyGraph(obj, G, select)
            switch obj
                case TopologyType.TwoLevel_HalfBridge
                    Gs = digraph([1 1 2 4 2 3], [2 4 3 3 1 2]);
                    if select == 1
                        result = isisomorphic(Gs, G);
                    else
                        I = isomorphism(Gs, G);
                        result = [I(1) I(2); I(2) I(3)];
                    end
                case TopologyType.ThreeLevel_ANPC
                    Gs = digraph([1 1 2 2 2 3 3 3 4 4 4 5 6 6], ...
                        [2 3 1 3 6 2 4 5 3 5 6 4 2 4]);
                    if select == 1
                        result = isisomorphic(Gs, G);
                    else
                        I = isomorphism(Gs, G);
                        result = [I(1) I(2); I(2) I(6); I(6) I(4); ...
                            I(4) I(5); I(2) I(3); I(3) I(4)];
                    end
                otherwise
                    result = 0;
            end
        end
    end
end
