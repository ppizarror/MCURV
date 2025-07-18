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
%| SectionAnalysis                                                      |
%|                                                                      |
%| Analiza una seccion, permitiendo calcular diagrama momento curvatura |
%| de cualquier seccion tipo SectionDesigner.                           |
%|                                                                      |
%| Autor: Pablo Pizarro R. @ppizarror.com                               |
%| Licencia: MIT                                                        |
%| Codigo fuente: https://github.com/ppizarror/MCURV                    |
%|______________________________________________________________________|

classdef SectionAnalysis < BaseModel

    properties (Access = protected)
        maxiter % Numero maximo de iteraciones
        tol % Tolerancia del calculo
        lastsole0p % Ultima solucion de e0/P
        showprogress % Muestra el progreso en consola
    end % protected properties

    methods (Access = public)

        function obj = SectionAnalysis(analysisName, maxiter, tol, varargin)
            % SectionAnalysis: Constructor de la clase
            %
            % Parametros opcionales:
            %   showprogress    Muestra el porcentaje de progreso

            p = inputParser;
            p.KeepUnmatched = true;
            p.addOptional('showprogress', true);
            parse(p, varargin{:});
            r = p.Results;

            obj = obj@BaseModel(analysisName);
            obj.maxiter = maxiter;
            obj.tol = tol;
            obj.lastsole0p = {};
            obj.showprogress = r.showprogress;

        end % SectionAnalysis constructor

        function [defTotal, mxInt, myInt, pInt, err, iters, jacIter] = calc_e0M(obj, section, P, phix, phiy, varargin)
            % calc_e0M: Calcula e0 y M dado un arreglo de cargas y curvaturas
            %
            % Parametros:
            %   section         Objeto de la seccion de analisis
            %   P               Arreglo de cargas
            %   phix            Vector de curvatura en x
            %   phiy            Vector de curvatura en y
            %
            % Parametros opcionales:
            %   ppos            Posicion de la carga, si no se define se deja en el centroide de la seccion

            tIni = cputime();
            if nargin < 5
                error('Numero de parametros incorrectos, uso: %s', ...
                    'calc_e0M(section,p,phix,phiy,varargin)');
            end

            if ~isa(section, 'SectionDesigner')
                error('Objeto seccion debe heredar de SectionDesigner');
            end

            if length(P) ~= length(phix) || length(P) ~= length(phiy)
                error('Los vectores p, phix, phiy deben tener igual largo');
            end

            % Verifica que los vectores sean crecientes
            for i = 2:length(P)
                if abs(P(i)) < abs(P(i-1)) || abs(phix(i)) < abs(phix(i-1)) || ...
                        abs(phiy(i)) < abs(phiy(i-1))
                    error('Los vectores p, phix, phiy deben ser crecientes en modulo');
                end
            end

            fprintf('Calculando e0 y M dado arreglo de P y phix, phiy:\n');
            fprintf('\tSeccion: %s\n', section.getName());

            % Actualiza propiedades
            section.updateProps();
            [px, py] = section.getCentroid();
            section.resetEvents();

            p = inputParser;
            p.KeepUnmatched = true;
            p.addOptional('ppos', [px, py]);

            % Internos
            p.addOptional('calcE0Mangle', '0');
            p.addOptional('calcE0Mmode', 'phixy'); % Puede ser 'phixy','angle'
            p.addOptional('calcE0Mphi', []);

            parse(p, varargin{:});
            r = p.Results;

            pcentroid = '';
            if r.ppos(1) == px && r.ppos(2) == py
                pcentroid = ' ubicado en centroide';
            end

            fprintf('\tNumero de incrementos: %d\n', length(P));
            fprintf('\tNumero de maximo de iteraciones: %d\n', obj.maxiter);
            fprintf('\tTolerancia maxima: %.3e\n', obj.tol);

            fprintf('\tCarga externa posicion: (%.2f,%.2f)%s\n', ...
                r.ppos(1), r.ppos(2), pcentroid);

            if strcmp(r.calcE0Mmode, 'phixy')
                fprintf('\tCalculando con arreglos de curvatura en x/y\n');
            elseif strcmp(r.calcE0Mmode, 'angle')
                fprintf('\tCalculando con arreglo de curvatura, angulo: %.1f\n', r.calcE0Mangle);
            else
                error('Modo de calculo invalido');
            end

            % Genera el vector de cambio de P
            n = length(P);
            deltaP = zeros(n, 1);
            deltaP(1) = P(1);
            for i = 2:n
                deltaP(i) = P(i) - P(i-1);
            end

            % Crea matriz de iteraciones de la deformacion total
            deltaE0Iter = zeros(n, obj.maxiter);
            pE0 = zeros(n, obj.maxiter);
            jacIter = zeros(n, obj.maxiter); % Jacobiano (rigidez)
            defTotal = zeros(n, 1); % Deformacion total para cada [P,phi]
            err = zeros(n, obj.maxiter); % Error de cada iteracion
            iters = zeros(n, 1); % Numero de iteraciones necesitados

            % Cargas internas guardadas
            pInt = nan(n, 1); % Carga efectiva de cada (P,phi)
            mxInt = nan(n, 1); % Momento por cada (P,phi)
            myInt = nan(n, 1); % Momento por cada (P,phi)
            reversePorcent = ''; % Texto que tiene el porcentaje de avance
            useFixedJacobian = 0;

            % Aplicacion de carga
            for i = 1:n
                valid = true;

                % Inicializa el Jacobiano para este paso
                if i == 1
                    jac = obj.get_jacobian(section, defTotal(max(i-1, 1)), phix(i), phiy(i), false, NaN);
                    if isnan(jac)
                        break;
                    end
                else
                    jac = jacIter(1, 1);
                end
                jacIter(i, 1) = jac;
                deltaE0Iter(i, 1) = jac * deltaP(i);

                % Iteración de Newton-Raphson
                for j = 1:(obj.maxiter - 1)
                    iters(i) = iters(i) + 1;

                    % Actualiza la deformacion total
                    if i > 1
                        defTotal(i) = defTotal(i-1) + sum(deltaE0Iter(i, :));
                    else
                        defTotal(i) = sum(deltaE0Iter(i, :));
                    end

                    % Calcula la fuerza interna
                    p = section.calcP(defTotal(i), phix(i), phiy(i));
                    if isnan(p)
                        valid = false;
                        break;
                    end
                    pE0(i, j) = p;

                    % Calcula el error entre carga aproximada y exacta
                    err(i, j) = P(i) - p;
                    if abs(err(i, j)) < obj.tol && (i > 1 && p ~= 0 || i == 1 && p == 0)
                        break;
                    end

                    % Nuevo Jacobiano
                    jacNew = obj.get_jacobian(section, defTotal(i), phix(i), phiy(i), useFixedJacobian > 0, jacIter(i, j));
                    if isnan(jacNew)
                        valid = false;
                        break;
                    end

                    jacIter(i, j+1) = jacNew;
                    deltaE0Iter(i, j+1) = jacNew * err(i, j);

                    % Chequeo de estabilidad
                    if j > 1 && (abs(deltaE0Iter(i, j+1)) > abs(deltaE0Iter(i, j)) || (p == 0 && i > 1 && useFixedJacobian == 0))
                        % Fuerza uso de primer Jacobiano a partir del próximo paso
                        if i > 1 && j > 0.9 * obj.maxiter && useFixedJacobian == 0
                            deltaE0Iter(i, :) = 0;
                            useFixedJacobian = i;
                            j = 0; %#ok<FXSET>
                        else
                            jacIter(i, j+1) = jacIter(i, j) * 0.5;
                            j = j - 1; %#ok<FXSET>
                        end
                    end
                end % Iteraciones Newton-Raphson

                if ~valid
                    section.callEvents(defTotal(i), phix(i), phiy(i), pInt(i), mxInt(i), myInt(i), iters(i));
                    i = i - 1; %#ok<FXSET>
                    break;
                end

                % Actualiza deformacion total
                if i > 1
                    defTotal(i) = defTotal(i-1) + sum(deltaE0Iter(i, :));
                else
                    defTotal(i) = sum(deltaE0Iter(i, :));
                end

                % Guarda P y momentos
                pInt(i) = pE0(i, j);
                mxInt(i) = section.calcMx(defTotal(i), phix(i), phiy(i), P(i), r.ppos);
                myInt(i) = section.calcMy(defTotal(i), phix(i), phiy(i), P(i), r.ppos);

                % Escribe el porcentaje
                if obj.showprogress
                    msg = sprintf('\tCalculando... (%.1f/100)', i/n*100);
                    fprintf([reversePorcent, msg]);
                    reversePorcent = repmat(sprintf('\b'), 1, length(msg));
                end

                % Llama a eventos
                section.callEvents(defTotal(i), phix(i), phiy(i), pInt(i), mxInt(i), myInt(i), iters(i));
            end

            % Verifica si las iteraciones fueron completadas
            if i ~= n
                fprintf('\nProceso terminado por problemas de material. Ultimo paso valido: %d', i);
            end

            % Guarda la solucion
            obj.lastsole0p = {mxInt, myInt, phix, phiy, pInt, P, pE0, ...
                section, iters, r.calcE0Mmode, r.calcE0Mangle, r.calcE0Mphi, ...
                defTotal, i};

            % Imprime resultados
            fprintf('\n');
            fprintf('\tIteraciones totales: %d\n', sum(iters));
            if useFixedJacobian > 0
                fprintf('\tUsando primera matriz rigidez desde i: %d\n', useFixedJacobian);
            end
            fprintf('\tProceso finalizado en %.2f segundos\n', cputime-tIni);
            dispMCURV();

        end % calc_e0M function

        function [defTotal, mxInt, myInt, pInt, err, iters, jacIter] = calc_e0M_angle(obj, section, p, phi, angle, varargin)
            % calc_e0M_Angle: Calcula e0 y M dado un arreglo de cargas, una
            % curvatura y un angulo de analisis de la curvatura
            %
            % Parametros:
            %   section         Objeto de la seccion de analisis
            %   p               Arreglo de cargas
            %   phi             Vector de curvatura
            %   angle           Angulo de analisis de la curvatura (grados)
            %
            % Parametros opcionales:
            %   ppos            Posicion de la carga, si no se define se deja en el centroide de la seccion

            if nargin < 5
                error('Numero de parametros incorrectos, uso: %s', ...
                    'calc_e0M_angle(section,p,phi,angle,varargin)');
            end

            if abs(angle) > 360
                error('El angulo debe ser entre 0 y 360 grados');
            end
            if angle == 360
                angle = 0;
            end

            phix = phi .* cos(-angle/180*pi());
            phiy = phi .* sin(-angle/180*pi());
            [defTotal, mxInt, myInt, pInt, err, iters, jacIter] = ...
                obj.calc_e0M(section, p, phix, phiy, varargin{:}, ...
                'calcE0Mmode', 'angle', 'calcE0Mangle', angle, ...
                'calcE0Mphi', phi);

        end % calc_e0M_angle function

        function plot_lastIter(obj)
            % plot_lastIter: Grafica el resultado de la ultima iteracion

            if isempty(obj.lastsole0p)
                error('Analisis e0M no ha sido ejecutado');
            end
            plt = figure();
            movegui(plt, 'center');
            set(gcf, 'name', 'Variacion numero iteraciones');
            hold on;
            secName = obj.lastsole0p{8}.getName();
            niter = obj.lastsole0p{9};

            plot(1:length(niter), niter, '-', 'Linewidth', 1.5);
            grid on;
            grid minor;

            xlabel('Numero de paso');
            ylabel('Numero de iteraciones');
            title({'Variacion numero iteraciones', secName});

        end % plot_lastIter function

        function plot_e0M(obj, varargin)
            % plot_e0M: Grafica el ultimo analisis de e0M
            %
            % Parametros opcionales:
            %   factorM         Factor de escala para el momento
            %   factorP         Factor de escala para la carga axial
            %   legend          Ubicacion de la leyenda
            %   limPos          Limita analisis a valores positivos
            %   linewidth       Ancho de linea de los graficos
            %   m               Eje analisis momento 'all','x','y','T'
            %   medfilt         Aplica medfilt
            %   medfiltN        Numero de filtro
            %   plot            Tipo de grafico
            %   sapcolumnM      Columna de momento del archivo
            %   sapcolumnPhi    Columna de curvatura del archivo
            %   sapdiff         Grafica la diferencia, solo para m:x/y
            %   sapfactorM      Factor multiplicacion archivo
            %   sapfactorPhi    Factor multiplicacion archivo
            %   sapfile         Carga un archivo, solo para m:x/y
            %   saplegend       Leyenda del archivo
            %   saplinewidth    Ancho de linea de grafico archivo
            %   unitlength      Unidad de longitud
            %   unitloadM       Unidad de carga para el momento
            %   unitloadP       Unidad de carga axial
            %   vecphi          Vector phi para interpolar
            %   vecphiColor     Cell phi colores
            %   vecphiInterp    Interpolacion, max,min,med,sqrt
            %   vecphiLw        Ancho de linea
            %   vecphiSize      Porte puntos

            tInit = cputime;
            p = inputParser;
            p.KeepUnmatched = true;
            p.addOptional('factorM', 1e-6); % Si se usan N*mm a kN-m
            p.addOptional('factorP', 1e-3); % Si se usan N a kN
            p.addOptional('legend', 'southeast');
            p.addOptional('limPos', true)
            p.addOptional('linewidth', 1);
            p.addOptional('m', 'T'); % Cual eje usar para el momento: all,x,y,T
            p.addOptional('medfilt', true); % Aplica medfilt
            p.addOptional('medfiltN', 3);
            p.addOptional('plot', 'all');
            p.addOptional('sapcolumnM', 2);
            p.addOptional('sapcolumnPhi', 1);
            p.addOptional('sapdiff', false);
            p.addOptional('sapfactorM', 1);
            p.addOptional('sapfactorPhi', 1);
            p.addOptional('sapfile', ''); % Archivo de sap
            p.addOptional('saplegend', 'SAP2000');
            p.addOptional('saplinewidth', 1); % Ancho de linea grafico sap
            p.addOptional('unitlength', '1/mm'); % Unidad de largo curvatura
            p.addOptional('unitloadM', 'kN*m'); % Unidad de carga
            p.addOptional('unitloadP', 'kN'); % Unidad de carga
            p.addOptional('vecphi', []); % Vector phi para interpolar
            p.addOptional('vecphiColor', {}); % Cell phi colores
            p.addOptional('vecphiInterp', 'min');
            p.addOptional('vecphiName', {}); % Cell phi nombres
            p.addOptional('vecphiLw', 0.5);
            p.addOptional('vecphiSize', 15);
            parse(p, varargin{:});
            r = p.Results;

            if isempty(obj.lastsole0p)
                error('Analisis e0M no ha sido ejecutado');
            end

            if length(r.vecphi) ~= length(r.vecphiColor)
                error('vecphi debe tener igual largo que sus colores vecphiColor');
            end

            fprintf('Graficando e0-M:\n');
            mxInt = abs(obj.lastsole0p{1}.*r.factorM);
            myInt = abs(obj.lastsole0p{2}.*r.factorM);
            phix = abs(obj.lastsole0p{3});
            phiy = abs(obj.lastsole0p{4});
            pInt = obj.lastsole0p{5} .* r.factorP;
            % pRre = obj.lastsole0p{6};
            % e0 = obj.lastsole0p{7};
            secName = obj.lastsole0p{8}.getName();
            % iters = obj.lastsole0p{9};
            mode = obj.lastsole0p{10};
            angle = obj.lastsole0p{11};
            phi = obj.lastsole0p{12};
            defTotal = obj.lastsole0p{13};
            fprintf('\tSeccion: %s\n', secName);

            % Aplica medfilt
            if r.medfilt
                mxInt = medfilt1(mxInt, r.medfiltN);
                myInt = medfilt1(myInt, r.medfiltN);
                pInt = medfilt1(pInt, r.medfiltN);
            end

            % Indica si se grafico
            doPlot = false;

            % Si se calculo con un angulo
            if strcmp(mode, 'angle')
                if strcmp(r.plot, 'all') || strcmp(r.plot, 'mphi')
                    obj.plot_e0M_mcurv(phi, mxInt, myInt, r, 'a', secName, angle);
                    doPlot = true;
                end
                if strcmp(r.plot, 'all') || strcmp(r.plot, 'pphi')
                    obj.plot_e0M_pcurv(phi, pInt, r, 'a', secName, angle);
                    doPlot = true;
                end
                if strcmp(r.plot, 'all') || strcmp(r.plot, 'ephi')
                    obj.plot_e0M_ecurv(phi, defTotal, r, 'a', secName, angle);
                    doPlot = true;
                end
            else
                if strcmp(r.plot, 'all') || strcmp(r.plot, 'mphix')
                    obj.plot_e0M_mcurv(phix, mxInt, myInt, r, 'x', secName, angle);
                    doPlot = true;
                end
                if strcmp(r.plot, 'all') || strcmp(r.plot, 'mphiy')
                    obj.plot_e0M_mcurv(phiy, mxInt, myInt, r, 'y', secName, angle);
                    doPlot = true;
                end
                if strcmp(r.plot, 'all') || strcmp(r.plot, 'pphix')
                    obj.plot_e0M_pcurv(phix, pInt, r, 'x', secName, angle);
                    doPlot = true;
                end
                if strcmp(r.plot, 'all') || strcmp(r.plot, 'pphiy')
                    obj.plot_e0M_pcurv(phiy, pInt, r, 'y', secName, angle);
                    doPlot = true;
                end
                if strcmp(r.plot, 'all') || strcmp(r.plot, 'ephix')
                    obj.plot_e0M_ecurv(phix, defTotal, r, 'x', secName, angle);
                    doPlot = true;
                end
                if strcmp(r.plot, 'all') || strcmp(r.plot, 'ephiy')
                    obj.plot_e0M_ecurv(phiy, defTotal, r, 'y', secName, angle);
                    doPlot = true;
                end
            end

            if ~doPlot
                if strcmp(mode, 'angle')
                    error('Tipo grafico incorrecto, valores plot: all,mphi,pphi,ephi');
                else
                    error('Tipo grafico incorrecto, valores plot: all,mphix,phiy,pphix,pphiy,ephix,ephiy');
                end
            end

            % Finaliza el grafico
            drawnow();
            fprintf('\tProceso finalizado en %.2f segundos\n', cputime-tInit);
            dispMCURV();

        end % plot_e0M function

        function plt = plotStress(obj, i, varargin)
            % plotStress: Grafica los esfuerzos de la seccion ante un punto
            % especifico i
            %
            % Parametros requeridos:
            %   i               Punto de evaluacion
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

            if isempty(obj.lastsole0p)
                error('Analisis e0M no ha sido ejecutado');
            end

            if nargin < 1
                error('Numero de parametros incorrectos, uso: %s', ...
                    'plotStress(i,varargin)');
            end

            phix = obj.lastsole0p{3};
            phiy = obj.lastsole0p{4};
            e0 = obj.lastsole0p{13};
            section = obj.lastsole0p{8};
            mode = obj.lastsole0p{10};
            angle = obj.lastsole0p{11};
            maxi = obj.lastsole0p{14};
            if i > maxi
                warning('Punto de evaluacion excede el maximo %d', maxi);
                i = maxi;
            end

            if strcmp(mode, 'angle')
                plt = section.plotStress(e0, phix, phiy, varargin{:}, 'i', i, ...
                    'angle', angle, 'mode', 'a');
            else
                plt = section.plotStress(e0, phix, phiy, varargin{:}, 'i', i, ...
                    'mode', 'xy');
            end

        end % plotStress function

        function plt = plotStrain(obj, i, varargin)
            % plotStrain: Grafica la deformacion de la seccion ante un punto
            % especifico i
            %
            % Parametros requeridos:
            %   i               Punto de evaluacion
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

            if isempty(obj.lastsole0p)
                error('Analisis e0M no ha sido ejecutado');
            end

            if nargin < 1
                error('Numero de parametros incorrectos, uso: %s', ...
                    'plotStress(i,varargin)');
            end

            phix = obj.lastsole0p{3};
            phiy = obj.lastsole0p{4};
            e0 = obj.lastsole0p{13};
            section = obj.lastsole0p{8};
            mode = obj.lastsole0p{10};
            angle = obj.lastsole0p{11};

            if strcmp(mode, 'angle')
                plt = section.plotStrain(e0, phix, phiy, varargin{:}, 'i', i, ...
                    'angle', angle, 'mode', 'a');
            else
                plt = section.plotStrain(e0, phix, phiy, varargin{:}, 'i', i, ...
                    'mode', 'xy');
            end

        end % plotStrain function

        function disp(obj)
            % disp: Imprime la informacion del objeto en consola

            fprintf('Analisis de seccion:\n');
            disp@BaseModel(obj);

        end % disp function

    end % public methods

    methods (Access = private)

        function jac = get_jacobian(~, section, e0, phix, phiy, useFixed, jac0)
            % get_jacobian: Obtiene el jacobiano de una seccion
            if useFixed
                jac = jac0; % Usar primera pendiente
            else
                jac = section.calcJac(e0, phix, phiy);
                if isnan(jac)
                    jac = NaN;
                else
                    jac = 1 / jac(1, 1);
                end
            end
        end % get_jacobian function

        function plot_e0M_mcurv(obj, phi, mxInt, myInt, r, curvAxis, secName, angle) %#ok<INUSL>
            % plot_e0M_mcurv: Grafica momento curvatura

            if min(phi) == max(phi)
                warning('Vector de curvatura phi no posee variacion');
                return;
            end

            plt = figure();
            movegui(plt, 'center');
            set(gcf, 'name', 'Momento curvatura');
            hold on;
            leg = {};

            % Carga sap
            if ~strcmp(r.sapfile, '')
                sapF = load(r.sapfile);
                sapPhi = sapF(:, r.sapcolumnPhi) .* r.sapfactorPhi;
                sapM = sapF(:, r.sapcolumnM) .* r.sapfactorM;
                sapMint = interp1(sapPhi, sapM, phi, 'linear', 'extrap');
                if max(sapPhi) < max(phi)
                    for i = 1:length(phi)
                        if phi(i) >= max(sapPhi)
                            phiF = phi(1:i);
                            sapMintF = sapMint(1:i);
                            break;
                        end
                    end
                else
                    phiF = phi;
                    sapMintF = sapMint;
                end
                plot(phiF, sapMintF, '-', 'LineWidth', r.saplinewidth);
                if ~strcmp(r.saplegend, '')
                    leg{length(leg)+1} = r.saplegend;
                end
            end

            % Grafica las curvas
            if strcmp(r.m, 'all')
                plot(phi, mxInt, '-', 'LineWidth', r.linewidth);
                plot(phi, myInt, '-', 'LineWidth', r.linewidth);
                leg{length(leg)+1} = 'M_x';
                leg{length(leg)+1} = 'M_y';
                mAxis = 'M'; % Eje del momento a mostrar en el titulo
            elseif strcmp(r.m, 'x')
                plot(phi, mxInt, '-', 'LineWidth', r.linewidth);
                leg{length(leg)+1} = 'M_x';
                mAxis = 'M_x';
                m = mxInt;
            elseif strcmp(r.m, 'y')
                plot(phi, myInt, '-', 'LineWidth', r.linewidth);
                leg{length(leg)+1} = 'M_y';
                mAxis = 'M_y';
                m = myInt;
            elseif strcmp(r.m, 'T')
                mtInt = sqrt(mxInt.^2+myInt.^2);
                plot(phi, mtInt, '-', 'LineWidth', r.linewidth);
                leg{length(leg)+1} = 'M_T';
                mAxis = 'M_T';
                m = mtInt;
            else
                error('Valor incorrecto parametro m: all,x,y,T');
            end

            % Ajusta el grafico
            grid on;
            grid minor;
            if ~strcmp(curvAxis, 'a')
                title(sprintf('Momento curvatura %s/\\phi_%s - %s', mAxis, curvAxis, secName));
                xlabel(sprintf('Curvatura \\phi_%s (%s)', curvAxis, r.unitlength));
            else
                title({sprintf('Momento curvatura %s/\\phi - Angulo %.1f', mAxis, angle), secName});
                xlabel(sprintf('Curvatura \\phi (%s)', r.unitlength));
            end
            ylabel(sprintf('Momento %s (%s)', mAxis, r.unitloadM));
            legend(leg, 'location', r.legend);
            if r.limPos
                ylim([0, max(get(gca, 'ylim'))]);
            end
            xlim([min(phi), max(phi)]);

            % Obtiene los limites
            ylm = get(gca, 'ylim');
            mmin = min(ylm);

            % Calcula las interpolaciones
            kphi = 1; % Numero de puntos agregados
            if (strcmp(r.m, 'x') || strcmp(r.m, 'y') || strcmp(r.m, 'T'))
                for i = 1:length(r.vecphi)

                    % Recorre cada curvatura para buscar el objetivo y
                    % graficarlo, si no lo encuentra escribe en la consola
                    mi = 0;
                    phiobj = abs(r.vecphi(i));
                    if phiobj == Inf
                        continue;
                    end
                    for j = 1:length(phi) - 1
                        if phi(j) <= phiobj && isnan(m(j+1))
                            mi = m(j);
                            break;
                        elseif phi(j) <= phiobj && phiobj <= phi(j+1)
                            if strcmp(r.vecphiInterp, 'min')
                                mi = min(m(j), m(j+1));
                            elseif strcmp(r.vecphiInterp, 'max')
                                mi = max(m(j), m(j+1));
                            elseif strcmp(r.vecphiInterp, 'med')
                                mi = 0.5 * (m(j) + m(j+1));
                            elseif strcmp(r.vecphiInterp, 'sqrt')
                                mi = sqrt((m(j)^2 + m(j+1)^2)/2);
                            else
                                error('Interpolacion vecphiInterp desconocida, valores posibles: min,max,med,sqrt');
                            end
                            break;
                        end
                    end

                    % Grafica el punto
                    if mi ~= 0
                        if length(r.vecphiName) == length(r.vecphi)
                            phiname = strcat(r.vecphiName{i}, ': ');
                        else
                            phiname = '';
                        end
                        fprintf('\tphi (%d) %e: Momento %f %s\n', kphi, phiobj, mi, r.unitloadM);
                        plot([phiobj, phiobj], [mmin, mi], '--', ...
                            'Color', r.vecphiColor{i}, 'LineWidth', r.vecphiLw, ...
                            'DisplayName', sprintf('%s\\phi_%d=%.2e, M_%d=%.1f', phiname, kphi, phiobj, kphi, mi));
                        pl = plot([min(phi), phiobj], [mi, mi], '--', ...
                            'Color', r.vecphiColor{i}, 'LineWidth', r.vecphiLw);
                        set(get(get(pl, 'Annotation'), 'LegendInformation'), 'IconDisplayStyle', 'off');
                        pl = plot(phiobj, mi, '.', ...
                            'Color', r.vecphiColor{i}, 'LineWidth', r.vecphiLw, ...
                            'MarkerSize', r.vecphiSize);
                        set(get(get(pl, 'Annotation'), 'LegendInformation'), 'IconDisplayStyle', 'off');
                        kphi = kphi + 1;
                    end

                end
            end

            % Genera la diferencia
            if ~strcmp(r.sapfile, '') && r.sapdiff && ...
                    (strcmp(r.m, 'x') || strcmp(r.m, 'y') || strcmp(r.m, 'T'))

                % Diferencia absoluta
                plt = figure();
                movegui(plt, 'center');
                set(gcf, 'name', 'Diferencia entre archivo y calculo');
                hold on;
                if strcmp(r.m, 'x')
                    mInt = mxInt;
                elseif strcmp(r.m, 'x')
                    mInt = myInt;
                elseif strcmp(r.m, 'T')
                    mInt = sqrt(mxInt.^2+myInt.^2);
                end

                mDiff = zeros(1, length(phi));
                for i = 1:length(phi)
                    mDiff(i) = sapMint(i) - mInt(i);
                end
                plot(phi, mDiff, 'k-', 'LineWidth', r.linewidth);

                grid on;
                grid minor;
                if ~strcmp(curvAxis, 'a')
                    xlabel(sprintf('Curvatura \\phi_%s (%s)', curvAxis, r.unitlength));
                else
                    xlabel(sprintf('Curvatura \\phi (%s)', r.unitlength));
                end
                ylabel(sprintf('Diferencia momento %s (%s)', mAxis, r.unitloadM));
                title({'Diferencia momento absoluta', secName});
                xlim([min(phi), max(phi)]);

                % Diferencia relativa
                plt = figure();
                movegui(plt, 'center');
                set(gcf, 'name', 'Diferencia entre archivo y calculo');
                hold on;
                mDiffAbs = (mDiff ./ sapMint) .* 100;
                mDiffAbs = medfilt1(mDiffAbs, r.medfiltN);
                plot(phi, mDiffAbs, 'k-', 'LineWidth', r.linewidth);
                grid on;
                grid minor;
                if ~strcmp(curvAxis, 'a')
                    xlabel(sprintf('Curvatura \\phi_%s (%s)', curvAxis, r.unitlength));
                else
                    xlabel(sprintf('Curvatura \\phi (%s)', r.unitlength));
                end
                ylabel('Diferencia momento (%)');
                title({'Diferencia momento relativa', secName});
                xlim([min(phi), max(phi)]);

            end

        end % plot_e0M_mcurv function

        function plot_e0M_pcurv(obj, phi, pInt, r, curvAxis, secName, angle) %#ok<INUSL>
            % plot_e0M_pcurv: Grafica carga curvatura

            if min(phi) == max(phi)
                warning('Vector de curvatura phi no posee variacion');
                return;
            end
            plt = figure();
            movegui(plt, 'center');
            set(gcf, 'name', sprintf('P vs \\phi_%s', curvAxis));
            plot(phi, pInt, '-', 'LineWidth', r.linewidth);
            grid on;
            grid minor;
            ylabel(sprintf('Carga axial interna P_{int} (%s)', r.unitloadP));

            if ~strcmp(curvAxis, 'a')
                title({sprintf('Carga axial interna vs curvatura \\phi_%s', curvAxis), secName});
                xlabel(sprintf('Curvatura \\phi_%s (%s)', curvAxis, r.unitlength));
            else
                title({sprintf('Carga axial interna vs curvatura \\phi - Angulo %.1f', angle), secName});
                xlabel(sprintf('Curvatura \\phi (%s)', r.unitlength));
            end
            if r.limPos
                ylim([0, max(get(gca, 'ylim'))]);
            end
            xlim([min(phi), max(phi)]);

        end % plot_e0M_pcurv function

        function plot_e0M_ecurv(obj, phi, pInt, r, curvAxis, secName, angle) %#ok<INUSL>
            % plot_e0M_ecurv: Grafica deformacion

            if min(phi) == max(phi)
                warning('Vector de curvatura phi no posee variacion');
                return;
            end
            plt = figure();
            movegui(plt, 'center');
            set(gcf, 'name', sprintf('e_0 vs \\phi_%s', curvAxis));
            plot(phi, pInt, '-', 'LineWidth', r.linewidth);
            grid on;
            grid minor;
            ylabel('Deformacion e_0 (-)');

            if ~strcmp(curvAxis, 'a')
                title({sprintf('Deformacion vs curvatura \\phi_%s', curvAxis), secName});
                xlabel(sprintf('Curvatura \\phi_%s (%s)', curvAxis, r.unitlength));
            else
                title({sprintf('Deformacion vs curvatura \\phi - Angulo %.1f', angle), secName});
                xlabel(sprintf('Curvatura \\phi (%s)', r.unitlength));
            end
            if r.limPos
                ylim([0, max(get(gca, 'ylim'))]);
            end
            xlim([min(phi), max(phi)]);

        end % plot_e0M_ecurv function

    end % private methods

end % SectionAnalysis class