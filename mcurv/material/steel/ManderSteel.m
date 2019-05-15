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
%| ManderSteel                                                          |
%|                                                                      |
%| Definicion de acero no lineal usando el modelo de Mander et al.      |
%| (1984).                                                              |
%|                                                                      |
%| Autor: Pablo Pizarro R. @ppizarror.com                               |
%| Licencia: MIT                                                        |
%| Codigo fuente: https://github.com/ppizarror/MCURV                    |
%|______________________________________________________________________|

classdef ManderSteel < GenericMaterial
    
    properties(Access = protected)
        fy % Tension de fluencia del acero
        ey % Deformacion al llegar a la fluencia
        Es % Modulo elastico
        fsu % Fluencia maxima
        Esh % Pendiente del modulo elastico despues de la fluencia
        esh % Deformacion post fluencia
        esu % Deformacion en maximo limite
        ef % Deformacion final
    end % protected properties
    
    methods(Access = public)
        
        function obj = ManderSteel(matName, fy, Es, fsu, Esh, esh, esu, ef)
            % ManderSteel: Constructor de la clase
            %
            % Parametros:
            %   fy      Tension de fluencia
            %   Es      Modulo elastico
            %   fsu     Fluencia maxima
            %   Esh     Pendiente del modulo elastico despues de la fluencia
            %   esh     Deformacion post fluencia
            %   esu     Deformacion en maximo limite
            %   ef      Deformacion final
            
            if nargin ~= 8
                error('Numero de parametros incorrectos, uso: %s', ...
                    'ManderSteel(matName, fy, Es, fsu, Esh, esh, esu, ef)');
            end
            obj = obj@GenericMaterial(matName);
            obj.ey = fy / Es;
            obj.Es = Es;
            obj.fy = fy;
            obj.fsu = fsu;
            obj.Esh = Esh;
            obj.esh = esh;
            obj.esu = esu;
            obj.ef = ef;
            
        end % ManderSteel constructor
        
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
                    f(i) = obj.Es * esi * sgn;
                    E(i) = obj.Es;
                elseif (obj.ey <= esi) && (esi < obj.esh) % Rango meseta elastica
                    f(i) = obj.fy * sgn;
                    E(i) = 0;
                elseif (obj.esh <= esi) && (esi < obj.ef) % Rango endurecimiento
                    p = obj.Esh * (obj.esu - obj.esh) / (obj.fsu - obj.fy);
                    fr = (obj.esu - esi) / (obj.esu - obj.esh); % Fraccion
                    f(i) = obj.fsu + (obj.fy - obj.fsu) * abs(fr)^p;
                    if f(i) < 0
                        f(i) = 0;
                        E(i) = 0;
                    else
                        f(i) = f(i)* sgn;
                        E(i) = -sgn * (obj.fy - obj.fsu) * (abs(fr)^p) * p * absDerivative(fr) / ((obj.esu - obj.esh) * abs(fr));
                    end
                else % Rotura
                    f(i) = 0;
                    E(i) = 0;
                end
            end
            
        end % eval function
        
        function disp(obj)
            % disp: Imprime la informacion del objeto en consola
            
            fprintf('Propiedades acero Mander et al. (1984):\n');
            disp@GenericMaterial(obj);
            fprintf('\tTension:\n\t\tfy: %.2f\n\t\tfsu: %.2f (%.2ffy)\n', ...
                obj.fy, obj.fsu, obj.fsu/obj.fy);
            fprintf('\tModulos elasticos:\n\t\tEs: %.1f\n\t\tEsh: %.1f (1/%.1f)\n', ...
                obj.Es, obj.Esh, obj.Es/obj.Esh);
            fprintf('\tDeformaciones:\n\t\tey: %.4f\n\t\tesh: %.4f\n\t\tesu: %.4f\n\t\tef: %.4f\n', ...
                obj.ey, obj.esh, obj.esu, obj.ef);
            dispMCURV();
            
        end % disp function
        
    end % public methods
    
end % ManderSteel class