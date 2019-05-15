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
%| SectionDesigner                                                      |
%|                                                                      |
%| Clase que define la geometria y materialidad de una seccion prima-   |
%| tica.                                                                |
%|                                                                      |
%| Autor: Pablo Pizarro R. @ppizarror.com                               |
%| Licencia: MIT                                                        |
%| Codigo fuente: https://github.com/ppizarror/MCURV                    |
%|______________________________________________________________________|

classdef SectionDesigner < BaseModel
    
    properties(Access = private)
        contGeom % Geometrias objetos continuos
        contGeomPlot % Guarda definicion de graficos de los objetos continuos
        contMat % Materialidad objetos continuos
        contTotal % Numero total de objetos continuos
        contParams % Parametros adicionales objetos continuos
        singGeom % Geometrias objetos singulares
        singGeomPlot % Guarda definicion de graficos de los objetos singulares
        singMat % Materialidad objetos singulares
        singTotal % Total de objetos singulares
        singParams % Parametros adicionales objetos singulares
        
    end % protected properties
    
    methods(Access = public)
        
        function obj = SectionDesigner(matName)
            % SectionDesigner: Constructor de la clase
            
            if nargin < 1
                error('Numero de parametros incorrectos, uso: %s', ...
                    'SectionDesigner(matName)');
            end
            obj = obj@BaseModel(matName);
            
            % Genera las bases
            obj.contGeom = {};
            obj.contGeomPlot = {};
            obj.contMat = {};
            obj.contTotal = 0;
            obj.contParams = {};
            obj.singParams = {};
            obj.singGeom = {};
            obj.singGeomPlot = {};
            obj.singMat = {};
            obj.singTotal = 0;
            
        end % SectionDesigner constructor
        
        function addDiscreteRect(obj, xc, yc, b, h, nx, ny, material, varargin)
            % addDiscreteRect: Agrega un rectangulo discreto a la seccion,
            % con centro (xc,yc) altura h, ancho b y una materialidad
            %
            % Parametros opcionales
            %   linewidth       Ancho de linea de la seccion
            %   transparency    Transparencia de la seccion
            
            if nargin < 8
                error('Numero de parametros incorrectos, uso: %s', ...
                    'addDiscreteRect(obj,xc,yc,b,h,nx,ny,material,varargin)');
            end
            if ~isa(material, 'GenericMaterial')
                error('Material no es un objeto de clase GenericMaterial');
            end
            
            p = inputParser;
            p.KeepUnmatched = true;
            p.addOptional('transparency', 0.6);
            p.addOptional('linewidth', 0.5);
            addParameter(p, 'MCURVgeometry', 'rectangle');
            parse(p, varargin{:});
            r = p.Results;
            
            obj.contTotal = obj.contTotal + 1;
            obj.contGeomPlot{obj.contTotal} = [xc - b / 2, yc - h / 2, b, h];
            obj.contMat{obj.contTotal} = material;
            obj.contParams{obj.contTotal} = r;
            
            % Genera la discretizacion
            dx = b / nx;
            dy = h / ny;
            
            tn = nx * ny; % Puntos totales
            px = zeros(tn, 1); % Puntos en x
            py = zeros(tn, 1); % Puntos en y
            
            y = yc - h / 2 + dy / 2;
            k = 1; % Guarda el numero del punto
            for i = 1:ny
                x = xc - b / 2 + dx / 2;
                for j = 1:nx
                    px(k) = x;
                    py(k) = y;
                    x = x + dx;
                    k = k + 1;
                end
                y = y + dy;
            end
            
            % Guarda la geometria
            obj.contGeom{obj.contTotal} = {px, py, dx, dy, tn, xc, yc, b*h};
            
        end % addDiscreteRect function
        
        function addFiniteArea(obj, x, y, area, material, varargin)
            % addFiniteArea: Agrega un area finita
            %
            % Parametros opcionales
            %   transparency    Transparencia de la seccion
            
            if nargin < 5
                error('Numero de parametros incorrectos, uso: %s', ...
                    'addFiniteArea(obj,x,y,area,material,varargin)');
            end
            if ~isa(material, 'GenericMaterial')
                error('Material no es un objeto de clase GenericMaterial');
            end
            
            p = inputParser;
            p.KeepUnmatched = true;
            p.addOptional('transparency', 0);
            parse(p, varargin{:});
            r = p.Results;
            r.transparency = 1-r.transparency;
            
            obj.singTotal = obj.singTotal + 1;
            b = sqrt(area);
            obj.singGeomPlot{obj.singTotal} = [x - b / 2, y - b / 2, b, b];
            obj.singMat{obj.singTotal} = material;
            obj.singParams{obj.singTotal} = r;
            obj.singGeom{obj.singTotal} = {x, y, area};
            
        end % addFiniteArea function
        
        function plt = plot(obj, varargin)
            % plot: Grafica la seccion
            %
            % Parametros opcionales:
            %   units           Unidades del modelo
            %   showdisc        Grafica la discretizacion
            %   limMargin       Incrementa el margen
            
            p = inputParser;
            p.KeepUnmatched = true;
            p.addOptional('units', 'mm');
            p.addOptional('showdisc', false);
            p.addOptional('limMargin', 0.1);
            parse(p, varargin{:});
            r = p.Results;
            
            % Genera la figura
            plt = figure();
            movegui(plt, 'center');
            set(gcf, 'name', obj.getName());
            hold on;
            grid on;
            grid minor;
            axis equal;
            
            % Agrega los elementos continuos
            for i = 1:obj.contTotal
                if strcmp(obj.contParams{i}.MCURVgeometry, 'rectangle')
                    rectangle('Position', obj.contGeomPlot{i}, ...
                        'FaceColor', [obj.contMat{i}.getColor(), obj.contParams{i}.transparency], ...
                        'EdgeColor', obj.contMat{i}.getColor(), ...
                        'LineWidth', obj.contParams{i}.linewidth);
                end
            end
            
            % Grafica la discretizacion de los elementos continuos
            if r.showdisc
                for i = 1:obj.contTotal
                    g = obj.contGeom{i};
                    px = g{1};
                    py = g{2};
                    dx = g{3};
                    dy = g{4};
                    tn = g{5};
                    
                    for j = 1:tn
                        rectangle('Position', [px(j) - dx / 2, py(j) - dy / 2, dx, dy], ...
                            'EdgeColor', [obj.contMat{i}.getColor(), 0.25], ...
                            'LineWidth', obj.contParams{i}.linewidth*0.5);
                        plot(px(j), py(j), '.', 'MarkerSize', 10, 'Color', ...
                            [obj.contMat{i}.getColor(), 0.25]);
                    end
                    
                end
            end
            
            % Agrega los elementos discretos
            for i = 1:obj.singTotal
                rectangle('Position', obj.singGeomPlot{i}, ...
                    'FaceColor', [obj.singMat{i}.getColor(), obj.singParams{i}.transparency], ...
                    'EdgeColor', [obj.singMat{i}.getColor(), obj.singParams{i}.transparency]);
            end
            
            % Modifica los ejes para dejar la misma escala
            lims =  get(gca, 'ylim') .* (1 + r.limMargin);
            xlim(lims);
            ylim(lims);
            
            % Cambia los label
            xlabel(sprintf('x (%s)', r.units));
            ylabel(sprintf('y (%s)', r.units));
            
        end % plot function
        
        function [xi, yi] = getCentroid(obj)
            % getCentroid: Calcula el centroide
            
            % Calcula el centroide en x
            xid = 0;
            yid = 0;
            at = 0; % Area total
            for i = 1:obj.contTotal
                g = obj.contGeom{i};
                xid = xid + g{6}*g{8};
                yid = yid + g{7}*g{8};
                at = at + g{8};
            end
            
            for i = 1:obj.singTotal
                g = obj.singGeom{i};
                xid = xid + g{1}*g{3};
                yid = yid + g{2}*g{3};
                at = at + g{3};
            end
            
            % Calcula el centride
            xi = xid / at;
            yi = yid / at;
            
        end % getCentroid function
        
        function area = getArea(obj)
            % getArea: Calcula el area total
            
            area = 0; % Area total
            for i = 1:obj.contTotal
                g = obj.contGeom{i};
                area = area + g{8};
            end 
            for i = 1:obj.singTotal
                g = obj.singGeom{i};
                area = area + g{3};
            end
            
        end % getArea function
        
        function disp(obj)
            % disp: Imprime la informacion del objeto en consola
            
            fprintf('Section designer:\n');
            disp@BaseModel(obj);
            
        end % disp function
        
    end % public methods
    
end % GenericMaterial class