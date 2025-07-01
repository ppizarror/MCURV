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
%| GenericEvent                                                         |
%|                                                                      |
%| Definicion de clase evento generico. Un evento es una parte del ana- |
%| lisis que permite verificar si un determinado elemento cumple con un |
%| nivel de deformacion, curvatura, tension o rigidez.                  |
%|                                                                      |
%| Autor: Pablo Pizarro R. @ppizarror.com                               |
%| Licencia: MIT                                                        |
%| Codigo fuente: https://github.com/ppizarror/MCURV                    |
%|______________________________________________________________________|

classdef GenericEvent < BaseModel

    methods (Access = public)

        function obj = GenericEvent(eventName)
            % GenericEvent: Constructor de la clase

            obj = obj@BaseModel(eventName);

        end % GenericEvent constructor

        function eval(obj, e0, phix, phiy, eps, f, E, p, mx, my, n) %#ok<INUSD>
            % eval: Evalua el evento.
            %
            % Parametros requeridos:
            %   e0          Valor de la deformacion con respecto al centroide
            %   phix        Curvatura en x
            %   phiy        Curvatura en y
            %   eps         Deformacion
            %   f           Tension del material
            %   E           Rigidez tangente
            %   p           Nivel de carga axial total analisis
            %   mx          Momento total eje x en analisis
            %   my          Momento total eje y en analisis
            %   n           Numero iteracion

        end % eval function

        function printAll(obj, e0, phix, phiy, eps, f, E, p, mx, my, n) %#ok<INUSL>
            % printAll: Imprime todas las propiedades del evento.
            %
            % Parametros requeridos:
            %   e0          Valor de la deformacion con respecto al centroide
            %   phix        Curvatura en x
            %   phiy        Curvatura en y
            %   eps         Deformacion
            %   f           Tension del material
            %   E           Rigidez tangente
            %   p           Nivel de carga axial total analisis
            %   mx          Momento total eje x en analisis
            %   my          Momento total eje y en analisis
            %   n           Numero iteracion

            fprintf('\tCurvatura: phix=%f, phiy=%f\n', phix, phiy);
            fprintf('\tDeformacion: e0=%f, eps=%f\n', e0, eps);
            fprintf('\tTension: %f\n', f);
            fprintf('\tMomento: x=%f, y=%f\n', mx, my);
            fprintf('\tModulo de elasticidad tangente: %f\n', E);
            fprintf('\tCarga axial: %f\n', p);
            fprintf('\tIteracion: %d\n', n);

        end % printAll
        
        function reset(obj) %#ok<MANU>
            % reset: Resetea evento

        end % reset function

    end % public methods

end % GenericMaterial class