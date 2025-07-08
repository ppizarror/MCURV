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
%| HognestadConcrete                                                    |
%|                                                                      |
%| Definicion de material de hormigon con modelo Hognestad.             |
%|                                                                      |
%| Autor: Pablo Pizarro R. @ppizarror.com                               |
%| Licencia: MIT                                                        |
%| Codigo fuente: https://github.com/ppizarror/MCURV                    |
%|______________________________________________________________________|

classdef HognestadConcrete < GenericMaterial

    properties (Access = protected)
        fc % Tension de rotura
        Ec % Modulo elastico en compresion
        fr % Tension maxima de rotura en traccion
        er % Deformacion de traccion
        eo % Deformacion a resistencia maxima
        eu % Deformacion ultima
    end % protected properties

    methods (Access = public)

        function obj = HognestadConcrete(matName, fc, eo)
            % HognestadConcrete: Constructor de la clase
            %
            % Parametros:
            %   fc      Resistencia a compresion (f'c)
            %   eo      Deformacion a resistencia maxima

            if nargin ~= 3
                error('Numero de parametros incorrectos, uso: %s', ...
                    'HognestadConcrete(matName,fc,eo)');
            end
            obj = obj@GenericMaterial(matName);
            obj.fc = fc;
            obj.eo = eo;
            obj.fr = 0.62 * sqrt(fc);
            obj.Ec = 4700 * sqrt(fc);
            obj.er = -obj.fr / obj.Ec;
            obj.eu = 2 * eo;

        end % HognestadConcrete constructor

        function e = e_lim(obj)
            % e_lim: Retorna los limites de deformacion del material

            e = [obj.er, obj.eu];

        end % e_lim function

        function [f, E] = eval(obj, e)
            % eval: Retorna la tension y el modulo elastico tangente del
            % material a un cierto nivel de deformacion

            % Crea los vectores solucion
            n = length(e); % Largo del vector
            f = zeros(n, 1);
            E = zeros(n, 1);

            % Determina rango
            for i = 1:n
                if e(i) < obj.er % Sobrepasa a rotura
                    f(i) = 0;
                    E(i) = 0;
                elseif (obj.er <= e(i)) && (e(i) < 0) % Tension
                    f(i) = obj.Ec * e(i);
                    E(i) = obj.Ec;
                elseif (0 <= e(i)) && (e(i) <= obj.eu) % Compresion
                    f(i) = obj.fc * (2 * (e(i) / obj.eo) - (e(i) / obj.eo)^2);
                    E(i) = 2 * obj.fc * (1 / obj.eo - e(i) / (obj.eo^2));
                else % Sobrepaso compresion
                    f(i) = NaN;
                    E(i) = NaN;
                end
            end

        end % eval function

        function disp(obj)
            % disp: Imprime la informacion del objeto en consola

            fprintf('Propiedades hormigon modelo Hognestad:\n');
            disp@GenericMaterial(obj);
            fprintf('\tResistencia a compresion fc: %.2f\n', obj.fc);
            fprintf('\tResistencia a traccion fr: %.2f\n', obj.fr);
            fprintf('\tModulo elastico a compresion: %.1f\n', obj.Ec);
            fprintf('\tDeformaciones:\n\t\ter: %.4f\n\t\teo: %.4f\n\t\teu: %.4f\n', ...
                obj.er, obj.eo, obj.eu);
            dispMCURV();

        end % disp function

    end % public methods

end % HognestadConcrete class