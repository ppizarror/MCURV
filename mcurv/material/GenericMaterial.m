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
    
    properties(Access = protected)
        materialColor % Color of the material
    end % protected properties
    
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
        
        function plt = plot(obj, varargin)
            % plot: Grafica el material
            %
            % Parametros opcionales:
            %   emin            Deformacion menor
            %   emax            Deformacion mayor
            %   npoints         Numero de puntos
            %   plotType        Tipo de plot 'tension','elastic'
            %   lineColor       Color de la linea
            %   gridStyle       Estilo de la grilla
            %   gridLineWidth   Ancho de la linea de la grilla
            %   gridColor       Color de la grilla
            %   lineWidth       Ancho de la linea
            %   legend          Posicion de la leyenda, 'off' lo desactiva
            %   units           Unidad del grafico
            
            p = inputParser;
            p.KeepUnmatched = true;
            p.addOptional('emin', -1);
            p.addOptional('emax', 1);
            p.addOptional('npoints', 1000);
            p.addOptional('lineColor', [0, 0, 0]);
            p.addOptional('gridLineWidth', 1);
            p.addOptional('gridStyle', '--');
            p.addOptional('gridColor', [0.5, 0.5, 0.5]);
            p.addOptional('lineWidth', 2.0);
            p.addOptional('plotType', 'tension');
            p.addOptional('legend', 'northwest');
            p.addOptional('units', 'MPa');
            parse(p, varargin{:});
            r = p.Results;
            r.plotType = lower(r.plotType);
            
            % Crea la particion del espacio
            ex = linspace(r.emin, r.emax, r.npoints)';
 
            % Calcula la tension o elasticidad
            if strcmp(r.plotType, 'tension')
                [fx, ~] = obj.eval(ex);
                plotTitle = sprintf('%s - Tension', obj.getName());
                yLabel = sprintf('f - Tension (%s)', r.units);
            elseif strcmp(r.plotType, 'elastic')
                [~, fx] = obj.eval(ex);
                plotTitle = sprintf('%s - Modulo elastico', obj.getName());
                yLabel = sprintf('E - Modulo elastico tangente (%s)', r.units);
            else
                error('Tipo de grafico desconocido, valores posibles: %s', ...
                    'tension, elastic');
            end
            
            % Crea la figura
            plt = figure();
            movegui(plt, 'center');
            set(gcf, 'name', plotTitle);
            
            % Grafica
            plot(ex, fx, 'LineWidth', r.lineWidth, 'Color', r.lineColor);
            hold on;
            plot([min(ex), max(ex)], [0, 0], r.gridStyle, ...
                'Color', r.gridColor, 'LineWidth', r.gridLineWidth);
            plot([0, 0], [min(fx), max(fx)], r.gridStyle, ...
                'Color', r.gridColor, 'LineWidth', r.gridLineWidth);
            plot(ex, fx, 'LineWidth', r.lineWidth, 'Color', r.lineColor);
            
            grid on;
            grid minor;
            
            title(plotTitle);
            xlabel('Deformacion (-)');
            ylabel(yLabel);
            
            if ~strcmp(r.legend, 'off')
                legend({'Tension-deformacion'}, 'Location', r.legend);
            end
            
        end % plot function
        
        function t = getTensionDeformation(obj, varargin)
            % getTensionDeformation: Obtiene una tabla de tensiones
            % deformaciones del material
            %
            % Parametros opcionales:
            %   emin            Deformacion menor
            %   emax            Deformacion mayor
            %   npoints         Numero de puntos
            
            p = inputParser;
            p.KeepUnmatched = true;
            p.addOptional('emin', -1);
            p.addOptional('emax', 1);
            p.addOptional('npoints', 1000);
            parse(p, varargin{:});
            r = p.Results;
            
            t = zeros(r.npoints, 2);
            e = linspace(r.emin, r.emax, r.npoints);
            [f, ~] = obj.eval(e);
            
            for i=1:r.npoints
                t(i, 1) = e(i);
                t(i, 2) = f(i);
            end
            
        end % getTensionDeformation function
        
        function disp(obj)
            % disp: Imprime la informacion del objeto en consola
            disp@BaseModel(obj);
        end % disp function
        
        function setColor(obj, color)
            % setColor: Set material color
            obj.materialColor = color;
        end % setColor function
        
        function c = getColor(obj)
            % getColor: Return material color
            c = obj.materialColor;
        end % getColor function
        
    end % public methods
    
end % GenericMaterial class