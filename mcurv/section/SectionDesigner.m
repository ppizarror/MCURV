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
            % Parametros requeridos:
            %   xc              Centro de gravedad
            %   yc              Centro de gravedad
            %   b               Ancho
            %   h               Alto
            %   nx              Numero de discretizaciones en eje x
            %   ny              Numero de discretizaciones en eje y
            %   material        Material de la seccion
            %   rotation        Angulo de giro de la seccion
            %
            % Parametros opcionales:
            %   color           Color del area
            %   linewidth       Ancho de linea de la seccion
            %   transparency    Transparencia de la seccion
            %   rotation        Angulo de rotacion en grados
            
            if nargin < 8
                error('Numero de parametros incorrectos, uso: %s', ...
                    'addDiscreteRect(xc,yc,b,h,nx,ny,material,varargin)');
            end
            if ~isa(material, 'GenericMaterial')
                error('Material no es un objeto de clase GenericMaterial');
            end
            
            p = inputParser;
            p.KeepUnmatched = true;
            p.addOptional('color', material.getColor());
            p.addOptional('linewidth', 0.5);
            p.addOptional('transparency', 0.6);
            p.addOptional('rotation', 0);
            addParameter(p, 'MCURVgeometry', 'rectangle');
            parse(p, varargin{:});
            r = p.Results;
            
            if isempty(r.color)
                r.color = material.getColor();
            end
            
            % Matriz de transformacion angular
            alpha = r.rotation * pi() / 180;
            tang = [cos(alpha), -sin(alpha); sin(alpha), cos(alpha)];
            rotBox = abs([b, h] * tang); % Caja rotada
            
            obj.contTotal = obj.contTotal + 1;
            obj.contGeomPlot{obj.contTotal} = [prot(1) - rotBox(1)/2, ...
                prot(2) - rotBox(2)/2, rotBox(1), rotBox(2)];
            obj.contMat{obj.contTotal} = material;
            obj.contParams{obj.contTotal} = r;
            
            % Genera la discretizacion
            dx = b / nx;
            dy = h / ny;
            
            % Anchos rotados
            dRot = abs([dx, dy] * tang);
            
            tn = nx * ny; % Puntos totales
            px = zeros(tn, 1); % Puntos en x
            py = zeros(tn, 1); % Puntos en y
            
            y = - h / 2 + dy / 2;
            k = 1; % Guarda el numero del punto
            for i = 1:ny
                x = - b / 2 + dx / 2;
                for j = 1:nx
                    rot = [xc+x, yc+y] * tang;
                    px(k) = rot(1);
                    py(k) = rot(2);
                    x = x + dx;
                    k = k + 1;
                end
                y = y + dy;
            end
            
            % Genera discretizacion densa, mallado de la geometria
            % dx -> dx/2 y dy -> dy/2
            nxd = 2 * max(nx, ny) + 1;
            nyd = nxd;
            tnd = nxd * nyd; % Puntos totales
            pxd = zeros(tnd, 1); % Puntos en x
            pyd = zeros(tnd, 1); % Puntos en y
            
            dxd = b / (nxd - 1);
            dyd = h / (nyd - 1);
            dRotd = [dxd, dyd] * tang;
            
            y = yc - h / 2;
            k = 1; % Guarda el numero del punto
            for i = 1:nyd
                x = xc - b / 2;
                for j = 1:nxd
                    pxd(k) = x;
                    pyd(k) = y;
                    x = x + dxd;
                    k = k + 1;
                end
                y = y + dyd;
            end
            
            % Guarda la geometria
            obj.contGeom{obj.contTotal} = {px, py, ... % Lista de puntos rotados
                dRot(1), dRot(2), ... % dx,dy rotados
                tn, ... % Numero de puntos
                prot(1), prot(2), ... % Centro del objeto, rotado
                b * h, ... % Area del objeto
                rotBox(1), rotBox(2), ... % Box del objeto, rotado
                pxd, pyd, ... % Puntos del mallado denso, rotados
                tnd, ... % Numero de puntos del mallado denso
                dRotd(1), dRotd(2), ... % dx,dy denso rotado
                };
            
        end % addDiscreteRect function
        
        function addDiscreteSquare(obj, xc, yc, L, n, material, varargin)
            % addDiscreteSquare: Agrega un cuadrado discreto a la seccion,
            % con centro (xc,yc) largo l y una materialidad
            %
            % Parametros requeridos:
            %   xc              Centro de gravedad
            %   yc              Centro de gravedad
            %   L               Largo del cuadrado
            %   n               Numero de discretizaciones en eje x/y
            %   material        Materialidad de la seccion
            %
            % Parametros opcionales:
            %   color           Color del area
            %   linewidth       Ancho de linea de la seccion
            %   transparency    Transparencia de la seccion
            
            if nargin < 6
                error('Numero de parametros incorrectos, uso: %s', ...
                    'addDiscreteSquare(xc,yc,L,n,material,varargin)');
            end
            obj.addDiscreteRect(xc, yc, L, L, n, n, material, varargin{:});
            
        end % addDiscreteSquare function
        
        function addDiscreteISection(obj, xc, yc, h, bfi, bfs, ti, ts, tw, nx, ny, material, varargin)
            % addDiscreteISection: Agrega una seccion I discreta
            %
            % Parametros requeridos:
            %   xc              Centro de gravedad
            %   yc              Centro de gravedad
            %   h               Altura de la seccion
            %   bf              Ancho del ala inferior
            %   bs              Ancho del ala superior
            %   ti              Espesor del ala inferior
            %   ts              Espesor del ala superior
            %   tw              Espesor del alma
            %   nx              Discretizacion en el eje x
            %   ny              Discretizacion en el eje y
            %   material        Materialidad de la seccion
            %
            % Parametros opcionales:
            %   color           Color del area
            %   linewidth       Ancho de linea de la seccion
            %   transparency    Transparencia de la seccion
            
            if nargin < 12
                error('Numero de parametros incorrectos, uso: %s', ...
                    'addDiscreteISection(xc,yc,h,bfi,bfs,ti,ts,tw,nx,ny,material,varargin)');
            end
            
            % Calcula las particiones
            nyts = ceil(ny/h*ts);
            nyti = ceil(ny/h*ti);
            nyw = ny - nyts - nyti; % Alma
            bf = max(bfi, bfs);
            nxts = ceil(nx/bf*bfs);
            nxti = ceil(nx/bf*bfi);
            nxw = ceil(nx/bf*tw);
            
            % Agrega las alas
            obj.addDiscreteRect(xc, yc+h/2-ts/2, bfs, ts, nxts, nyts, material, varargin{:});
            obj.addDiscreteRect(xc, yc-h/2+ti/2, bfi, ti, nxti, nyti, material, varargin{:});
            obj.addDiscreteRect(xc, yc, tw, h-ti-ts, nxw, nyw, material, varargin{:});
            
        end % addDiscreteISection function
        
        function addDiscreteHSection(obj, xc, yc, h, b, tf, tw, nx, ny, material, varargin)
            % addDiscreteHSection: Agrega una seccion H discreta
            %
            % Parametros requeridos:
            %   xc              Centro de gravedad
            %   yc              Centro de gravedad
            %   h               Altura de la seccion
            %   b               Ancho del ala
            %   tf              Espesor del ala
            %   tw              Espesor del alma
            %   nx              Discretizacion en el eje x
            %   ny              Discretizacion en el eje y
            %   material        Materialidad de la seccion
            %
            % Parametros opcionales:
            %   color           Color del area
            %   linewidth       Ancho de linea de la seccion
            %   transparency    Transparencia de la seccion
            
            if nargin < 10
                error('Numero de parametros incorrectos, uso: %s', ...
                    'addDiscreteHSection(xc,yc,h,b,tf,tw,nx,ny,material,varargin)');
            end
            obj.addDiscreteISection(xc, yc, h, b, b, tf, tf, tw, nx, ny, material, varargin{:});
            
        end % addDiscreteHSection function
        
        function addFiniteArea(obj, xc, yc, area, material, varargin)
            % addFiniteArea: Agrega un area finita
            %
            % Parametros opcionales:
            %   color           Color del area
            %   plotareafactor  Factor del area en los graficos
            %   transparency    Transparencia de la seccion
            
            if nargin < 5
                error('Numero de parametros incorrectos, uso: %s', ...
                    'addFiniteArea(xc,yc,area,material,varargin)');
            end
            if ~isa(material, 'GenericMaterial')
                error('Material no es un objeto de clase GenericMaterial');
            end
            
            p = inputParser;
            p.KeepUnmatched = true;
            p.addOptional('color', material.getColor());
            p.addOptional('plotareafactor', 1);
            p.addOptional('transparency', 0);
            parse(p, varargin{:});
            r = p.Results;
            r.transparency = 1 - r.transparency;
            
            obj.singTotal = obj.singTotal + 1;
            b = sqrt(area * r.plotareafactor);
            obj.singGeomPlot{obj.singTotal} = [xc - b / 2, yc - b / 2, b, b];
            obj.singMat{obj.singTotal} = material;
            obj.singParams{obj.singTotal} = r;
            
            % Genera el mallado de la geometria
            px = [xc - b / 2, xc + b / 2, xc - b / 2, xc + b / 2];
            py = [yc - b / 2, yc - b / 2, yc + b / 2, yc + b / 2];
            
            % Guarda la geometria
            obj.singGeom{obj.singTotal} = {xc, yc, area, b / 2, b / 2, px, py, b};
            
        end % addFiniteArea function
        
        function plt = plot(obj, varargin)
            % plot: Grafica la seccion
            %
            % Parametros opcionales:
            %   center              Muestra o no el centroide
            %   centerColor         Color del centroide
            %   centerLineWidth     Ancho de linea del centroide
            %   centerMarkerSize    Tamano del marcador
            %   centroid            Muestra o no el centroide
            %   centroidColor       Color del centroide
            %   centroidLineWidth   Ancho de linea del centroide
            %   centroidMarkerSize  Tamano del marcador
            %   limMargin           Incrementa el margen
            %   showdisc            Grafica la discretizacion
            %   title               Titulo del grafico
            %   units               Unidades del modelo
            
            p = inputParser;
            p.KeepUnmatched = true;
            p.addOptional('centroid', true);
            p.addOptional('centroidColor', [1, 1, 0]);
            p.addOptional('centroidLineWidth', 2);
            p.addOptional('centroidMarkerSize', 10);
            p.addOptional('center', true);
            p.addOptional('centerColor', [0, 0, 0]);
            p.addOptional('centerLineWidth', 0.5);
            p.addOptional('centerMarkerSize', 10);
            p.addOptional('limMargin', 0.1);
            p.addOptional('showdisc', false);
            p.addOptional('title', obj.getName());
            p.addOptional('units', 'mm');
            parse(p, varargin{:});
            r = p.Results;
            
            % Genera la figura
            plt = figure();
            movegui(plt, 'center');
            set(gcf, 'name', r.title);
            hold on;
            grid on;
            grid minor;
            axis equal;
            
            % Agrega los elementos continuos
            for i = 1:obj.contTotal
                if strcmp(obj.contParams{i}.MCURVgeometry, 'rectangle')
                    rectangle('Position', obj.contGeomPlot{i}, ...
                        'FaceColor', [obj.contParams{i}.color, obj.contParams{i}.transparency], ...
                        'EdgeColor', obj.contParams{i}.color, ...
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
                            'EdgeColor', [obj.contParams{i}.color, 0.25], ...
                            'LineWidth', obj.contParams{i}.linewidth*0.5);
                        plot(px(j), py(j), '.', 'MarkerSize', 10, 'Color', ...
                            [obj.contParams{i}.color, 0.25]);
                    end
                end
            end
            
            % Agrega los elementos discretos
            for i = 1:obj.singTotal
                rectangle('Position', obj.singGeomPlot{i}, ...
                    'FaceColor', [obj.singParams{i}.color, obj.singParams{i}.transparency], ...
                    'EdgeColor', [obj.singParams{i}.color, obj.singParams{i}.transparency]);
            end
            
            % Modifica los ejes para dejar la misma escala
            xlim(get(gca, 'xlim').*(1 + r.limMargin));
            ylim(get(gca, 'ylim').*(1 + r.limMargin));
            
            % Cambia los label
            xlabel(sprintf('x (%s)', r.units));
            ylabel(sprintf('y (%s)', r.units));
            title(r.title);
            
            % Escribe el centro de gravedad
            if r.centroid
                [x, y] = obj.getCentroid();
                plot(x, y, '+', 'Color', r.centroidColor, 'MarkerSize', ...
                    r.centroidMarkerSize, 'LineWidth', r.centroidLineWidth);
            end
            
            % Escribe el centro geometrico
            if r.center
                [gx, gy] = obj.getCenter();
                plot(gx, gy, '+', 'Color', r.centerColor, 'MarkerSize', ...
                    r.centerMarkerSize, 'LineWidth', r.centerLineWidth);
            end
            
            % Finaliza el grafico
            drawnow();
            
        end % plot function
        
        function plt = plotStress(obj, e0, phix, phiy, varargin)
            % plotStress: Grafica los esfuerzos de la seccion ante un punto
            % especifico (e0,phix,phiy)
            %
            % Parametros iniciales:
            %   axisequal       Aplica mismo factores a los ejes
            %   Az              Angulo azimutal
            %   EI              Elevacion del grafico
            %   i               Numero de punto de evaluacion
            %   limMargin       Incrementa el margen
            %   normaspect      Normaliza el aspecto
            %   plot            Tipo de grafico (cont,sing)
            %   showgrid        Muestra la grilla de puntos
            %   showmesh        Muesra el meshado de la geometria
            %   unitlength      Unidad de largo
            %   unitload        Unidad de carga
            
            % Verificacion inicial
            if length(e0) ~= length(phix) || length(e0) ~= length(phiy)
                error('e0 y phix/y deben tener igual largo');
            end
            obj.updateProps();
            
            p = inputParser;
            p.KeepUnmatched = true;
            p.addOptional('axisequal', false);
            p.addOptional('Az', 0)
            p.addOptional('EI', 90);
            p.addOptional('i', 1);
            p.addOptional('limMargin', 0.1);
            p.addOptional('normaspect', false);
            p.addOptional('plot', 'cont');
            p.addOptional('showgrid', true);
            p.addOptional('showmesh', false);
            p.addOptional('unitlength', 'mm');
            p.addOptional('unitload', 'MPa');
            parse(p, varargin{:});
            r = p.Results;
            
            if ~(strcmp(r.plot, 'cont') || strcmp(r.plot, 'sing'))
                error('Errot tipo de grafico, valores posibles: %s', ...
                    'cont, sing');
            end
            
            fprintf('Generando grafico esfuerzos:\n');
            fprintf('\tTipo: %s\n', r.plot);
            
            r.i = ceil(r.i);
            if length(e0) >= r.i && r.i > 0
                e0 = e0(r.i);
                phix = phix(r.i);
                phiy = phiy(r.i);
            end
            fprintf('\tDeformaciones:\n');
            fprintf('\t\te0: %e\n', e0);
            fprintf('\t\tphix: %e\n', phix);
            fprintf('\t\tphiy: %e\n', phiy);
            
            % Calcula cargas
            p = obj.calcP(e0, phix, phiy);
            mx = obj.calcMx(e0, phix, phiy);
            my = obj.calcMy(e0, phix, phiy);
            fprintf('\tCargas:\n');
            fprintf('\t\tP axial: %.2f\n', p);
            fprintf('\t\tMx: %.2f\n', mx);
            fprintf('\t\tMy: %.2f\n', my);
            
            % Genera el titulo
            plotTitle = {sprintf('%s  -  Esfuerzos i=%d', obj.getName(), r.i), ...
                sprintf('e_0: %e  /  \\phi_x: %e  /  \\phi_y: %e', e0, phix, phiy)};
            
            if length(e0) ~= 1
                error('Solo se puede graficar un punto de e0,phix/y, no un vector');
            end
            
            % Genera la figura
            plt = figure();
            movegui(plt, 'center');
            set(gcf, 'name', 'Esfuerzos');
            hold on;
            if r.showgrid
                grid on;
                grid minor;
            end
            if r.axisequal
                axis equal;
            end
            
            % Crea funcion deformacion
            eps = @(x, y) e0 + phix * (y - obj.y0) - phiy * (x - obj.x0);
            fmeshes = {};
            
            % Mallado menor
            dxm = Inf;
            dym = Inf;
            
            % Genera el mallado de cada area continua
            if strcmp(r.plot, 'cont')
                for i = 1:obj.contTotal
                    g = obj.contGeom{i};
                    px = g{11};
                    py = g{12};
                    nt = g{13};
                    dx = g{14};
                    dy = g{15};
                    mat = obj.contMat{i};
                    
                    dxm = min(dxm, dx);
                    dym = min(dym, dy);
                    
                    mallaX = zeros(nt, 1);
                    mallaY = zeros(nt, 1);
                    vecF = zeros(nt, 1);
                    
                    for j = 1:nt
                        mallaX(j) = px(j);
                        mallaY(j) = py(j);
                        [f, ~] = mat.eval(eps(px(j), py(j)));
                        vecF(j) = f;
                    end
                    
                    [xq, yq] = meshgrid(min(mallaX):dx:max(mallaX), min(mallaY):dy:max(mallaY));
                    vq = griddata(mallaX, mallaY, vecF, xq, yq);
                    mesh(xq, yq, vq);
                    surf(xq, yq, vq);
                    
                    % Grafica la linea en cero
                    if r.showmesh
                        [xq, yq] = meshgrid(min(mallaX):dx:max(mallaX), min(mallaY):dy:max(mallaY));
                        vq = griddata(mallaX, mallaY, vecF.*0, xq, yq);
                        hold on;
                        fmesh = mesh(xq, yq, vq);
                        % alpha(fmesh1, 0.7);
                        set(fmesh, 'FaceAlpha', 0);
                        fmeshes{i} = fmesh; %#ok<*AGROW>
                    end
                end
            end
            
            % Genera el mallado de cada area singular
            if strcmp(r.plot, 'sing')
                
                % Grafica el borde de los continuos
                for i = 1:obj.contTotal
                    if strcmp(obj.contParams{i}.MCURVgeometry, 'rectangle')
                        rectangle('Position', obj.contGeomPlot{i}, ...
                            'FaceColor', [obj.contParams{i}.color, 0], ...
                            'EdgeColor', [0, 0, 0], ...
                            'LineWidth', obj.contParams{i}.linewidth);
                    end
                end
                
                % Grafica los singulares
                for i = 1:obj.singTotal
                    g = obj.singGeom{i};
                    x = g{1};
                    y = g{2};
                    px = g{6};
                    py = g{7};
                    nt = 4;
                    dd = g{8};
                    mat = obj.singMat{i};
                    
                    mallaX = zeros(nt, 1);
                    mallaY = zeros(nt, 1);
                    vecF = zeros(nt, 1);
                    
                    for j = 1:nt
                        mallaX(j) = px(j);
                        mallaY(j) = py(j);
                        % A diferencia del continuo, el discreto se evalua
                        % solo en el centro del area
                        [f, ~] = mat.eval(eps(x, y));
                        vecF(j) = f;
                    end
                    
                    [xq, yq] = meshgrid(min(mallaX):dd:max(mallaX), min(mallaY):dd:max(mallaY));
                    vq = griddata(mallaX, mallaY, vecF, xq, yq);
                    m = mesh(xq, yq, vq);
                    surf(xq, yq, vq);
                    % set(m, 'EdgeColor', [0.5, 0.5, 0.5]);
                    set(m, 'EdgeAlpha', 0);
                end
            end
            
            if r.showmesh && strcmp(r.plot, 'cont')
                for i = 1:1:obj.contTotal
                    set(fmeshes{i}, 'EdgeColor', [0.5, 0.5, 0.5]);
                    set(fmeshes{i}, 'EdgeAlpha', .50);
                end
            end
            
            % Cambia el esquema de colores
            colormap(flipud(jet));
            
            % Agrega el colorbar
            h = colorbar('Location', 'eastoutside');
            shading interp;
            
            % Cambia los label
            xlabel(sprintf('x (%s)', r.unitlength));
            ylabel(sprintf('y (%s)', r.unitlength));
            ylabel(h, sprintf('\\sigma (%s)', r.unitload));
            view(r.Az, r.EI);
            title(plotTitle);
            
            % Modifica los ejes para dejar la misma escala
            xlim(get(gca, 'xlim').*(1 + r.limMargin));
            ylim(get(gca, 'ylim').*(1 + r.limMargin));
            
            % Aplica factor de escala en x/y
            if r.normaspect && ~r.axisequal
                h = get(gca, 'DataAspectRatio');
                [sx, sy] = obj.getSize();
                set(gca, 'DataAspectRatio', [h(1), h(2) * sx / sy, h(3)]);
            end
            
            % Actualiza el grafico
            drawnow();
            dispMCURV();
            
        end % plotStress function
        
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
            
            % Calcula el centroide
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
            
            % Agrega objetos continuos
            for j = 1:obj.contTotal
                
                g = obj.contGeom{j};
                px = g{1};
                py = g{2};
                mat = obj.contMat{j};
                dd = g{3} * g{4};
                nt = g{5};
                for i = 1:nt % Calcula la integral
                    
                    e_i = eps(px(i), py(i));
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
                
                e_i = eps(px, py);
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
            
            % Agrega los objetos continuos
            mx = 0;
            for j = 1:obj.contTotal
                g = obj.contGeom{j};
                px = g{1};
                py = g{2};
                mat = obj.contMat{j};
                dd = g{3} * g{4};
                nt = g{5};
                for i = 1:nt % Calcula la integral
                    e_i = eps(px(i), py(i));
                    [fc, ~] = mat.eval(e_i);
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
                e_i = eps(px, py);
                [fc, ~] = mat.eval(e_i);
                mx = mx + fc * (py - obj.y0) * area;
            end
            
        end % calcMx function
        
        function my = calcMy(obj, e0, phix, phiy)
            % calcMy: Calcula el momento con respecto al eje y
            
            % Crea funcion deformacion
            eps = @(x, y) e0 + phix * (y - obj.y0) - phiy * (x - obj.x0);
            
            % Agrega los objetos continuos
            my = 0;
            for j = 1:obj.contTotal
                g = obj.contGeom{j};
                px = g{1};
                py = g{2};
                mat = obj.contMat{j};
                dd = g{3} * g{4};
                nt = g{5};
                for i = 1:nt % Calcula la integral
                    e_i = eps(px(i), py(i));
                    [fc, ~] = mat.eval(e_i);
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
                e_i = eps(px, py);
                [fc, ~] = mat.eval(e_i);
                my = my - fc * (px - obj.x0) * area;
            end
            
        end % calcMy function
        
        function p = calcP(obj, e0, phix, phiy)
            % calcP: Calcula la carga axial
            
            % Crea funcion deformacion
            eps = @(x, y) e0 + phix * (y - obj.y0) - phiy * (x - obj.x0);
            
            % Agrega los objetos continuos
            p = 0;
            for j = 1:obj.contTotal
                g = obj.contGeom{j};
                px = g{1};
                py = g{2};
                mat = obj.contMat{j};
                dd = g{3} * g{4};
                nt = g{5};
                for i = 1:nt % Calcula la integral
                    e_i = eps(px(i), py(i));
                    [fc, ~] = mat.eval(e_i);
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
                e_i = eps(px, py);
                [fc, ~] = mat.eval(e_i);
                p = p + fc * area;
            end
            
        end % calcP function
        
        function [xmin, xmax, ymin, ymax] = getLimits(obj)
            % getLimits: Calcula los limites de la seccion
            
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
            
        end % getLimits function
        
        function [x, y] = getCenter(obj)
            % calcGeometricCenter: Calcula el centro del limite
            
            [xmin, xmax, ymin, ymax] = obj.getLimits();
            x = (xmax + xmin) / 2;
            y = (ymax + ymin) / 2;
            
        end % calcGeometricCenter function
        
        function [sx, sy] = getSize(obj)
            % getSize: Calcula el porte de la seccion
            
            [xmin, xmax, ymin, ymax] = obj.getLimits();
            sx = abs(xmax-xmin);
            sy = abs(ymax-ymin);
            
        end
        
        function disp(obj)
            % disp: Imprime la informacion del objeto en consola
            
            fprintf('Section designer:\n');
            disp@BaseModel(obj);
            
            [cx, cy] = obj.getCentroid();
            [gx, gy] = obj.getCenter();
            [xmin, xmax, ymin, ymax] = obj.getLimits();
            [sx, sy] = obj.getSize();
            
            fprintf('\tCentroide: %.2f, %.2f\n', cx, cy);
            fprintf('\tCentro geometrico: %.2f, %.2f\n', gx, gy);
            fprintf('\tArea: %.2f\n', obj.getArea());
            fprintf('\tAncho: %.2f\n', sx);
            fprintf('\tAlto: %.2f\n', sy);
            fprintf('\tNumero de elementos: %d\n\t\tContinuos: %d\n\t\tFinitos: %d\n', ...
                obj.contTotal+obj.singTotal, obj.contTotal, obj.singTotal);
            fprintf('\tLimites de la seccion:\n\t\tx: (%.2f, %.2f)\n\t\ty: (%.2f, %.2f)\n', ...
                xmin, xmax, ymin, ymax);
            
            dispMCURV();
            
        end % disp function
        
    end % public methods
    
end % SectionDesigner class