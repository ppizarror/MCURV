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
%| HognestadModifiedConcrete                                            |
%|                                                                      |
%| Definicion de material de hormigon con modelo Hognestad modificado,  |
%| asociado al modelo de compresion del hormigon no confinado.          |
%|                                                                      |
%| Autor: Pablo Pizarro R. @ppizarror.com                               |
%| Licencia: MIT                                                        |
%| Codigo fuente: https://github.com/ppizarror/MCURV                    |
%|______________________________________________________________________|

classdef HognestadModifiedConcrete < GenericMaterial
    
    properties(Access = protected)
        fc % Tension de rotura
        Ec % Modulo elastico en compresion
        fr % Tension maxima de rotura en traccion
        er % Deformacion de traccion
        eo % Deformacion a resistencia maxima
        eu % Deformacion ultima
    end % protected properties
    
    methods(Access = public)
        
        function obj = HognestadModifiedConcrete(matName, fc, eo, eu)
            % HognestadModifiedConcrete: Constructor de la clase
            %
            % Parametros:
            %   fc      Resistencia a compresion (f'c)
            %   eo      Deformacion a resistencia maxima
            %   eu      Deformacion ultima
            
            if nargin ~= 4
                error('Numero de parametros incorrectos, uso: %s', ...
                    'HognestadModifiedConcrete(matName, fc, eo, eu)');
            end
            obj = obj@GenericMaterial(matName);
            obj.fc = fc;
            obj.eo = eo;
            obj.fr = 0.62 * sqrt(fc);
            obj.Ec = 4700 * sqrt(fc);
            obj.er = -obj.fr / obj.Ec;
            obj.eu = eu;
            
        end % HognestadModifiedConcrete constructor
        
        function [f, E] = eval(obj, e)
            % eval: Retorna la tension y el modulo elastico tangente del
            % material a un cierto nivel de deformacion
            
            % Crea los vectores solucion
            n = length(e); % Largo del vector
            f = zeros(n, 1);
            E = zeros(n, 1);
            
            % Deterimina rango
            for i = 1:n
                if e(i) < obj.er % Sobrepasa a rotura
                    f(i) = 0;
                    E(i) = 0;
                elseif (obj.er <= e(i)) && (e(i) < 0) % Tension
                    f(i) = obj.Ec * e(i);
                    E(i) = obj.Ec;
                elseif (0 <= e(i)) && (e(i) < obj.eo) % Compresion, menor a la parabola
                    f(i) = obj.fc * (2 * (e(i) / obj.eo) - (e(i) / obj.eo)^2);
                    E(i) = 2 * obj.fc * (1 / obj.eo - e(i) / (obj.eo^2));
                elseif (obj.eo <= e(i)) && (e(i) < obj.eu) % Tramo descendente
                    f(i) = obj.fc * (1 - 0.15 * (e(i) - obj.eo) / (obj.eu - obj.eo));
                    E(i) = -0.15 * obj.fc / (obj.eu - obj.eo);
                else % Sobrepaso compresion
                    f(i) = 0;
                    E(i) = 0;
                end
            end
            
        end % eval function
        
        function disp(obj)
            % disp: Imprime la informacion del objeto en consola
            
            fprintf('Propiedades hormigon modelo Hognestad modificado:\n');
            disp@GenericMaterial(obj);
            fprintf('\tResistencia a compresion fc: %.2f\n', obj.fc);
            fprintf('\tResistencia a traccion fr: %.2f\n', obj.fr);
            fprintf('\tModulo elastico a compresion: %.1f\n', obj.Ec);
            fprintf('\tDeformaciones:\n\t\ter: %.4f\n\t\teo: %.4f\n\t\teu: %.4f\n', ...
                obj.er, obj.eo, obj.eu);
            fu = obj.eval(obj.eu*0.9999999);
            fprintf('\tTension a deformacion ultima: %.2f (%.2ffc)\n', ...
                fu, fu/obj.fc);
            dispMCURV();
            
        end % disp function
        
    end % public methods
    
end % HognestadModifiedConcrete class