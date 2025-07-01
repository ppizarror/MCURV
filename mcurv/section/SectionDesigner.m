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

    properties (Access = private)
        contEvent % Eventos objetos continuos
        contGeom % Geometrias objetos continuos
        contMat % Materialidad objetos continuos
        contTotal % Numero total de objetos continuos
        contParams % Parametros adicionales objetos continuos
        singEvent % Eventos objetos singulares
        singGeom % Geometrias objetos singulares
        singGeomPlot % Guarda definicion de graficos de los objetos singulares
        singMat % Materialidad objetos singulares
        singTotal % Total de objetos singulares
        singParams % Parametros adicionales objetos singulares
        terminateOnFailure % Termina análisis si algun material excede el limite
        x0 % Guarda la posicion en x del centroide
        y0 % Guarda la posicion en y del centroide
    end % protected properties

    methods (Access = public)

        function obj = SectionDesigner(matName, terminateOnFailure)
            % SectionDesigner: Constructor de la clase

            if nargin < 1
                matName = '';
            end
            if nargin < 2
                terminateOnFailure = false;
            end
            obj = obj@BaseModel(matName);

            % Genera las bases
            obj.contEvent = {};
            obj.contGeom = {};
            obj.contMat = {};
            obj.contTotal = 0;
            obj.contParams = {};
            obj.singEvent = {};
            obj.singParams = {};
            obj.singGeom = {};
            obj.singGeomPlot = {};
            obj.singMat = {};
            obj.singTotal = 0;
            obj.terminateOnFailure = terminateOnFailure;

            % Otros
            obj.x0 = 0;
            obj.y0 = 0;

        end % SectionDesigner constructor

        function addDiscreteRect(obj, xc, yc, b, h, nx, ny, material, varargin)
            % addDiscreteRect: Agrega un rectangulo discreto a la seccion,
            % con centro (xc,yc) altura h, ancho b y una materialidad
            %
            % Parametros requeridos:
            %   xc              Posicion del centro en x
            %   yc              Posicion del centro en y
            %   b               Ancho
            %   h               Alto
            %   nx              Numero de discretizaciones en eje x
            %   ny              Numero de discretizaciones en eje y
            %   material        Material de la seccion
            %
            % Parametros opcionales:
            %   color           Color del area
            %   event           Evento de la seccion
            %   linewidth       Ancho de linea de la seccion
            %   rotation        Angulo de rotacion en grados
            %   translatex      Punto de translacion del eje x
            %   translatey      Punto de translacion del eje y
            %   transparency    Transparencia de la seccion
            %   xco             Centro de giro en x
            %   yco             Centro de giro en y

            if nargin < 8
                error('Numero de parametros incorrectos, uso: %s', ...
                    'addDiscreteRect(xc,yc,b,h,nx,ny,material,varargin)');
            end
            if ~isa(material, 'GenericMaterial')
                error('Material no es un objeto de clase GenericMaterial');
            end

            if nx == 0 || ny == 0
                error('La discretizacion del elemento no puede ser igual a cero');
            end

            if b < 0 || h < 0
                error('El ancho o el largo deben ser positivos');
            end

            if length(xc) ~= 1 || length(yc) ~= 1
                error('El centro debe ser un punto, no vector');
            end

            p = inputParser;
            p.KeepUnmatched = true;
            p.addOptional('color', material.getColor());
            p.addOptional('event', GenericEvent('contEvent'));
            p.addOptional('linewidth', 0.5);
            p.addOptional('rotation', 0);
            p.addOptional('translatex', 0);
            p.addOptional('translatey', 0);
            p.addOptional('transparency', 0.6);
            p.addOptional('xco', xc);
            p.addOptional('yco', yc);
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

            dc = [r.xco, r.yco] - [r.xco, r.yco] * tang; % Distancia al centro real
            tx = tx + dc(1);
            ty = ty + dc(2);

            % Suma el centro a la rotacion
            prot = prot + [tx, ty];

            % Crea el vector
            txV = [tx, tx, tx, tx];
            tyV = [ty, ty, ty, ty];

            xpatch = [(xc - b / 2), (xc + b / 2), (xc + b / 2), (xc - b / 2)];
            ypatch = [(yc - h / 2), (yc - h / 2), (yc + h / 2), (yc + h / 2)];

            % Rota los puntos del parche
            xpatchR = cos(alpha) * xpatch - sin(alpha) * ypatch;
            ypatchR = sin(alpha) * xpatch + cos(alpha) * ypatch;
            zpatchR = zeros(1, 4);

            % Suma la translacion
            xpatchR = xpatchR + txV;
            ypatchR = ypatchR + tyV;

            % Guarda objetos
            obj.contTotal = obj.contTotal + 1;
            obj.contEvent{obj.contTotal} = r.event;
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
                    px(k) = rot(1);
                    py(k) = rot(2);

                    % Crea el parche de la discretizacion
                    xpatch = [(xc + x - dx / 2), (xc + x + dx / 2), (xc + x + dx / 2), (xc + x - dx / 2)];
                    ypatch = [(yc + y - dy / 2), (yc + y - dy / 2), (yc + y + dy / 2), (yc + y + dy / 2)];

                    % Rota los puntos del parche
                    xpatchD{k} = cos(alpha) * xpatch - sin(alpha) * ypatch + txV;
                    ypatchD{k} = sin(alpha) * xpatch + cos(alpha) * ypatch + tyV;
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
            %   xc              Posicion del centro en x
            %   yc              Posicion del centro en y
            %   L               Largo del cuadrado
            %   n               Numero de discretizaciones en eje x/y
            %   material        Materialidad de la seccion
            %
            % Parametros opcionales:
            %   color           Color del area
            %   event           Evento de la seccion
            %   linewidth       Ancho de linea de la seccion
            %   transparency    Transparencia de la seccion

            if nargin < 6
                error('Numero de parametros incorrectos, uso: %s', ...
                    'addDiscreteSquare(xc,yc,L,n,material,varargin)');
            end
            if L < 0
                error('El largo debe ser mayor a cero');
            end
            obj.addDiscreteRect(xc, yc, L, L, n, n, material, varargin{:}, 'xco', xc, 'yco', yc);

        end % addDiscreteSquare function

        function addDiscreteEllipseRect(obj, xc, yc, b, h, nx, ny, material, varargin)
            % addDiscreteEllipse: Agrega una seccion elipse discreta
            % delimitada por un rectangulo. Orientacion vertical. Usar
            % 'rotation' para rotar la seccion.
            %
            % Parametros requeridos:
            %   xc              Posicion del centro en x
            %   yc              Posicion del centro en y
            %   b               Ancho del rectangulo contenedor
            %   h               Alto del rectangulo contenedor
            %   nx              Discretizacion en el eje x
            %   ny              Discretizacion en el eje y
            %   material        Materialidad de la seccion
            %
            % Parametros opcionales:
            %   color           Color del area
            %   event           Evento de la seccion
            %   linewidth       Ancho de linea de la seccion
            %   rotation        Angulo de rotacion en grados
            %   translatex      Punto de translacion del eje x
            %   translatey      Punto de translacion del eje y
            %   transparency    Transparencia de la seccion

            if nargin < 8
                error('Numero de parametros incorrectos, uso: %s', ...
                    'addDiscreteEllipseRect(xc,yc,b,h,nx,ny,material,varargin)');
            end

            if h <= 0
                error('Altura del rectangulo contenedor invalido');
            end
            if b <= 0
                error('Ancho del rectangulo contenedor invalido');
            end
            if ny <= 1
                error('Numero de discretizacion en la vertical incorrecto, debe ser mayor a 1');
            end

            % Itera segun el numero de particiones
            dh = h / ny; % Altura de cada segmento
            for i = 1:ny
                bi = sqrt(1-(h / 2 - dh * (i - 0.5))^2/((h / 2)^2)) * b; % Ec. elipse
                obj.addDiscreteRect(xc, yc+-h/2+dh*i, bi, dh, nx, 1, material, varargin{:}, 'xco', xc, 'yco', yc);
            end

        end % addDiscreteEllipseRect function

        function addDiscreteISection(obj, xc, yc, bi, bs, h, ti, ts, tw, nx, ny, material, varargin)
            % addDiscreteISection: Agrega una seccion I discreta
            %
            % Parametros requeridos:
            %   xc              Posicion del centro en x
            %   yc              Posicion del centro en y
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
            %   event           Evento de la seccion
            %   linewidth       Ancho de linea de la seccion
            %   rotation        Angulo de rotacion en grados
            %   translatex      Punto de translacion del eje x
            %   translatey      Punto de translacion del eje y
            %   transparency    Transparencia de la seccion

            if nargin < 12
                error('Numero de parametros incorrectos, uso: %s', ...
                    'addDiscreteISection(xc,yc,bi,bs,h,ti,ts,tw,nx,ny,material,varargin)');
            end

            if h <= 0
                error('Altura del perfil invalida');
            end
            if bi < 0 || bs <= 0
                error('Ancho de alas invalidos');
            end
            if bi == 0
                ti = 0;
            end

            % Calcula las particiones
            nyts = max(1, ceil(ny/h*ts));
            nyti = max(1, ceil(ny/h*ti));
            if ny - nyts - nyti < 0
                error('La suma del alto de las alas no puede exceder la altura del perfil');
            end

            nyw = max(1, ny-nyts-nyti); % Alma
            bf = max(bi, bs);
            nxts = max(1, ceil(nx/bf*bs));
            nxti = max(1, ceil(nx/bf*bi));
            nxw = max(1, ceil(nx/bf*tw));

            % Agrega las alas
            obj.addDiscreteRect(xc, yc+h/2-ts/2, bs, ts, nxts, nyts, material, varargin{:}, 'xco', xc, 'yco', yc);
            if bi ~= 0
                obj.addDiscreteRect(xc, yc-h/2+ti/2, bi, ti, nxti, nyti, material, varargin{:}, 'xco', xc, 'yco', yc);
                obj.addDiscreteRect(xc, yc, tw, h-ti-ts, nxw, nyw, material, varargin{:}, 'xco', xc, 'yco', yc);
            else
                obj.addDiscreteRect(xc, yc-ts/2, tw, h-ti-ts, nxw, nyw, material, varargin{:}, 'xco', xc, 'yco', yc);
            end

        end % addDiscreteISection function

        function addDiscreteHSection(obj, xc, yc, b, h, tf, tw, nx, ny, material, varargin)
            % addDiscreteHSection: Agrega una seccion H discreta
            %
            % Parametros requeridos:
            %   xc              Posicion del centro en x
            %   yc              Posicion del centro en y
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
            %   event           Evento de la seccion
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

        function addDiscreteTSection(obj, xc, yc, b, h, tf, tw, nx, ny, material, varargin)
            % addDiscreteTSection: Agrega una seccion T discreta
            %
            % Parametros requeridos:
            %   xc              Posicion del centro en x
            %   yc              Posicion del centro en y
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
            %   event           Evento de la seccion
            %   linewidth       Ancho de linea de la seccion
            %   rotation        Angulo de rotacion en grados
            %   translatex      Punto de translacion del eje x
            %   translatey      Punto de translacion del eje y
            %   transparency    Transparencia de la seccion

            if nargin < 10
                error('Numero de parametros incorrectos, uso: %s', ...
                    'addDiscreteTSection(xc,yc,b,h,tf,tw,nx,ny,material,varargin)');
            end
            obj.addDiscreteISection(xc, yc, 0, b, h, 0, tf, tw, nx, ny, material, varargin{:});

        end % addDiscreteTSection function

        function addDiscreteChannel(obj, xc, yc, b, h, tf, tw, nx, ny, material, varargin)
            % addDiscreteChannel: Agrega una seccion canal discreta
            %
            % Parametros requeridos:
            %   xc              Posicion del centro en x
            %   yc              Posicion del centro en y
            %   b               Ancho del canal
            %   h               Altura del canal
            %   tf              Ancho del ala
            %   tw              Ancho del alma
            %   nx              Discretizacion en x
            %   ny              Discretizacion en y
            %   material        Materialidad de la seccion
            %
            % Parametros opcionales:
            %   color           Color del area
            %   event           Evento de la seccion
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
            obj.addDiscreteRect(xc-b/2+tw/2, yc, tw, h-2*tf, nwx, nwy, material, varargin{:}, 'xco', xc, 'yco', yc);
            obj.addDiscreteRect(xc, yc-h/2+tf/2, b, tf, nx, nfy, material, varargin{:}, 'xco', xc, 'yco', yc);
            obj.addDiscreteRect(xc, yc+h/2-tf/2, b, tf, nx, nfy, material, varargin{:}, 'xco', xc, 'yco', yc);

        end % addDiscreteChannel function

        function addDiscreteBoxChannel(obj, xc, yc, b, h, t, nx, ny, material, varargin)
            % addDiscreteBoxChannel: Agrega una seccion canal rectangular
            % discreta
            %
            % Parametros requeridos:
            %   xc              Posicion del centro en x
            %   yc              Posicion del centro en y
            %   b               Ancho del canal
            %   h               Altura del canal
            %   t               Altura del ala/alma
            %   nx              Discretizacion en x
            %   ny              Discretizacion en y
            %   material        Materialidad de la seccion
            %
            % Parametros opcionales:
            %   color           Color del area
            %   event           Evento de la seccion
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
            obj.addDiscreteRect(xc-b/2+t/2, yc, t, h-2*t, ntex, ny-2*nte, material, varargin{:}, 'xco', xc, 'yco', yc);
            obj.addDiscreteRect(xc+b/2-t/2, yc, t, h-2*t, ntex, ny-2*nte, material, varargin{:}, 'xco', xc, 'yco', yc);
            obj.addDiscreteRect(xc, yc+h/2-t/2, b, t, nx, ntey, material, varargin{:}, 'xco', xc, 'yco', yc);
            obj.addDiscreteRect(xc, yc-h/2+t/2, b, t, nx, ntey, material, varargin{:}, 'xco', xc, 'yco', yc);

        end % addDiscreteBoxChannel function

        function addDiscreteSquareChannel(obj, xc, yc, L, t, n, material, varargin)
            % addDiscreteSquareChannel: Agrega una seccion canal cuadrada
            % discreta
            %
            % Parametros requeridos:
            %   xc              Posicion del centro en x
            %   yc              Posicion del centro en y
            %   L               Largo de la caja
            %   t               Espesor
            %   n               Discretizacion en x/y
            %   material        Materialidad de la seccion
            %
            % Parametros opcionales:
            %   color           Color del area
            %   event           Evento de la seccion
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

        function addDiscreteLChannel(obj, xc, yc, b, h, t, nx, ny, material, varargin)
            % addDiscreteLChannel: Agrega un perfil L discreto
            %
            % Parametros requeridos:
            %   xc              Posicion del centro en x
            %   yc              Posicion del centro en y
            %   b               Ancho del canal
            %   h               Altura del canal
            %   t               Ancho del ala/alma
            %   nx              Discretizacion en x
            %   ny              Discretizacion en y
            %   material        Materialidad de la seccion
            %
            % Parametros opcionales:
            %   color           Color del area
            %   event           Evento de la seccion
            %   linewidth       Ancho de linea de la seccion
            %   rotation        Angulo de rotacion en grados
            %   translatex      Punto de translacion del eje x
            %   translatey      Punto de translacion del eje y
            %   transparency    Transparencia de la seccion

            if nargin < 8
                error('Numero de parametros incorrectos, uso: %s', ...
                    'addDiscreteLChannel(xc,yc,b,h,t,nx,ny,material,varargin)');
            end

            % Calcula discretizacion del ala
            nty = max(1, ceil(ny/h*t));
            ntx = max(1, ceil(nx/b*t));
            nte = max(nty, ntx); % Espesor

            ntex = min(nx, nte);
            ntey = min(ny, nte);

            % Agrega elementos
            obj.addDiscreteRect(xc-b/2+t/2, yc, t, h-2*t, ntex, ny-2*nte, material, varargin{:}, 'xco', xc, 'yco', yc);
            obj.addDiscreteRect(xc, yc-h/2+t/2, b, t, nx, ntey, material, varargin{:}, 'xco', xc, 'yco', yc);

        end % addDiscreteLChannel function

        function addDiscreteTubular(obj, xc, yc, ri, rf, n, material, varargin)
            % addDiscreteTubular: Crea seccion tubular
            %
            % Parametros requeridos
            %   xc              Posicion del centro en x
            %   yc              Posicion del centro en y
            %   ri              Radio interior
            %   re              Radio exterior
            %   n               Discretizacion
            %   material        Material de la seccion
            %
            % Parametros opcionales:
            %   color           Color del area
            %   event           Evento de la seccion
            %   nrad            Numero de discretizacion radial
            %   ntheta          Numero de discretizacion en angulo
            %   linewidth       Ancho de linea de la seccion
            %   translatex      Punto de translacion del eje x
            %   translatey      Punto de translacion del eje y
            %   transparency    Transparencia de la seccion

            p = inputParser;
            p.KeepUnmatched = true;

            p.addOptional('nrad', 0);
            p.addOptional('ntheta', 100);
            parse(p, varargin{:});
            r = p.Results;

            if nargin < 7
                error('Numero de parametros incorrectos, uso: %s', ...
                    'addDiscreteTubular(obj,xc,yc,ri,rf,n,material,varargin)');
            end

            if ri > rf
                error('El radio interior no puede exceder al exterior');
            end
            if n <= 0
                error('Discretizacion invalida');
            end

            % Porte de cada discretizacion
            n = n / 2;
            dd = rf / n;

            % Parametriza el circulo
            ang = linspace(0, pi()/2, r.ntheta);
            nrad = ceil((rf - ri + 2 * dd)/dd);
            if r.nrad ~= 0
                nrad = r.nrad;
            end
            rad = linspace(ri+dd/2, rf-dd/2, nrad);
            aPoints = {};
            k = 1; % Puntos agregados

            for j = 1:nrad % Discretiza en el radio
                last = [Inf, Inf];
                for i = 1:r.ntheta % Discretiza en el angulo

                    xi = (rad(j)) * cos(ang(i));
                    yi = (rad(j)) * sin(ang(i));
                    xi = xi - mod(xi, dd);
                    yi = yi - mod(yi, dd);

                    % Si el punto no ha sido agregado
                    if (xi ~= last(1) || yi ~= last(2)) && ...
                            ~isCellMember(aPoints, sprintf('%d,%d', xi, yi))

                        % Agrega punto original
                        obj.addDiscreteRect(xc+xi, yc+yi, dd, dd, 1, 1, material, varargin{:}, 'rotation', 0, 'xco', xc', 'yco', yc);
                        aPoints{k} = sprintf('%d,%d', xi, yi);
                        k = k + 1;
                        last(1) = xi;
                        last(2) = yi;

                        % Agrega el reflejo en x
                        if ~isCellMember(aPoints, sprintf('%d,%d', -xi, yi))
                            obj.addDiscreteRect(xc-xi, yc+yi, dd, dd, 1, 1, material, varargin{:}, 'rotation', 0, 'xco', xc', 'yco', yc);
                            aPoints{k} = sprintf('%d,%d', -xi, yi);
                            k = k + 1;
                        end

                        % Agrega el reflejo en y
                        if ~isCellMember(aPoints, sprintf('%d,%d', xi, -yi))
                            obj.addDiscreteRect(xc+xi, yc-yi, dd, dd, 1, 1, material, varargin{:}, 'rotation', 0, 'xco', xc', 'yco', yc);
                            aPoints{k} = sprintf('%d,%d', xi, -yi);
                            k = k + 1;
                        end

                        % Agrega el reflejo en xy
                        if ~isCellMember(aPoints, sprintf('%d,%d', -xi, -yi))
                            obj.addDiscreteRect(xc-xi, yc-yi, dd, dd, 1, 1, material, varargin{:}, 'rotation', 0, 'xco', xc', 'yco', yc);
                            aPoints{k} = sprintf('%d,%d', -xi, -yi);
                            k = k + 1;
                        end
                    end

                end % Angulo
            end % Radio

        end % addDiscreteTubular function

        function addDiscreteCircle(obj, xc, yc, r, n, material, varargin)
            % addDiscreteCircle: Crea seccion circular
            %
            % Parametros requeridos
            %   xc              Posicion del centro en x
            %   yc              Posicion del centro en y
            %   r               Radio
            %   n               Discretizacion
            %   material        Material de la seccion
            %
            % Parametros opcionales:
            %   color           Color del area
            %   event           Evento de la seccion
            %   ntheta          Numero de discretizacion en angulo
            %   linewidth       Ancho de linea de la seccion
            %   translatex      Punto de translacion del eje x
            %   translatey      Punto de translacion del eje y
            %   transparency    Transparencia de la seccion

            if nargin < 6
                error('Numero de parametros incorrectos, uso: %s', ...
                    'addDiscreteCircle(obj,xc,yc,r,n,material,varargin)');
            end
            obj.addDiscreteTubular(xc, yc, 0, r, n, material, varargin{:});

        end % addDiscreteCircle function

        function addFiniteArea(obj, xc, yc, area, material, varargin)
            % addFiniteArea: Agrega un area finita
            %
            % Parametros requeridos:
            %   xc              Posicion del centro en x
            %   yc              Posicion del centro en y
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
            p.addOptional('event', GenericEvent('contEvent'));
            p.addOptional('plotareafactor', 1);
            p.addOptional('transparency', 0);
            parse(p, varargin{:});
            r = p.Results;
            r.transparency = 1 - r.transparency;

            obj.singTotal = obj.singTotal + 1;
            b = sqrt(area * r.plotareafactor);
            xpatch = [(xc - b / 2), (xc + b / 2), (xc + b / 2), (xc + -b / 2)];
            ypatch = [(yc - b / 2), (yc - b / 2), (yc + b / 2), (yc + b / 2)];
            zpatch = [0, 0, 0, 0];
            obj.singEvent{obj.singTotal} = r.event;
            obj.singGeomPlot{obj.singTotal} = {xpatch, ypatch, zpatch};
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
            %   axisTextSize        Altura texto ejes
            %   axisTextWeight      Tipo de texto ejes
            %   axisXColor          Color eje x
            %   axisXText           Texto eje x
            %   axisYColor          Color eje y
            %   axisYText           Texto eje y
            %   center              Muestra o no el centroide
            %   centerColor         Color del centroide
            %   centerLineWidth     Ancho de linea del centroide
            %   centerMarkerSize    Tamano del marcador
            %   centroid            Muestra o no el centroide
            %   centroidColor       Color del centroide
            %   centroidLineWidth   Ancho de linea del centroide
            %   centroidMarkerSize  Tamano del marcador
            %   contCenter          Muestra el centro de los e. continuos
            %   legend              Muestra la leyenda
            %   legendCentroid      Leyenda centroide
            %   legendMaterial      Leyenda de materiales
            %   limMargin           Incrementa el margen
            %   showdisc            Grafica la discretizacion
            %   title               Titulo del grafico
            %   units               Unidades del modelo

            p = inputParser;
            p.KeepUnmatched = true;
            p.addOptional('axis', true);
            p.addOptional('axisSize', 0.15);
            p.addOptional('axisTextSize', 12);
            p.addOptional('axisTextWeight', 'bold');
            p.addOptional('axisXColor', [1, 0, 0]);
            p.addOptional('axisXText', 'x');
            p.addOptional('axisYColor', [0, 1, 0]);
            p.addOptional('axisYText', 'y');
            p.addOptional('center', true);
            p.addOptional('centerColor', [0, 0, 0]);
            p.addOptional('centerLineWidth', 2);
            p.addOptional('centerMarkerSize', 10);
            p.addOptional('centroid', true);
            p.addOptional('centroidColor', [1, 1, 0]);
            p.addOptional('centroidLineWidth', 2);
            p.addOptional('centroidMarkerSize', 10);
            p.addOptional('contCenter', false);
            p.addOptional('legend', false);
            p.addOptional('legendCentroid', true);
            p.addOptional('legendMaterial', true);
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
            addedMaterials = {};

            % Agrega los elementos continuos
            for i = 1:obj.contTotal
                g = obj.contGeom{i};
                patchx = g{17};
                patchy = g{18};
                patchz = g{19};
                matname = obj.contMat{i}.getName();
                pl = patch(patchx, patchy, patchz, ...
                    'FaceColor', obj.contParams{i}.color, ...
                    'EdgeColor', obj.contParams{i}.color, ...
                    'LineWidth', obj.contParams{i}.linewidth*0.5, ...
                    'FaceAlpha', obj.contParams{i}.transparency, ...
                    'DisplayName', matname);
                if ~isCellMember(addedMaterials, matname) && r.legendMaterial
                    addedMaterials{length(addedMaterials)+1} = matname;
                else
                    set(get(get(pl, 'Annotation'), 'LegendInformation'), 'IconDisplayStyle', 'off');
                end
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
                        pl = patch(patchx{j}, patchy{j}, patchz, ...
                            'FaceColor', obj.contParams{i}.color, ...
                            'EdgeColor', obj.contParams{i}.color, ...
                            'LineWidth', obj.contParams{i}.linewidth*0.5, ...
                            'FaceAlpha', 0);
                        set(get(get(pl, 'Annotation'), 'LegendInformation'), 'IconDisplayStyle', 'off');
                        if r.contCenter
                            plot(px(j), py(j), '.', 'MarkerSize', 10, 'Color', ...
                                [obj.contParams{i}.color, 0.25]);
                        end
                    end
                end
            end

            % Agrega los elementos discretos
            for i = 1:obj.singTotal
                sg = obj.singGeomPlot{i};
                patchx = sg{1};
                patchy = sg{2};
                patchz = sg{3};
                matname = obj.singMat{i}.getName();
                pl = patch(patchx, patchy, patchz, ...
                    'FaceColor', obj.singParams{i}.color, ...
                    'EdgeColor', obj.singParams{i}.color, ...
                    'FaceAlpha', obj.singParams{i}.transparency, ...
                    'EdgeAlpha', obj.singParams{i}.transparency, ...
                    'DisplayName', matname);
                if ~isCellMember(addedMaterials, matname) && r.legendMaterial
                    addedMaterials{length(addedMaterials)+1} = matname;
                else
                    set(get(get(pl, 'Annotation'), 'LegendInformation'), 'IconDisplayStyle', 'off');
                end
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
            if r.legend
                legend('location', 'best');
            end

            % Escribe el centro de gravedad
            if r.centroid
                pl = plot(xc, yc, '+', 'Color', r.centroidColor, 'MarkerSize', ...
                    r.centroidMarkerSize, 'LineWidth', r.centroidLineWidth, ...
                    'DisplayName', sprintf('Centroide (%.2f, %.2f)', xc, yc));
                if ~r.legendCentroid
                    set(get(get(pl, 'Annotation'), 'LegendInformation'), 'IconDisplayStyle', 'off');
                end
            end

            % Escribe el centro geometrico
            if r.center
                pl = plot(gx, gy, '+', 'Color', r.centerColor, 'MarkerSize', ...
                    r.centerMarkerSize, 'LineWidth', r.centerLineWidth, ...
                    'DisplayName', sprintf('Centro (%.2f, %.2f)', gx, gy));
                if ~r.legendCentroid
                    set(get(get(pl, 'Annotation'), 'LegendInformation'), 'IconDisplayStyle', 'off');
                end
            end

            % Escribe los ejes
            if r.axis

                % Largo ejes
                lx = r.axisSize * sx;
                ly = r.axisSize * sy;
                la = max(lx, ly);

                % Eje x
                p1 = [gx, gy];
                p2 = [gx + la, gy];
                dp = p2 - p1;
                pl = quiver(p1(1), p1(2), dp(1), dp(2), 0, 'Color', r.axisXColor);
                set(get(get(pl, 'Annotation'), 'LegendInformation'), 'IconDisplayStyle', 'off');
                text(p2(1)-0.05*la, p2(2)+0.20*la, r.axisXText, 'Color', r.axisXColor, ...
                    'FontWeight', r.axisTextWeight, 'FontSize', r.axisTextSize, ...
                    'HorizontalAlignment', 'center');

                % Eje y
                p1 = [gx, gy];
                p2 = [gx, gy + la];
                dp = p2 - p1;
                pl = quiver(p1(1), p1(2), dp(1), dp(2), 0, 'Color', r.axisYColor);
                set(get(get(pl, 'Annotation'), 'LegendInformation'), 'IconDisplayStyle', 'off');
                text(p2(1)+0.15*la, p2(2), r.axisYText, 'Color', r.axisYColor, ...
                    'FontWeight', r.axisTextWeight, 'FontSize', r.axisTextSize, ...
                    'HorizontalAlignment', 'center');

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
            %   factorM         Factor momento
            %   factorP         Factor de carga axial
            %   i               Numero de punto de evaluacion
            %   limMargin       Incrementa el margen
            %   normaspect      Normaliza el aspecto
            %   plot            Tipo de grafico (cont,sing)
            %   showgrid        Muestra la grilla de puntos
            %   showmesh        Muesra el meshado de la geometria
            %   unitlength      Unidad de largo
            %   unitloadF       Unidad de tension
            %   unitloadM       Unidad de momento
            %   unitloadP       Unidad de carga axial

            plt = obj.plotStrainStress(e0, phix, phiy, varargin{:}, 'type', 'stress');

        end % plotStress function

        function plt = plotStrain(obj, e0, phix, phiy, varargin)
            % plotStrain: Grafica el valor de la deformacion para cada
            % punto (x,y) del elemento
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
            %   factorM         Factor momento
            %   factorP         Factor de carga axial
            %   i               Numero de punto de evaluacion
            %   limMargin       Incrementa el margen
            %   normaspect      Normaliza el aspecto
            %   plot            Tipo de grafico (cont,sing)
            %   showgrid        Muestra la grilla de puntos
            %   showmesh        Muesra el meshado de la geometria
            %   unitlength      Unidad de largo
            %   unitloadF       Unidad de tension
            %   unitloadM       Unidad de momento
            %   unitloadP       Unidad de carga axial

            plt = obj.plotStrainStress(e0, phix, phiy, varargin{:}, 'type', 'strain');

        end % plotStrain function

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
                for i = 1:g{5} % Calcula la integral
                    e_i = eps(px(i), py(i));
                    [~, Ec] = mat.eval(e_i);
                    if isnan(Ec)
                        if obj.terminateOnFailure
                            jac = NaN;
                            return;
                        else
                            Ec = 0;
                        end
                    end

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
                if isnan(Ec)
                    if obj.terminateOnFailure
                        jac = NaN;
                        return;
                    else
                        Ec = 0;
                    end
                end

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

        function callEvents(obj, e0, phix, phiy, p, mx, my, n)
            % callEvents: LLama a los eventos de la seccion
            %
            % Parametros requeridos:
            %   e0          Valor de la deformacion con respecto al centroide
            %   phix        Curvatura en x
            %   phiy        Curvatura en y
            %   p           Nivel de carga axial analisis
            %   mx          Momento total en eje x analisis
            %   my          Momento total en eje y analisis
            %   n           Numero de iteracion

            % Crea funcion deformacion
            eps = @(x, y) e0 + phix * (y - obj.y0) - phiy * (x - obj.x0);

            % Objetos continuos
            for j = 1:obj.contTotal
                g = obj.contGeom{j};
                px = g{1};
                py = g{2};
                mat = obj.contMat{j};
                for i = 1:g{5}
                    e_i = eps(px(i), py(i));
                    [f, Ec] = mat.eval(e_i);
                    obj.contEvent{j}.eval(e0, phix, phiy, e_i, f, Ec, p, mx, my, n);
                end
            end

            % Objetos puntuales
            for j = 1:obj.singTotal
                g = obj.singGeom{j};
                px = g{1};
                py = g{2};
                mat = obj.singMat{j};

                e_i = eps(px, py);
                [f, Ec] = mat.eval(e_i);
                obj.singEvent{j}.eval(e0, phix, phiy, e_i, f, Ec, p, mx, my, n);
            end

        end % callEvents function
        
        function resetEvents(obj)
            % resetEvents: Resetea eventos

            for j = 1:obj.contTotal
                g = obj.contGeom{j};
                for i = 1:g{5}
                    obj.contEvent{j}.reset();
                end
            end
            for j = 1:obj.singTotal
                obj.singEvent{j}.reset();
            end

        end % resetEvents function

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
                    if isnan(fc)
                        if obj.terminateOnFailure
                            mx = NaN;
                            return;
                        else
                            fc = 0;
                        end
                    end
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
                if isnan(fc)
                    if obj.terminateOnFailure
                        mx = NaN;
                        return;
                    else
                        fc = 0;
                    end
                end

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
                    if isnan(fc)
                        if obj.terminateOnFailure
                            my = NaN;
                            return;
                        else
                            fc = 0;
                        end
                    end
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
                if isnan(fc)
                    if obj.terminateOnFailure
                        my = NaN;
                        return;
                    else
                        fc = 0;
                    end
                end
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
                    if isnan(fc)
                        if obj.terminateOnFailure
                            p = NaN;
                            return;
                        else
                            fc = 0;
                        end
                    end
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
                if isnan(fc)
                    if obj.terminateOnFailure
                        p = NaN;
                        return;
                    else
                        fc = 0;
                    end
                end
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

        function [ix, iy] = getInertia(obj)
            % getInertia: Calcula la inercia de la seccion

            [xc, yc] = obj.getCentroid();
            ix = 0;
            iy = 0;
            at = 0;
            for i = 1:obj.contTotal
                g = obj.contGeom{i};
                px = g{1};
                py = g{2};
                ai = g{3} * g{4};
                tn = g{5};
                for j = 1:tn
                    ix = ix + (py(j) - yc)^2 * ai;
                    iy = iy + (px(j) - xc)^2 * ai;
                    at = at + ai;
                end
            end
            for i = 1:obj.singTotal
                g = obj.singGeom{i};
                ix = ix + (g{2} - yc)^2 * g{3};
                iy = iy + (g{1} - xc)^2 * g{3};
            end

        end % getInertia function

        function [rx, ry] = getGyradius(obj)
            % getGyradius: Calcula el radio de giro

            [ix, iy] = obj.getInertia();
            a = obj.getArea();

            rx = sqrt(ix/a);
            ry = sqrt(iy/a);

        end % getGyradius function

        function [wx, wy] = getPlasticModuli(obj)
            % getGyradius: Calcula el radio de giro

            [ix, iy] = obj.getInertia();
            [sy, sx] = obj.getSize();

            wx = ix / (sx / 2);
            wy = iy / (sy / 2);

        end % getGyradius function

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
            [ix, iy] = obj.getInertia();
            [rx, ry] = obj.getGyradius();
            [wx, wy] = obj.getPlasticModuli();

            fprintf('\tCentroide:\t\t\t(%.2f,%.2f)\n', cx, cy);
            fprintf('\tCentro geometrico:\t(%.2f,%.2f)\n', gx, gy);
            fprintf('\tAncho:\t%.2f\n', sx);
            fprintf('\tAlto:\t%.2f\n', sy);
            fprintf('\tArea:\t%.2f\n\t\tContinuos:\t%.2f\n\t\tSingulares:\t%.2f\n', a, ac, as);
            fprintf('\tInercia:\n\t\tIx:\t%e\n\t\tIy:\t%e\n', ix, iy);
            fprintf('\tModulo plastico:\n\t\tWx:\t%e\n\t\tWy:\t%e\n', wx, wy);
            fprintf('\tRadio de giro:\n\t\trx:\t%.3f\n\t\try:\t%.3f\n', rx, ry);
            fprintf('\tNumero de elementos: %d\n\t\tContinuos:\t\t%d\n\t\tSingulares:\t\t%d\n', ...
                obj.contTotal+obj.singTotal, obj.contTotal, obj.singTotal);

            % Obtiene los materiales
            mats = {};
            for i = 1:length(obj.contMat)
                mats{i} = obj.contMat{i};
            end
            for j = 1:length(obj.singMat)
                mats{i+j} = obj.singMat{j};
            end

            matsL = getClassnameCell(mats); % Lista con clase: total
            matsK = matsL.keys();
            matsV = matsL.values();
            % matsT = length(mats); % Materiales diferentes

            fprintf('\tMateriales diferentes: %d\n', length(matsK));
            for i = 1:length(matsK)
                fprintf('\t\t(%d)\t%d\t%s\n', i, matsV{i}, matsK{i});
            end % for i

            fprintf('\tLimites de la seccion:\n\t\tx:\t(%.2f,%.2f)\n\t\ty:\t(%.2f,%.2f)\n', ...
                xmin, xmax, ymin, ymax);

            dispMCURV();

        end % disp function

    end % public methods

    methods (Access = private)

        function plt = plotStrainStress(obj, e0, phix, phiy, varargin)
            % plotStrainStress: Grafica el esfuerzo o la deformacion de la
            % seccion
            %
            % Parametros requeridos:
            %   e0          Valor de la deformacion con respecto al centroide
            %   phix        Curvatura en x
            %   phiy        Curvatura en y
            %
            % Parametros iniciales:
            %   angle           Angulo de la curvatura (interno)
            %   axisequal       Aplica mismo factores a los ejes
            %   Az              Angulo azimutal
            %   EI              Elevacion del grafico
            %   factorM         Factor momento
            %   factorP         Factor de carga axial
            %   i               Numero de punto de evaluacion
            %   limMargin       Incrementa el margen
            %   normaspect      Normaliza el aspecto
            %   plot            Tipo de grafico (cont,sing)
            %   showgrid        Muestra la grilla de puntos
            %   showmesh        Muesra el meshado de la geometria
            %   type            Tipo de grafico (strain,stress)
            %   unitlength      Unidad de largo
            %   unitloadF       Unidad de tension
            %   unitloadM       Unidad de momento
            %   unitloadP       Unidad de carga axial

            % Verificacion inicial
            if length(e0) ~= length(phix) || length(e0) ~= length(phiy)
                error('e0 y phix/y deben tener igual largo');
            end
            obj.updateProps();

            p = inputParser;
            p.KeepUnmatched = true;
            p.addOptional('angle', 0);
            p.addOptional('axisequal', false);
            p.addOptional('Az', 0)
            p.addOptional('EI', 90);
            p.addOptional('factorM', 1e-6); % N*mm -> kN*m
            p.addOptional('factorP', 1e-3); % N -> kN
            p.addOptional('i', 1);
            p.addOptional('limMargin', 0);
            p.addOptional('mode', 'xy'); % Interno, 'xy','a'
            p.addOptional('normaspect', false);
            p.addOptional('plot', 'cont');
            p.addOptional('showgrid', true);
            p.addOptional('showmesh', false);
            p.addOptional('type', 'stress');
            p.addOptional('unitlength', 'mm');
            p.addOptional('unitloadF', 'MPa');
            p.addOptional('unitloadM', 'kN*m');
            p.addOptional('unitloadP', 'kN');
            parse(p, varargin{:});
            r = p.Results;

            if ~(strcmp(r.plot, 'cont') || strcmp(r.plot, 'sing'))
                error('Errot tipo de grafico, valores posibles: %s', ...
                    'cont, sing');
            end

            if strcmp(r.type, 'stress')
                fprintf('Generando grafico esfuerzos:\n');
            elseif strcmp(r.type, 'strain')
                fprintf('Generando grafico deformaciones:\n');
            else
                error('Tipo de grafico desconocido, type:strain,stress');
            end
            fprintf('\tSeccion: %s\n', obj.getName());
            fprintf('\tTipo: %s\n', r.plot);

            r.i = ceil(r.i);
            if r.i > 0
                if length(e0) >= r.i
                    e0 = e0(r.i);
                    phix = phix(r.i);
                    phiy = phiy(r.i);
                else
                    error('El punto de evaluacion i=%d excede el largo del vector de soluciones (%d)', ...
                        r.i, length(e0));
                end
            end
            fprintf('\tPunto evaluacion: %d\n', r.i);

            % Aplica limites
            if abs(e0) < 1e-20
                e0 = 0;
            end
            if abs(phix) < 1e-20
                phix = 0;
            end
            if abs(phiy) < 1e-20
                phiy = 0;
            end

            if strcmp(r.mode, 'a')
                fprintf('\tModo: Angulo (%.1f)\n', r.angle);
            else
                fprintf('\tModo: xy\n');
            end

            fprintf('\tDeformaciones:\n');
            fprintf('\t\te0: %e (-)\n', e0);
            fprintf('\t\tphix: %e (1/%s)\n', phix, r.unitlength);
            fprintf('\t\tphiy: %e (1/%s)\n', phiy, r.unitlength);
            if strcmp(r.mode, 'a')
                ra = r.angle * pi() / 180;
                aphi = (phix + phiy) / (cos(-ra) + sin(-ra));
                fprintf('\t\tphi: %e (1/%s)\n', aphi, r.unitlength);
            else
                aphi = 0;
            end

            % Calcula cargas
            p = obj.calcP(e0, phix, phiy);
            if isnan(p)
                error('Punto de evaluacion i excede limite. Pruebe con otro');
            end
            mx = obj.calcMx(e0, phix, phiy);
            my = obj.calcMy(e0, phix, phiy);
            fprintf('\tCargas:\n');
            fprintf('\t\tP axial: %.2f %s\n', p*r.factorP, r.unitloadP);
            fprintf('\t\tMx: %.2f %s\n', mx*r.factorM, r.unitloadM);
            fprintf('\t\tMy: %.2f %s\n', my*r.factorM, r.unitloadM);

            if length(e0) ~= 1
                error('Solo se puede graficar un punto de e0,phix/y, no un vector');
            end

            % Genera la figura
            plt = figure();
            movegui(plt, 'center');
            if strcmp(r.type, 'stress')
                set(gcf, 'name', 'Esfuerzos');
            elseif strcmp(r.type, 'strain')
                set(gcf, 'name', 'Deformaciones');
            end
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
            flim = [Inf, -Inf];

            % Genera el mallado de cada area continua
            if strcmp(r.plot, 'cont')
                for i = 1:obj.contTotal
                    g = obj.contGeom{i};
                    px = g{11};
                    py = g{12};
                    nt = g{13};
                    dx = abs(g{14}) * 0.5;
                    dy = abs(g{15}) * 0.5;
                    mat = obj.contMat{i};

                    dxm = abs(min(dxm, dx));
                    dym = abs(min(dym, dy));

                    mallaX = zeros(nt, 1);
                    mallaY = zeros(nt, 1);
                    vecF = zeros(nt, 1);

                    for j = 1:nt
                        mallaX(j) = px(j);
                        mallaY(j) = py(j);
                        if strcmp(r.type, 'stress')
                            [f, ~] = mat.eval(eps(px(j), py(j)));
                        elseif strcmp(r.type, 'strain')
                            f = eps(px(j), py(j));
                        end
                        if isnan(f)
                            f = 0;
                        end
                        flim = [min(f, flim(1)), max(f, flim(2))];
                        vecF(j) = f;
                    end

                    [xq, yq] = meshgrid(min(mallaX):dx:max(mallaX), min(mallaY):dy:max(mallaY));
                    vq = griddata(mallaX, mallaY, vecF, xq, yq);
                    surf(xq, yq, vq, 'EdgeColor', 'none');

                    % Grafica la linea en cero
                    if r.showmesh
                        [xq, yq] = meshgrid(min(mallaX):dx:max(mallaX), min(mallaY):dy:max(mallaY));
                        vq = griddata(mallaX, mallaY, vecF.*0, xq, yq);
                        hold on;
                        fmesh = mesh(xq, yq, vq);
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
                        'FaceAlpha', 0.1, 'EdgeAlpha', 1);
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
                        % A diferencia del continuo, el discreto se evalua solo en el centro del area
                        if strcmp(r.type, 'stress')
                            [f, ~] = mat.eval(eps(x, y));
                        elseif strcmp(r.type, 'strain')
                            f = eps(x, y);
                        end
                        if isnan(f)
                            f = 0;
                        end
                        flim = [min(f, flim(1)), max(f, flim(2))];
                        vecF(j) = f;
                    end

                    [xq, yq] = meshgrid(min(mallaX):dd:max(mallaX), min(mallaY):dd:max(mallaY));
                    vq = griddata(mallaX, mallaY, vecF, xq, yq);
                    m = mesh(xq, yq, vq);
                    surf(xq, yq, vq);
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
            if strcmp(r.type, 'stress')
                t = get(h, 'Limits');
                T = linspace(t(1), t(2), 5);
                set(h, 'Ticks', T);
                TL = arrayfun(@(x) sprintf('%.2f', x), T, 'un', 0);
                set(h, 'TickLabels', TL);
            end
            shading interp;

            % Cambia los label
            xlabel(sprintf('x (%s)', r.unitlength));
            ylabel(sprintf('y (%s)', r.unitlength));
            if strcmp(r.type, 'stress')
                ylabel(h, sprintf('\\sigma (%s)', r.unitloadF));
            elseif strcmp(r.type, 'strain')
                ylabel(h, '\epsilon (-)');
            end
            view(r.Az, r.EI);

            % Modifica los ejes para dejar la misma escala
            plotLimsMargin(r.limMargin);

            % Aplica factor de escala en x/y
            if r.normaspect && ~r.axisequal
                h = get(gca, 'DataAspectRatio');
                [sx, sy] = obj.getSize();
                set(gca, 'DataAspectRatio', [h(1), h(2) * sx / sy, h(3)]);
            end

            % Escribe informacion del analisis
            if strcmp(r.type, 'stress')
                fprintf('\tTensiones limite:\n\t\tMinimo: %f %s\n\t\tMaximo: %f %s\n', ...
                    flim(1), r.unitloadF, flim(2), r.unitloadF);
            elseif strcmp(r.type, 'strain')
                fprintf('\tDeformaciones limite:\n\t\tMinimo: %f\n\t\tMaximo: %f\n', ...
                    flim(1), flim(2));
            end

            % Genera el titulo
            if strcmp(r.type, 'stress')
                if strcmp(r.mode, 'xy')
                    plotTitle = {sprintf('%s  -  Esfuerzos i=%d', obj.getName(), r.i), ...
                        sprintf('e_0: %.3e  /  \\phi_x: %.3e  /  \\phi_y: %.3e', e0, phix, phiy), ...
                        sprintf('\\sigma_{max}: %.3e %s  /  \\sigma_{min}: %.3e %s', flim(2), r.unitloadF, flim(1), r.unitloadF)};
                else
                    plotTitle = {sprintf('%s  -  Angulo %.1f  -  Esfuerzos i=%d', obj.getName(), r.angle, r.i), ...
                        sprintf('e_0: %.3e  /  \\phi_x: %.3e  /  \\phi_y: %.3e  /  \\phi: %.3e', e0, phix, phiy, aphi), ...
                        sprintf('\\sigma_{max}: %.3e %s  /  \\sigma_{min}: %.3e %s', flim(2), r.unitloadF, flim(1), r.unitloadF)};
                end
            elseif strcmp(r.type, 'strain')
                if strcmp(r.mode, 'xy')
                    plotTitle = {sprintf('%s  -  Deformaciones i=%d', obj.getName(), r.i), ...
                        sprintf('e_0: %.3e  /  \\phi_x: %.3e  /  \\phi_y: %.3e', e0, phix, phiy), ...
                        sprintf('\\epsilon_{max}: %.3e  /  \\epsilon_{min}: %.3e', flim(2), flim(1))};
                else
                    plotTitle = {sprintf('%s  -  Angulo %.1f  -  Deformaciones i=%d', obj.getName(), r.angle, r.i), ...
                        sprintf('e_0: %.3e  /  \\phi_x: %.3e  /  \\phi_y: %.3e  /  \\phi: %.3e', e0, phix, phiy, aphi), ...
                        sprintf('\\epsilon_{max}: %.3e  /  \\epsilon_{min}: %.3e', flim(2), flim(1))};
                end
            end
            title(plotTitle);

            % Actualiza el grafico
            drawnow();
            dispMCURV();

        end % plotStrainStress function

    end % private methods

end % SectionDesigner class