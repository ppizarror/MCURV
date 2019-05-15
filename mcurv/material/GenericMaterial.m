% ______________________________________________________________________
%|                                                                      |
%|           MCURV - Toolbox para Calculo de Momento Curvatura          |
%|                                                                      |
%|                    Area de Estructuras y Geotecnia                   |
%|                   Departamento de Ingenieria Civil                   |
%|              Facultad de Ciencias Fisicas y Matematicas              |
%|                         Universidad de Chile                         |
%|                                                                      |
%| MCURV es una plataforma en MATLAB que permite realizar calculos de   |
%| momento curvatura de secciones genericas utilizando la metodologia de|
%| calculo no lineal Newton-Raphson.                                    |
%|______________________________________________________________________|
%|                                                                      |
%| GenericMaterial                                                      |
%|                                                                      |
%| Definicion de clase material generica, un material se define por su  |
%| trayectoria de esfuerzo deformacion. Debe poder graficarse, retornar |
%| una tabla tension deformacion (con N puntos) y poder obtener el valor|
%| de la tension y la rigidez tangente en cualquier valor de la         |
%| deformacion.                                                         |
%|______________________________________________________________________|

classdef GenericMaterial
 
    properties(Access = public)
        Property1
    end
    
    methods(Access = public)
        function obj = GenericMaterial(tag)
            % 
            obj.Property1 = inputArg1 + inputArg2;
        end
        
        function outputArg = method1(obj, inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end
    end
end