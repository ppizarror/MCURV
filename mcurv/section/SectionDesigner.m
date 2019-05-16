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
        x0 % Guarda la posicion en x del centroide
        y0 % Guarda la posicion en y del centroide
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
            
            % Otros
            obj.x0 = 0;
            obj.y0 = 0;
            
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
            obj.contGeom{obj.contTotal} = {px, py, dx, dy, tn, xc, yc, b * h, b, h};
            
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
            r.transparency = 1 - r.transparency;
            
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
            xlim(get(gca, 'xlim').*(1 + r.limMargin));
            ylim(get(gca, 'ylim').*(1 + r.limMargin));
            
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
                xid = xid + g{6} * g{8};
                yid = yid + g{7} * g{8};
                at = at + g{8};
            end
            
            for i = 1:obj.singTotal
                g = obj.singGeom{i};
                xid = xid + g{1} * g{3};
                yid = yid + g{2} * g{3};
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
        
        function updateProps(obj)
            % updateProps: Actualiza las propiedades del modelo previo
            % analisis
            
            [x, y] = obj.getCentroid();
            obj.x0 = x;
            obj.y0 = y;
            
        end % updateProps function
        
        function jac = calcJac(obj, e0, phix, phiy)
            % calcJac: Calcula el jacobiano de la seccion
            
            % Crea funcion deformacion
            eps = @(x, y) e0 + phix * (y - obj.y0) - phiy * (x - obj.x0);
            
            % Valores del jacobiano
            aP_ae0 = 0;
            aP_aphix = 0;
            aP_aphiy = 0;
            aMx_aphix = 0;
            aMx_aphiy = 0;
            aMy_aphiy = 0;
            
            % Calcula las integrales
            for j = 1:obj.contTotal
                
                g = obj.contGeom{j};
                px = g{1};
                py = g{2};
                mat = obj.contMat{j};
                dd = g{3} * g{4};
                nt = g{5};
                for i = 1:nt % Avanza en los puntos continuos
                    
                    % Calcula la deformacion
                    e_i = eps(px(i), py(i));
                    
                    % Calcula la rigidez tangente
                    [~, Ec] = mat.eval(e_i);
                    
                    % Calcula los jacobianos
                    aP_ae0 = aP_ae0 + Ec * dd; % aP/ae0
                    aP_aphix = aP_aphix + Ec * (py(i) - obj.y0) * dd; % aP/aphix
                    aP_aphiy = aP_aphiy - Ec * (px(i) - obj.x0) * dd; % aP/aphiy
                    aMx_aphix = aMx_aphix + Ec * ((py(i) - obj.y0)^2) * dd; % aMx/aphix
                    aMx_aphiy = aMx_aphiy - Ec * (py(i) - obj.y0) * (px(i) - obj.x0) * dd; % aMx/aphiy
                    aMy_aphiy = aMy_aphiy + Ec * ((px(i) - obj.x0)^2) * dd; % aMy/aphiy
                    
                end
            end
            
            % Agrega objetos puntuales
            for j = 1:obj.singTotal
                
                g = obj.singGeom{j};
                px = g{1};
                py = g{2};
                mat = obj.singMat{j};
                area = g{3};
                
                % Calcula la deformacion
                e_i = eps(px, py);
                
                % Calcula la rigidez tangente del suelo
                [~, Ec] = mat.eval(e_i);
                
                % Calcula los jacobianos
                aP_ae0 = aP_ae0 + Ec * area; % aP/ae0
                aP_aphix = aP_aphix + Ec * (py - obj.y0) * area; % aP/aphix
                aP_aphiy = aP_aphiy - Ec * (px - obj.x0) * area; % aP/aphiy
                aMx_aphix = aMx_aphix + Ec * ((py - obj.y0)^2) * area; % aMx/aphix
                aMx_aphiy = aMx_aphiy - Ec * (py - obj.y0) * (px - obj.x0) * area; % aMx/aphiy
                aMy_aphiy = aMy_aphiy + Ec * ((px - obj.x0)^2) * area; % aMy/aphiy
            end
            
            % Asigna los valores iguales
            aMx_ae0 = aP_aphix;
            aMy_ae0 = aP_aphiy;
            aMy_aphix = aMx_aphiy;
            
            % Genera el jacobiano
            jac = [[aP_ae0, aP_aphix, aP_aphiy]; ...
                [aMx_ae0, aMx_aphix, aMx_aphiy]; ...
                [aMy_ae0, aMy_aphix, aMy_aphiy]];
            
        end % calcJac function
        
        function mx = calcMx(obj, e0, phix, phiy)
            % calcMx: Calcula el momento con respecto al eje x
            
            % Crea funcion deformacion
            eps = @(x, y) e0 + phix * (y - obj.y0) - phiy * (x - obj.x0);
            
            % Calcula la integral para objetos continuos
            mx = 0;
            for j = 1:obj.contTotal
                g = obj.contGeom{j};
                px = g{1};
                py = g{2};
                mat = obj.contMat{j};
                dd = g{3} * g{4};
                nt = g{5};
                
                for i = 1:nt % Avanza en los puntos continuos
                    % Calcula la deformacion
                    e_i = eps(px(i), py(i));
                    
                    % Calcula la tension
                    [fc, ~] = mat.eval(e_i);
                    
                    % Calcula el momento
                    mx = mx + fc * (py(i) - obj.y0) * dd;
                end
            end
            
            % Agrega los objetos singulares
            for j = 1:obj.singTotal
                g = obj.singGeom{j};
                px = g{1};
                py = g{2};
                mat = obj.singMat{j};
                area = g{3};
                
                % Calcula la deformacion
                e_i = eps(px, py);
                
                % Calcula la tension
                [fc, ~] = mat.eval(e_i);
                
                % Suma el momento
                mx = mx + fc * (py - obj.y0) * area;
            end
            
        end % calcMx function
        
        function my = calcMy(obj, e0, phix, phiy)
            % calcMy: Calcula el momento con respecto al eje y
            
            % Crea funcion deformacion
            eps = @(x, y) e0 + phix * (y - obj.y0) - phiy * (x - obj.x0);
            
            % Calcula la integral para objetos continuos
            my = 0;
            for j = 1:obj.contTotal
                g = obj.contGeom{j};
                px = g{1};
                py = g{2};
                mat = obj.contMat{j};
                dd = g{3} * g{4};
                nt = g{5};
                
                for i = 1:nt % Avanza en los puntos continuos
                    % Calcula la deformacion
                    e_i = eps(px(i), py(i));
                    
                    % Calcula la tension
                    [fc, ~] = mat.eval(e_i);
                    
                    % Calcula el momento
                    my = my - fc * (px(i) - obj.x0) * dd;
                end
            end
            
            % Agrega los objetos singulares
            for j = 1:obj.singTotal
                g = obj.singGeom{j};
                px = g{1};
                py = g{2};
                mat = obj.singMat{j};
                area = g{3};
                
                % Calcula la deformacion
                e_i = eps(px, py);
                
                % Calcula la tension
                [fc, ~] = mat.eval(e_i);
                
                % Suma el momento
                my = my - fc * (px - obj.x0) * area;
            end
            
        end % calcMy function
        
        function p = calcP(obj, e0, phix, phiy)
            % calcP: Calcula la carga axial
            
            % Crea funcion deformacion
            eps = @(x, y) e0 + phix * (y - obj.y0) - phiy * (x - obj.x0);
            
            % Calcula la integral para objetos continuos
            p = 0;
            for j = 1:obj.contTotal
                g = obj.contGeom{j};
                px = g{1};
                py = g{2};
                mat = obj.contMat{j};
                dd = g{3} * g{4};
                nt = g{5};
                
                for i = 1:nt % Avanza en los puntos continuos
                    % Calcula la deformacion
                    e_i = eps(px(i), py(i));
                    
                    % Calcula la tension
                    [fc, ~] = mat.eval(e_i);
                    
                    % Calcula el momento
                    p = p + fc * dd;
                end
            end
            
            % Agrega los objetos singulares
            for j = 1:obj.singTotal
                g = obj.singGeom{j};
                px = g{1};
                py = g{2};
                mat = obj.singMat{j};
                area = g{3};
                
                % Calcula la deformacion
                e_i = eps(px, py);
                
                % Calcula la tension
                [fc, ~] = mat.eval(e_i);
                
                % Suma el momento
                p = p + fc * area;
            end
            
        end % calcP function
        
        function [xmin, xmax, ymin, ymax] = calcLimits(obj)
            % calcLimits: Calcula los limites de la seccion
            
            xmin = Inf;
            xmax = -Inf;
            ymin = Inf;
            ymax = -Inf;
            
            % Recorre los objetos continuos
            for j = 1:obj.contTotal
                g = obj.contGeom{j};
                xc = g{6};
                yc = g{7};
                b = g{9};
                h = g{10};
                xmin = min(xmin, xc-b/2);
                xmax = max(xmax, xc+b/2);
                ymin = min(ymin, yc-h/2);
                ymax = max(ymax, yc+h/2);
            end
            
            % Agrega objetos puntuales
            for j = 1:obj.singTotal
                g = obj.singGeom{j};
                pjx = g{1};
                pjy = g{2};
                xmin = min(xmin, pjx);
                xmax = max(xmax, pjx);
                ymin = min(ymin, pjy);
                ymax = max(ymax, pjy);
            end
            
        end % calcLimits function
        
        function disp(obj)
            % disp: Imprime la informacion del objeto en consola
            
            fprintf('Section designer:\n');
            disp@BaseModel(obj);
            
            [cx, cy] = obj.getCentroid();
            [xmin, xmax, ymin, ymax] = obj.calcLimits();
            
            fprintf('\tCentroide: %.2f, %.2f\n', cx, cy);
            fprintf('\tArea: %.2f\n', obj.getArea());
            fprintf('\tAncho: %.2f\n', abs(xmax-xmin));
            fprintf('\tAlto: %.2f\n', abs(ymax-ymin));
            fprintf('\tNumero de elementos: %d\n\t\tContinuos: %d\n\t\tFinitos: %d\n', ...
                obj.contTotal+obj.singTotal, obj.contTotal, obj.singTotal);
            fprintf('\tLimites de la seccion:\n\t\tx: (%.2f, %.2f)\n\t\ty: (%.2f, %.2f)\n', ...
                xmin, xmax, ymin, ymax);
            
        end % disp function
        
    end % public methods
    
end % SectionDesigner class