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

classdef GenericMaterial < BaseModel
    
    methods(Access = public)
        
        function obj = GenericMaterial(matName)
            % GenericMaterial: Constructor de la clase
            obj = obj@BaseModel(matName);
        end % GenericMaterial constructor
        
        function [f, E] = eval(obj, e) %#ok<*INUSL>
            % eval: Retorna la tension y el modulo elastico tangente del
            % material a un cierto nivel de deformacion
            f = 0 * e;
            E = 0;
        end % eval function
        
        function plt = plot(obj, varargin) %#ok<*VANUS>
            % plot: Grafica el material
            plt = 0;
        end % plot function
        
        function t = getTensionDeformation(obj, varargin) %#ok<*INUSD>
            % getTensionDeformation: Obtiene una tabla de tensiones
            % deformaciones del material
            t = [0, 0];
        end % getTensionDeformation function
        
        function disp(obj)
            % disp: Imprime la informacion del objeto en consola
            disp@BaseModel(obj);
        end % disp function
        
    end % public methods
    
end % GenericMaterial class