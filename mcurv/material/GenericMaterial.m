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
%|                                                                      |
%| Autor: Pablo Pizarro R. @ppizarror.com                               |
%| Licencia: MIT                                                        |
%| Codigo fuente: https://github.com/ppizarror/MCURV                    |
%|______________________________________________________________________|

classdef GenericMaterial < BaseModel
    
    properties(Access = protected)
        materialColor % Color of the material
    end % protected properties
    
    methods(Access = public)
        
        function obj = GenericMaterial(matName)
            % GenericMaterial: Constructor de la clase
            
            obj = obj@BaseModel(matName);
            obj.materialColor = [0, 0, 0];
            
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
            %   emax            Deformacion mayor
            %   emin            Deformacion menor
            %   gridColor       Color de la grilla
            %   gridLineWidth   Ancho de la linea de la grilla
            %   gridStyle       Estilo de la grilla
            %   legend          Posicion de la leyenda, 'off' lo desactiva
            %   limMargin       Limites grafico en y
            %   lineColor       Color de la linea
            %   lineWidth       Ancho de la linea
            %   npoints         Numero de puntos
            %   plotType        Tipo de plot 'stress','elastic'
            %   units           Unidad del grafico
            
            p = inputParser;
            p.KeepUnmatched = true;
            p.addOptional('emax', 1);
            p.addOptional('emin', -1);
            p.addOptional('gridColor', [0.5, 0.5, 0.5]);
            p.addOptional('gridLineWidth', 0.5);
            p.addOptional('gridStyle', '--');
            p.addOptional('legend', 'off');
            p.addOptional('limMargin', 0.1);
            p.addOptional('lineColor', [0, 0, 0]);
            p.addOptional('lineWidth', 2.0);
            p.addOptional('npoints', 1000);
            p.addOptional('plotType', 'stress');
            p.addOptional('units', 'MPa');
            parse(p, varargin{:});
            r = p.Results;
            r.plotType = lower(r.plotType);
            
            % Crea la particion del espacio
            ex = linspace(r.emin, r.emax, r.npoints)';
            
            % Calcula la tension/elasticidad
            if strcmp(r.plotType, 'stress')
                [fx, ~] = obj.eval(ex);
                plotTitle = sprintf('%s - Esfuerzo', obj.getName());
                yLabel = sprintf('f - Esfuerzo (%s)', r.units);
                plotLegend = 'Esfuerzo-deformacion';
            elseif strcmp(r.plotType, 'elastic')
                [~, fx] = obj.eval(ex);
                plotTitle = sprintf('%s - Modulo elastico', obj.getName());
                yLabel = sprintf('E - Modulo elastico tangente (%s)', r.units);
                plotLegend = 'Modulo Elastico-deformacion';
            else
                error('Tipo de grafico desconocido, valores posibles: %s', ...
                    'stress,elastic');
            end
            
            % Crea la figura
            plt = figure();
            movegui(plt, 'center');
            set(gcf, 'name', plotTitle);
            
            % Grafica
            plot(ex, fx, 'LineWidth', r.lineWidth, 'Color', r.lineColor);
            lims = get(gca, 'ylim') .* (1 + r.limMargin);
            ylim(lims); % Aplica limites
            xlim = get(gca, 'xlim');
            hold on;
            plot(xlim, [0, 0], r.gridStyle, ...
                'Color', r.gridColor, 'LineWidth', r.gridLineWidth);
            plot([0, 0], lims, r.gridStyle, ...
                'Color', r.gridColor, 'LineWidth', r.gridLineWidth);
            plot(ex, fx, 'LineWidth', r.lineWidth, 'Color', r.lineColor);
            
            grid on;
            grid minor;
            
            title(plotTitle);
            xlabel('Deformacion (-)');
            ylabel(yLabel);
            
            if ~strcmp(r.legend, 'off')
                legend({plotLegend}, 'Location', r.legend);
            end
            
        end % plot function
        
        function t = getStressDeformation(obj, varargin)
            % getStressDeformation: Obtiene una tabla de esfuerzo
            % deformaciones del material
            %
            % Parametros opcionales:
            %   emax            Deformacion mayor
            %   emin            Deformacion menor
            %   file            Archivo en que se guarda la informacion
            %   npoints         Numero de puntos
            
            p = inputParser;
            p.KeepUnmatched = true;
            p.addOptional('emax', 1);
            p.addOptional('emin', -1);
            p.addOptional('file', '');
            p.addOptional('npoints', 1000);
            parse(p, varargin{:});
            r = p.Results;
            
            t = zeros(r.npoints, 2);
            j = 1; % Contador sobre t
            e = linspace(r.emin, r.emax, r.npoints);
            [f, ~] = obj.eval(e);
            
            for i = 1:r.npoints
                
                % Si se pasa por cero
                if i > 1 && f(i) > 0 && f(i-1) < 0 && f(i) ~= 0
                    t(j, 1) = 0;
                    t(j, 2) = 0;
                    j = j + 1;
                end
                
                % Guarda el punto
                t(j, 1) = e(i);
                t(j, 2) = f(i);
                j = j + 1;
                
            end
            
            % Si se pasa un archivo
            if ~strcmp(r.file, '')
                fileO = fopen(r.file, 'w');
                for i = 1:r.npoints
                    if i < r.npoints
                        fprintf(fileO, '%f\t%f\n', t(i, 1), t(i, 2));
                    else
                        fprintf(fileO, '%f\t%f', t(i, 1), t(i, 2));
                    end
                end
                fclose(fileO);
            end
            
        end % getStressDeformation function
        
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