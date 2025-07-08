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
%| ElastoplasticSteel                                                   |
%|                                                                      |
%| Definicion de acero elastoplastico, con endurecimiento por deforma-  |
%| cion bilineal.                                                       |
%|                                                                      |
%| Autor: Pablo Pizarro R. @ppizarror.com                               |
%| Licencia: MIT                                                        |
%| Codigo fuente: https://github.com/ppizarror/MCURV                    |
%|______________________________________________________________________|

classdef ElastoplasticSteel < GenericMaterial

    properties (Access = protected)
        fy % Tension de fluencia del acero
        Es1 % Modulo elastico
        Es2 % Modulo elastico plastificado
        ey % Deformacion de fluencia del acero
        eu % Deformacion ultima del acero
    end % protected properties

    methods (Access = public)

        function obj = ElastoplasticSteel(matName, fy, Es1, Es2, eu)
            % ElastoplasticSteel: Constructor de la clase
            %
            % Parametros:
            %   fy      Tension de fluencia
            %   Es1     Modulo de rigidez elastico
            %   Es2     Modulo de rigidez post fluencia
            %   eu      Deformacion ultima [-]

            if nargin ~= 5
                error('Numero de parametros incorrectos, uso: %s', ...
                    'ElastoplasticSteel(matName,fy,Es1,Es2,eu)');
            end
            obj = obj@GenericMaterial(matName);
            obj.ey = fy / Es1;
            obj.fy = fy;
            obj.Es1 = Es1;
            obj.Es2 = Es2;
            obj.eu = eu;

        end % ElastoplasticSteel constructor
        
        function e = e_lim(obj)
            % e_lim: Retorna los limites de deformacion del material

            e = [-obj.eu, obj.eu];

        end % e_lim function

        function [f, E] = eval(obj, e)
            % eval: Retorna la tension y el modulo elastico tangente del
            % material a un cierto nivel de deformacion

            % Crea los vectores solucion
            n = length(e); % Largo del vector
            f = zeros(n, 1);
            E = zeros(n, 1);

            % Deterimina rango
            for i = 1:n
                esi = abs(e(i));
                sgn = sign(e(i));
                if (0 <= esi) && (esi < obj.ey) % Rango elastico
                    f(i) = obj.Es1 * esi * sgn;
                    E(i) = obj.Es1;
                elseif (obj.ey <= esi) && (esi <= obj.eu) % Rango post fluencia
                    f(i) = (obj.fy + obj.Es2 * (esi - obj.ey)) * sgn;
                    E(i) = obj.Es2;
                else % Rotura
                    f(i) = NaN;
                    E(i) = NaN;
                end
            end

        end % eval function

        function disp(obj)
            % disp: Imprime la informacion del objeto en consola

            fprintf('Propiedades acero elastoplastico:\n');
            disp@GenericMaterial(obj);
            fprintf('\tTension de fluencia: %.2f\n', obj.fy);
            fprintf('\tModulos elasticos:\n\t\tEs1: %.1f\n\t\tEs2: %.1f\n', ...
                obj.Es1, obj.Es2);
            dispMCURV();

        end % disp function

    end % public methods

end % ElastoplasticSteel class