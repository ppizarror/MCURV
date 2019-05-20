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
                matName = '';
            end
            obj = obj@BaseModel(matName);
            
            % Genera las bases
            obj.contGeom = {};
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
            %
            % Parametros opcionales:
            %   color           Color del area
            %   linewidth       Ancho de linea de la seccion
            %   rotation        Angulo de rotacion en grados
            %   translatex      Punto de translacion del eje x
            %   translatey      Punto de translacion del eje y
            %   transparency    Transparencia de la seccion
            
            if nargin < 8
                error('Numero de parametros incorrectos, uso: %s', ...
                    'addDiscreteRect(xc,yc,b,h,nx,ny,material,varargin)');
            end
            if ~isa(material, 'GenericMaterial')
                error('Material no es un objeto de clase GenericMaterial');
            end
            
            if nx == 0 || ny == 0
                error('La discretizacion del elemento no puede ser nula');
            end
            
            p = inputParser;
            p.KeepUnmatched = true;
            p.addOptional('color', material.getColor());
            p.addOptional('linewidth', 0.5);
            p.addOptional('rotation', 0);
            p.addOptional('translatex', 0);
            p.addOptional('translatey', 0);
            p.addOptional('transparency', 0.6);
            parse(p, varargin{:});
            r = p.Results;
            r.transparency = 1 - r.transparency;
            
            nx = ceil(nx);
            ny = ceil(ny);
            
            if isempty(r.color)
                r.color = material.getColor();
            end
            
            tx = r.translatex;
            ty = r.translatey;
            
            % Matriz de transformacion angular
            alpha = r.rotation * pi() / 180;
            tang = [cos(alpha), sin(alpha); -sin(alpha), cos(alpha)];
            rotBox = abs([b, h]*tang); % Caja rotada
            prot = [xc, yc] * tang; % Punto rotado
            
            xpatch = [(xc - b / 2), (xc + b / 2), (xc + b / 2), (xc - b / 2)];
            ypatch = [(yc - h / 2), (yc - h / 2), (yc + h / 2), (yc + h / 2)];
            
            % Rota los puntos del parche
            xpatchR = cos(alpha) * xpatch - sin(alpha) * ypatch;
            ypatchR = sin(alpha) * xpatch + cos(alpha) * ypatch;
            zpatchR = zeros(1, 4);
            
            % Suma la translacion
            xpatchR = xpatchR + [tx, tx, tx, tx];
            ypatchR = ypatchR + [ty, ty, ty, ty];
            
            obj.contTotal = obj.contTotal + 1;
            obj.contMat{obj.contTotal} = material;
            obj.contParams{obj.contTotal} = r;
            
            % Genera la discretizacion
            dx = b / nx;
            dy = h / ny;
            
            % Anchos rotados
            dRot = abs([dx, dy]*tang);
            
            tn = nx * ny; % Puntos totales
            px = zeros(tn, 1); % Puntos en x
            py = zeros(tn, 1); % Puntos en y
            
            y = -h / 2 + dy / 2;
            k = 1; % Guarda el numero del punto
            
            % Parches discretizados
            xpatchD = {};
            ypatchD = {};
            
            for i = 1:ny
                x = -b / 2 + dx / 2;
                for j = 1:nx
                    rot = [xc + x, yc + y] * tang;
                    px(k) = rot(1) + tx;
                    py(k) = rot(2) + ty;
                    
                    % Crea el parche de la discretizacion
                    xpatch = [(xc + x - dx / 2), (xc + x + dx / 2), (xc + x + dx / 2), (xc + x - dx / 2)];
                    ypatch = [(yc + y - dy / 2), (yc + y - dy / 2), (yc + y + dy / 2), (yc + y + dy / 2)];
                    
                    % Rota los puntos del parche
                    xpatchD{k} = cos(alpha) * xpatch - sin(alpha) * ypatch;
                    ypatchD{k} = sin(alpha) * xpatch + cos(alpha) * ypatch;
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
            
            y = -h / 2;
            k = 1; % Guarda el numero del punto
            for i = 1:nyd
                x = -b / 2;
                for j = 1:nxd
                    rot = [xc + x, yc + y] * tang;
                    pxd(k) = rot(1) + tx;
                    pyd(k) = rot(2) + ty;
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
                alpha, ... % Angulo de rotacion
                xpatchR, ypatchR, zpatchR, ... % Posicion del parche
                xpatchD, ypatchD; ... % Posicion del parche discretizado
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
        
        function addDiscreteISection(obj, xc, yc, bi, bs, h, ti, ts, tw, nx, ny, material, varargin)
            % addDiscreteISection: Agrega una seccion I discreta
            %
            % Parametros requeridos:
            %   xc              Centro de gravedad
            %   yc              Centro de gravedad
            %   bi              Ancho del ala inferior
            %   bs              Ancho del ala superior
            %   h               Altura de la seccion
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
            %   rotation        Angulo de rotacion en grados
            %   translatex      Punto de translacion del eje x
            %   translatey      Punto de translacion del eje y
            %   transparency    Transparencia de la seccion
            
            if nargin < 12
                error('Numero de parametros incorrectos, uso: %s', ...
                    'addDiscreteISection(xc,yc,bi,bs,h,ti,ts,tw,nx,ny,material,varargin)');
            end
            
            % Calcula las particiones
            nyts = max(1, ceil(ny/h*ts));
            nyti = max(1, ceil(ny/h*ti));
            nyw = max(1, ny-nyts-nyti); % Alma
            bf = max(bi, bs);
            nxts = max(1, ceil(nx/bf*bs));
            nxti = max(1, ceil(nx/bf*bi));
            nxw = max(1, ceil(nx/bf*tw));
            
            % Agrega las alas
            obj.addDiscreteRect(xc, yc+h/2-ts/2, bs, ts, nxts, nyts, material, varargin{:});
            obj.addDiscreteRect(xc, yc-h/2+ti/2, bi, ti, nxti, nyti, material, varargin{:});
            obj.addDiscreteRect(xc, yc, tw, h-ti-ts, nxw, nyw, material, varargin{:});
            
        end % addDiscreteISection function
        
        function addDiscreteHSection(obj, xc, yc, b, h, tf, tw, nx, ny, material, varargin)
            % addDiscreteHSection: Agrega una seccion H discreta
            %
            % Parametros requeridos:
            %   xc              Centro de gravedad
            %   yc              Centro de gravedad
            %   b               Ancho del ala
            %   h               Altura de la seccion
            %   tf              Espesor del ala
            %   tw              Espesor del alma
            %   nx              Discretizacion en el eje x
            %   ny              Discretizacion en el eje y
            %   material        Materialidad de la seccion
            %
            % Parametros opcionales:
            %   color           Color del area
            %   linewidth       Ancho de linea de la seccion
            %   rotation        Angulo de rotacion en grados
            %   translatex      Punto de translacion del eje x
            %   translatey      Punto de translacion del eje y
            %   transparency    Transparencia de la seccion
            
            if nargin < 10
                error('Numero de parametros incorrectos, uso: %s', ...
                    'addDiscreteHSection(xc,yc,b,h,tf,tw,nx,ny,material,varargin)');
            end
            obj.addDiscreteISection(xc, yc, b, b, h, tf, tf, tw, nx, ny, material, varargin{:});
            
        end % addDiscreteHSection function
        
        function addDiscreteChannel(obj, xc, yc, b, h, tf, tw, nx, ny, material, varargin)
            % addDiscreteChannel: Agrega una seccion canal discreta
            %
            % Parametros requeridos:
            %   xc          Centro de gravedad en x
            %   yc          Centro de gravedad en y
            %   b           Ancho del canal
            %   h           Altura del canal
            %   tf          Ancho del ala
            %   tw          Ancho del alma
            %   nx          Discretizacion en x
            %   ny          Discretizacion en y
            %   material    Materialidad de la seccion
            %
            % Parametros opcionales:
            %   color           Color del area
            %   linewidth       Ancho de linea de la seccion
            %   rotation        Angulo de rotacion en grados
            %   translatex      Punto de translacion del eje x
            %   translatey      Punto de translacion del eje y
            %   transparency    Transparencia de la seccion
            
            if nargin < 10
                error('Numero de parametros incorrectos, uso: %s', ...
                    'addDiscreteChannel(obj,xc,yc,b,h,tf,tw,nx,ny,material,varargin)');
            end
            
            % Calcula discretizacion del ala
            nfy = max(1, ceil(ny/h*tf));
            nwy = max(1, ny-2*nfy);
            nwx = max(1, nx/b*tw);
            
            % Agrega elementos
            obj.addDiscreteRect(xc-b/2+tw/2, yc, tw, h-2*tf, nwx, nwy, material, varargin{:});
            obj.addDiscreteRect(xc, yc-h/2+tf/2, b, tf, nx, nfy, material, varargin{:});
            obj.addDiscreteRect(xc, yc+h/2-tf/2, b, tf, nx, nfy, material, varargin{:});
            
        end % addDiscreteChannel function
        
        function addDiscreteBoxChannel(obj, xc, yc, b, h, t, nx, ny, material, varargin)
            % addDiscreteBoxChannel: Agrega una seccion canal rectangular
            % discreta
            %
            % Parametros requeridos:
            %   xc          Centro de gravedad en x
            %   yc          Centro de gravedad en y
            %   b           Ancho del canal
            %   h           Altura del canal
            %   tf          Ancho del ala
            %   tw          Ancho del alma
            %   nx          Discretizacion en x
            %   ny          Discretizacion en y
            %   material    Materialidad de la seccion
            %
            % Parametros opcionales:
            %   color           Color del area
            %   linewidth       Ancho de linea de la seccion
            %   rotation        Angulo de rotacion en grados
            %   translatex      Punto de translacion del eje x
            %   translatey      Punto de translacion del eje y
            %   transparency    Transparencia de la seccion
            
            if nargin < 9
                error('Numero de parametros incorrectos, uso: %s', ...
                    'addDiscreteBoxChannel(xc,yc,b,h,t,nx,ny,material,varargin)');
            end
            
            % Calcula discretizacion del ala
            nty = max(1, ceil(ny/h*t));
            ntx = max(1, ceil(nx/b*t));
            nte = max(nty, ntx); % Espesor
            
            ntex = min(nx, nte);
            ntey = min(ny, nte);
            
            % Agrega elementos
            obj.addDiscreteRect(xc-b/2+t/2, yc, t, h-2*t, ntex, ny-2*nte, material, varargin{:});
            obj.addDiscreteRect(xc+b/2-t/2, yc, t, h-2*t, ntex, ny-2*nte, material, varargin{:});
            obj.addDiscreteRect(xc, yc+h/2-t/2, b, t, nx, ntey, material, varargin{:});
            obj.addDiscreteRect(xc, yc-h/2+t/2, b, t, nx, ntey, material, varargin{:});
            
        end % addDiscreteBoxChannel function
        
        function addDiscreteSquareChannel(obj, xc, yc, L, t, n, material, varargin)
            % addDiscreteSquareChannel: Agrega una seccion canal cuadrada
            % discreta
            %
            % Parametros requeridos:
            %   xc          Centro de gravedad en x
            %   yc          Centro de gravedad en y
            %   L           Largo de la caja
            %   t           Espesor
            %   n           Discretizacion en x/y
            %   material    Materialidad de la seccion
            %
            % Parametros opcionales:
            %   color           Color del area
            %   linewidth       Ancho de linea de la seccion
            %   rotation        Angulo de rotacion en grados
            %   translatex      Punto de translacion del eje x
            %   translatey      Punto de translacion del eje y
            %   transparency    Transparencia de la seccion
            
            if nargin < 7
                error('Numero de parametros incorrectos, uso: %s', ...
                    'addDiscreteSquareChannel(xc,yc,L,t,n,material,varargin)');
            end
            obj.addDiscreteBoxChannel(xc, yc, L, L, t, n, n, material, varargin{:});
            
        end % addDiscreteSquareChannel function
        
        function addFiniteArea(obj, xc, yc, area, material, varargin)
            % addFiniteArea: Agrega un area finita
            %
            % Parametros requeridos:
            %   xc              Posicion del centro del area en x
            %   yc              Posicion del centro del area en y
            %   area            Area
            %   material        Materialidad de la seccion
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
            %   axis                Escribe los ejes
            %   axisSize            Largo de los ejes
            %   center              Muestra o no el centroide
            %   centerColor         Color del centroide
            %   centerLineWidth     Ancho de linea del centroide
            %   centerMarkerSize    Tamano del marcador
            %   centroid            Muestra o no el centroide
            %   centroidColor       Color del centroide
            %   centroidLineWidth   Ancho de linea del centroide
            %   centroidMarkerSize  Tamano del marcador
            %   contCenter          Muestra el centro de los e. continuos
            %   limMargin           Incrementa el margen
            %   showdisc            Grafica la discretizacion
            %   title               Titulo del grafico
            %   units               Unidades del modelo
            
            p = inputParser;
            p.KeepUnmatched = true;
            p.addOptional('axis', true);
            p.addOptional('axisSize', 0.15);
            p.addOptional('centroid', true);
            p.addOptional('centroidColor', [1, 1, 0]);
            p.addOptional('centroidLineWidth', 2);
            p.addOptional('centroidMarkerSize', 10);
            p.addOptional('center', true);
            p.addOptional('centerColor', [0, 0, 0]);
            p.addOptional('centerLineWidth', 2);
            p.addOptional('centerMarkerSize', 10);
            p.addOptional('contCenter', false);
            p.addOptional('limMargin', 0);
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
                g = obj.contGeom{i};
                patchx = g{17};
                patchy = g{18};
                patchz = g{19};
                patch(patchx, patchy, patchz, ...
                    'FaceColor', obj.contParams{i}.color, ...
                    'EdgeColor', obj.contParams{i}.color, ...
                    'LineWidth', obj.contParams{i}.linewidth*0.5, ...
                    'FaceAlpha', obj.contParams{i}.transparency);
            end
            
            % Grafica la discretizacion de los elementos continuos
            if r.showdisc
                for i = 1:obj.contTotal
                    g = obj.contGeom{i};
                    px = g{1};
                    py = g{2};
                    tn = g{5};
                    patchx = g{20};
                    patchy = g{21};
                    patchz = g{19};
                    for j = 1:tn
                        patch(patchx{j}, patchy{j}, patchz, ...
                            'FaceColor', obj.contParams{i}.color, ...
                            'EdgeColor', obj.contParams{i}.color, ...
                            'LineWidth', obj.contParams{i}.linewidth*0.5, ...
                            'FaceAlpha', 0);
                        if r.contCenter
                            plot(px(j), py(j), '.', 'MarkerSize', 10, 'Color', ...
                                [obj.contParams{i}.color, 0.25]);
                        end
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
            plotLimsMargin(r.limMargin);
            
            % Cambia los label
            xlabel(sprintf('x (%s)', r.units));
            ylabel(sprintf('y (%s)', r.units));
            title(r.title);
            
            % Realiza algunos calculos
            [gx, gy] = obj.getCenter();
            [xc, yc] = obj.getCentroid();
            [sx, sy] = getSize(obj);
            
            % Escribe el centro de gravedad
            if r.centroid
                plot(xc, yc, '+', 'Color', r.centroidColor, 'MarkerSize', ...
                    r.centroidMarkerSize, 'LineWidth', r.centroidLineWidth);
            end
            
            % Escribe el centro geometrico
            if r.center
                plot(gx, gy, '+', 'Color', r.centerColor, 'MarkerSize', ...
                    r.centerMarkerSize, 'LineWidth', r.centerLineWidth);
            end
            
            % Escribe los ejes
            if r.axis
                
                % Eje x
                lx = r.axisSize * sx;
                p1 = [gx, gy];
                p2 = [gx + lx, gy];
                dp = p2 - p1;
                quiver(p1(1), p1(2), dp(1), dp(2), 0, 'Color', [1, 0, 0]);
                text(p2(1)-0.1*lx, p2(2)+0.15*lx, 'x', 'Color', [1, 0, 0]);
                
                % Eje y
                ly = r.axisSize * sy;
                p1 = [gx, gy];
                p2 = [gx, gy + ly];
                dp = p2 - p1;
                quiver(p1(1), p1(2), dp(1), dp(2), 0, 'Color', [0, 1, 0]);
                text(p2(1)+0.1*ly, p2(2), 'y', 'Color', [0, 1, 0]);
                
            end
            
            % Finaliza el grafico
            drawnow();
            
        end % plot function
        
        function plt = plotStress(obj, e0, phix, phiy, varargin)
            % plotStress: Grafica los esfuerzos de la seccion ante un punto
            % especifico (e0,phix,phiy)
            %
            % Parametros requeridos:
            %   e0          Valor de la deformacion con respecto al centroide
            %   phix        Curvatura en x
            %   phiy        Curvatura en y
            %
            % Parametros iniciales:
            %   axisequal       Aplica mismo factores a los ejes
            %   Az              Angulo azimutal
            %   EI              Elevacion del grafico
            %   i               Numero de punto de evaluacion
            %   limMargin       Incrementa el margen
            %   mfactor         Factor momento
            %   munits          Unidad de momento
            %   normaspect      Normaliza el aspecto
            %   pfactor         Factor de carga axial
            %   plot            Tipo de grafico (cont,sing)
            %   punits          Unidad de carga axial
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
            p.addOptional('limMargin', 0);
            p.addOptional('mfactor', 1);
            p.addOptional('munits', 'kN*m');
            p.addOptional('normaspect', false);
            p.addOptional('pfactor', 1);
            p.addOptional('plot', 'cont');
            p.addOptional('punits', 'kN');
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
            fprintf('\t\tP axial: %.2f %s\n', p*r.pfactor, r.punits);
            fprintf('\t\tMx: %.2f %s\n', mx*r.mfactor, r.munits);
            fprintf('\t\tMy: %.2f %s\n', my*r.mfactor, r.munits);
            
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
                    g = obj.contGeom{i};
                    patchx = g{17};
                    patchy = g{18};
                    patchz = g{19};
                    patch(patchx, patchy, patchz, ...
                        'FaceColor', obj.contParams{i}.color, ...
                        'EdgeColor', [0, 0, 0], ...
                        'LineWidth', obj.contParams{i}.linewidth*0.5, ...
                        'FaceAlpha', 0);
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
            t = get(h, 'Limits');
            T = linspace(t(1), t(2), 5);
            set(h, 'Ticks', T);
            TL = arrayfun(@(x) sprintf('%.2f', x), T, 'un', 0);
            set(h, 'TickLabels', TL);
            shading interp;
            
            % Cambia los label
            xlabel(sprintf('x (%s)', r.unitlength));
            ylabel(sprintf('y (%s)', r.unitlength));
            ylabel(h, sprintf('\\sigma (%s)', r.unitload));
            view(r.Az, r.EI);
            title(plotTitle);
            
            % Modifica los ejes para dejar la misma escala
            plotLimsMargin(r.limMargin);
            
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
        
        function [area, areacont, areasing] = getArea(obj)
            % getArea: Calcula el area total
            
            area = 0; % Area total
            for i = 1:obj.contTotal
                g = obj.contGeom{i};
                area = area + g{8};
            end
            areacont = area;
            for i = 1:obj.singTotal
                g = obj.singGeom{i};
                area = area + g{3};
            end
            areasing = area - areacont;
            
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
            %
            % Parametros requeridos:
            %   e0          Valor de la deformacion con respecto al centroide
            %   phix        Curvatura en x
            %   phiy        Curvatura en y
            
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
        
        function mx = calcMx(obj, e0, phix, phiy, pext, ppos)
            % calcMx: Calcula el momento con respecto al eje x
            %
            % Parametros requeridos:
            %   e0          Valor de la deformacion con respecto al centroide
            %   phix        Curvatura en x
            %   phiy        Curvatura en y
            %   pext        Carga externa
            %   ppos        Posicion de la carga externa
            
            if ~exist('pext', 'var')
                pext = 0;
                ppos = [0, 0];
            end
            
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
            
            % Agrega la carga externa
            mx = mx - pext * (ppos(2) - obj.y0);
            
        end % calcMx function
        
        function my = calcMy(obj, e0, phix, phiy, pext, ppos)
            % calcMy: Calcula el momento con respecto al eje y
            %
            % Parametros requeridos:
            %   e0          Valor de la deformacion con respecto al centroide
            %   phix        Curvatura en x
            %   phiy        Curvatura en y
            %   pext        Carga externa
            %   ppos        Posicion de la carga externa
            
            if ~exist('pext', 'var')
                pext = 0;
                ppos = [0, 0];
            end
            
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
            
            % Agrega la carga externa
            my = my - pext * (ppos(1) - obj.x0);
            
        end % calcMy function
        
        function p = calcP(obj, e0, phix, phiy)
            % calcP: Calcula la carga axial interna
            %
            % Parametros requeridos:
            %   e0          Valor de la deformacion con respecto al centroide
            %   phix        Curvatura en x
            %   phiy        Curvatura en y
            
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
            % getCenter: Calcula el centro del limite
            
            [xmin, xmax, ymin, ymax] = obj.getLimits();
            x = (xmax + xmin) / 2;
            y = (ymax + ymin) / 2;
            
        end % getCenter function
        
        function [sx, sy] = getSize(obj)
            % getSize: Calcula el porte de la seccion
            
            [xmin, xmax, ymin, ymax] = obj.getLimits();
            sx = abs(xmax-xmin);
            sy = abs(ymax-ymin);
            
        end % getSize function
        
        function disp(obj)
            % disp: Imprime la informacion del objeto en consola
            
            fprintf('Section designer:\n');
            disp@BaseModel(obj);
            
            [cx, cy] = obj.getCentroid();
            [gx, gy] = obj.getCenter();
            [xmin, xmax, ymin, ymax] = obj.getLimits();
            [sx, sy] = obj.getSize();
            [a, ac, as] = obj.getArea();
            
            fprintf('\tCentroide: (%.2f,%.2f)\n', cx, cy);
            fprintf('\tCentro geometrico: (%.2f,%.2f)\n', gx, gy);
            fprintf('\tArea: %.2f\n\t\tContinuos: %.2f\n\t\tSingulares: %.2f\n', a, ac, as);
            fprintf('\tAncho: %.2f\n', sx);
            fprintf('\tAlto: %.2f\n', sy);
            fprintf('\tNumero de elementos: %d\n\t\tContinuos: %d\n\t\tSingulares: %d\n', ...
                obj.contTotal+obj.singTotal, obj.contTotal, obj.singTotal);
            fprintf('\tLimites de la seccion:\n\t\tx: (%.2f,%.2f)\n\t\ty: (%.2f,%.2f)\n', ...
                xmin, xmax, ymin, ymax);
            
            dispMCURV();
            
        end % disp function
        
    end % public methods
    
end % SectionDesigner class