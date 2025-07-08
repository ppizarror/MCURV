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
%| DeformationLimit                                                     |
%|                                                                      |
%| Evento simple.  Verifica que la seccion haya superado un determinado |
%| umbral de deformacion.                                               |
%|                                                                      |
%| Autor: Pablo Pizarro R. @ppizarror.com                               |
%| Licencia: MIT                                                        |
%| Codigo fuente: https://github.com/ppizarror/MCURV                    |
%|______________________________________________________________________|

classdef DeformationLimit < GenericEvent

    properties (Access = protected)
        epsLim % Maxima deformacion registrada
        hit % Umbral superado
        hitData % Valor de [phix, phiy, mx, my] que logra deformacion
        isAbs % Usa valor absoluto
        maxEps % Maxima deformacion
        name % Nombre evento
    end % protected properties

    methods (Access = public)

        function obj = DeformationLimit(eventName, maxEps, isAbs)
            % DeformationLimit: Constructor de la clase
            %
            % Parametros:
            %   maxEps     Maxima deformacion
            %   abs        Usa valor absoluto. Verdadero por defecto
            if nargin < 3
                isAbs = false;
            end
            if nargin < 2
                error('Numero de parametros incorrectos, uso: %s', ...
                    'DeformationLimit(eventName,max_eps,abs)');
            end
            obj = obj@GenericEvent(eventName);
            obj.epsLim = [0, 0, 0];
            obj.isAbs = isAbs;
            if isAbs
                obj.maxEps = abs(maxEps);
            else
                obj.maxEps = maxEps;
            end
            obj.name = eventName;
            obj.reset();

        end % DeformationLimit constructor

        function [e, phix, phiy] = eLim(obj)
            % eLim: Retorna la maxima deformacion registrada (def, phix, phiy)

            e = obj.epsLim(1);
            phix = obj.epsLim(2);
            phiy = obj.epsLim(3);

        end % eLim function

        function o = phix(obj)
            % phix: Deformacion si se cumple condicion evento

            o = obj.hitData(1);

        end % phix function

        function o = phiy(obj)
            % phiy: Deformacion si se cumple condicion evento

            o = obj.hitData(2);

        end % phiy function

        function eval(obj, e0, phix, phiy, eps, f, E, p, mx, my, n)
            % eval: Evalua el evento
            if abs(eps) > abs(obj.epsLim(1))
                obj.epsLim = [eps, phix, phiy];
            end
            if obj.hit
                return
            elseif (obj.isAbs && abs(eps) > obj.maxEps) || (obj.maxEps < 0 && eps < obj.maxEps || obj.maxEps > 0 && eps > obj.maxEps)
                fprintf('\n');
                dispMCURV();
                if obj.maxEps < 0
                    expr = '<';
                else
                    expr = '>';
                end
                fprintf('Evento Deformacion limite: %s (%f %s %f)\n', obj.name, eps, expr, obj.maxEps);
                obj.printAll(e0, phix, phiy, eps, f, E, p, mx, my, n);
                obj.hit = true;
                obj.hitData = [phix, phiy, mx, my];
                dispMCURV();
            end

        end % eval function

        function disp(obj)
            % disp: Imprime la informacion del objeto en consola

            fprintf('Propiedades evento deformacion limite:\n');
            disp@GenericMaterial(obj);
            fprintf('\tDeformacion maxima: %.2f\n', obj.max_eps);
            dispMCURV();

        end % disp function

        function reset(obj)
            % reset: Resetea evento

            obj.hit = false;
            obj.hitData = [0, 0, 0, 0];

        end % reset function

    end % public methods

end % HognestadConcrete class