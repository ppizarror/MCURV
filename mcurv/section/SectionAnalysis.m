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
    
    properties(Access = protected)
        maxiter % Numero maximo de iteraciones
        tol % Tolerancia del calculo
        lastsole0p % Ultima solucion de e0/P
        showprogress % Muestra el progreso en consola
    end % protected properties
    
    methods(Access = public)
        
        function obj = SectionAnalysis(analysisName, maxiter, tol, varargin)
            % SectionAnalysis: Constructor de la clase
            %
            % Parametros opcionales:
            %   showprogress        Muestra el porcentaje de progreso
            
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
        
        function [defTotal, mxInt, myInt, pInt, err, iters] = calc_e0M(obj, section, p, phix, phiy, ppos)
            % calc_e0M: Calcula e0 y M dado un arreglo de cargas y
            % curvaturas
            %
            % Parametros:
            %   section         Objeto de la seccion de analisis
            %   p               Arreglo de cargas
            %   phix            Vector de curvatura en x
            %   phiy            Vector de curvatura en y
            %   ppos            Posicion de la carga, si no se define se
            %                   deja en el centroide de la seccion
            
            if nargin < 5
                error('Numero de parametros incorrectos, uso: %s', ...
                    'calc_e0M(section,p,phix,phiy,ppos)');
            end
            
            if ~isa(section, 'SectionDesigner')
                error('Objeto seccion debe heredar de SectionDesigner');
            end
            
            if length(p) ~= length(phix) || length(p) ~= length(phiy)
                error('Los vectores p, phix, phiy deben tener igual largo');
            end
            
            fprintf('Calculando e0 y M dado arreglo de P y phix,phiy:\n');
            fprintf('\tSeccion: %s\n', section.getName());
            
            % Actualiza propiedades
            section.updateProps();
            
            [px, py] = section.getCentroid();
            if ~exist('ppos', 'var')
                ppos = [px, py];
            end
            
            pcentroid = '';
            if ppos(1) == px && ppos(2) == py
                pcentroid = ' ubicado en centroide';
            end
            
            fprintf('\tCarga externa posicion: (%.2f,%.2f)%s\n', ...
                ppos(1), ppos(2), pcentroid);
            
            % Genera el vector de cambio de P
            n = length(p);
            delta_p = zeros(n, 1);
            delta_p(1) = p(1);
            for i = 2:n
                delta_p(i) = p(i) - p(i-1);
            end
            
            % Crea matriz de iteraciones de la deformacion total
            deltaE0Iter = zeros(n, obj.maxiter);
            pE0 = zeros(n, obj.maxiter);
            jacIter = zeros(n, obj.maxiter); % Jacobiano (rigidez)
            
            defTotal = zeros(n, 1); % Deformacion total para cada [P,phi]_i
            err = zeros(n, obj.maxiter); % Error de cada iteracion
            
            iters = zeros(n, 1); % Numero de iteraciones necesitados
            
            % Cargas internas guardadas
            pInt = zeros(n, 1); % Carga efectiva de cada (P,phi)
            mxInt = zeros(n, 1); % Momento por cada (P,phi)
            myInt = zeros(n, 1); % Momento por cada (P,phi)
            reverse_porcent = ''; % Texto que tiene el porcentaje de avance
            
            % Variable que indica que las iteraciones se hacen con la primera
            % pendiente de la matriz de rigidez
            usar1JAC = false;
            
            % Almacena desde que i-incremento se usa el primer jacobiano
            usar1JACNITER = 1;
            
            % Aplicacion de carga
            for i = 1:n
                
                % Iteracion con variacion del jacobiano
                if ~usar1JAC
                    
                    % Calcula el primer delta_eo, considera deformacion total como la suma
                    % de los delta_e0 de cada iteracion
                    jac = section.calcJac(defTotal(i), phix(i), phiy(i));
                    jac = jac(1, 1); % Solo escata aP/ae0
                    jac = jac^-1;
                    jacIter(i, 1) = jac(1, 1);
                    deltaE0Iter(i, 1) = jacIter(i, 1) * delta_p(i);
                    
                    for j = 1:(obj.maxiter - 1)
                        
                        % Incrementa iteracion
                        iters(i) = iters(i) + 1;
                        
                        % Actualiza deformacion total
                        if i > 1
                            defTotal(i) = defTotal(i-1) + sum(deltaE0Iter(i, :));
                        else
                            defTotal(i) = sum(deltaE0Iter(i, :));
                        end
                        
                        % Calcula la fuerza interna
                        pE0(i, j) = section.calcP(defTotal(i), phix(i), phiy(i));
                        
                        % Calcula el error entre carga aproximada y exacta
                        err(i, j) = p(i) - pE0(i, j);
                        if abs(err(i, j)) < obj.tol && (i > 1 && pE0(i, j) ~= 0) || (i == 1 && pE0(i, j) == 0)
                            break;
                        end
                        
                        % Si es mayor a la tolerancia
                        jac = section.calcJac(sum(deltaE0Iter(i, :)), phix(i), phiy(i));
                        jac = jac(1, 1); % Solo escata aP/ae0
                        jac = jac^-1;
                        jacIter(i, j+1) = jac(1, 1);
                        deltaE0Iter(i, j+1) = jacIter(i, j+1) * err(i, j);
                        
                        % Si se pasa del error detiene y usa la pendiente del primer
                        % intervalo
                        if j > 1 && (abs(deltaE0Iter(i, j+1)) > abs(deltaE0Iter(i, j))) || (pE0(i, j) == 0 && i > 1)
                            for jj = 1:j + 1
                                deltaE0Iter(i, jj) = 0;
                            end
                            usar1JAC = true;
                            jacIter(i, 1) = jacIter(1, 1);
                            usar1JACNITER = i;
                            break;
                        end
                        
                    end
                    
                else % Itera con la primera pendiente
                    
                    % Asigna el primer jacobiano
                    jacIter(i, 1) = jacIter(1, 1);
                    
                    for j = 1:(obj.maxiter - 1)
                        
                        % Incrementa iteracion
                        iters(i) = iters(i) + 1;
                        
                        % Actualiza deformacion total
                        if i > 1
                            defTotal(i) = defTotal(i-1) + sum(deltaE0Iter(i, :));
                        else
                            defTotal(i) = sum(deltaE0Iter(i, :));
                        end
                        
                        % Calcula la fuerza interna [N]
                        pE0(i, j) = section.calcP(defTotal(i), phix(i), phiy(i));
                        
                        % Calcula el error entre carga aproximada y exacta
                        err(i, j) = p(i) - pE0(i, j);
                        if abs(err(i, j)) < obj.tol
                            break;
                        end
                        
                        % Si es mayor a la tolerancia
                        jacIter(i, j+1) = jacIter(i, j); % Puede ser jac_iter(i, 1)
                        deltaE0Iter(i, j+1) = jacIter(i, j+1) * err(i, j);
                        
                        % Si se pasa del error detiene y usa el j anterior
                        if j > 1 && (abs(deltaE0Iter(i, j+1)) > abs(deltaE0Iter(i, j)))
                            jacIter(i, j) = 0.5 * jacIter(i, j-1);
                            j = j - 1; %#ok<FXSET>
                        end
                        
                    end
                    
                end
                
                % Actualiza deformacion total
                if i > 1
                    defTotal(i) = defTotal(i-1) + sum(deltaE0Iter(i, :));
                else
                    defTotal(i) = sum(deltaE0Iter(i, :));
                end
                
                % Guarda el P calculado
                pInt(i) = pE0(i, j);
                
                % Calcula el momento
                mxInt(i) = section.calcMx(defTotal(i), phix(i), phiy(i), p(i), ppos);
                myInt(i) = section.calcMy(defTotal(i), phix(i), phiy(i), p(i), ppos);
                
                % Escribe el porcentaje
                if obj.showprogress
                    msg = sprintf('\tCalculando... (%.1f/100)', i/n*100);
                    fprintf([reverse_porcent, msg]);
                    reverse_porcent = repmat(sprintf('\b'), 1, length(msg));
                end
                
            end
            
            % Imprime resultados
            fprintf('\n');
            fprintf('\tIteraciones totales: %d\n', sum(iters));
            fprintf('\tUsado primera matriz rigidez desde i: %d\n', usar1JACNITER);
            
            % Guarda la solucion
            obj.lastsole0p = {mxInt, myInt, phix, phiy, pInt, p, pE0, section.getName()};
            
        end % calc_e0M function
        
        function plot_e0M(obj, varargin)
            % plot_e0M: Grafica el ultimo analisis de e0M
            %
            % Parametros opcionales:
            %   factor          Factor de escala para el momento
            %   legend          Ubicacion de la leyenda
            %   limPos          Limita analisis a valores positivos
            %   m               Que eje usar, 'x', 'y'
            %   medfilt         Aplica medfilt
            %   medfiltN        Numero de filtro
            %   plot            Tipo de grafico
            %   sapcolumnM      Columna de momento del archivo
            %   sapcolumnPhi    Columna de curvatura del archivo
            %   sapfactorM      Factor multiplicacion archivo
            %   sapfactorPhi    Factor multiplicacion archivo
            %   sapfile         Carga un archivo de resultados (phi-M)
            %   saplegend       Leyenda del archivo
            %   unitlength      Unidad de longitud
            %   unitload        Unidad de carga
            
            p = inputParser;
            p.KeepUnmatched = true;
            p.addOptional('factor', 1); % Si se usan N*mm a tonf-m
            p.addOptional('legend', 'southeast');
            p.addOptional('limPos', true)
            p.addOptional('m', 'all'); % Cual eje usar
            p.addOptional('medfilt', true); % Aplica medfilt
            p.addOptional('medfiltN', 3);
            p.addOptional('plot', 'all');
            p.addOptional('sapcolumnM', 2);
            p.addOptional('sapcolumnPhi', 1);
            p.addOptional('sapfactorM', 1);
            p.addOptional('sapfactorPhi', 1);
            p.addOptional('sapfile', ''); % Archivo de sap
            p.addOptional('saplegend', 'SAP2000');
            p.addOptional('unitlength', '1/mm'); % Unidad de largo
            p.addOptional('unitload', 'kN*m'); % Unidad de carga
            parse(p, varargin{:});
            r = p.Results;
            
            if isempty(obj.lastsole0p)
                error('Analisis e0M no ha sido ejecutado');
            end
            
            mxInt = obj.lastsole0p{1} .* r.factor;
            myInt = obj.lastsole0p{2} .* r.factor;
            pInt = obj.lastsole0p{5};
            % pRre = obj.lastsole0p{6};
            phix = obj.lastsole0p{3};
            phiy = obj.lastsole0p{4};
            % e0 = obj.lastsole0p{7};
            secName = obj.lastsole0p{8};
            
            % Aplica medfilt
            if r.medfilt
                mxInt = medfilt1(mxInt, r.medfiltN);
                myInt = medfilt1(myInt, r.medfiltN);
            end
            
            if strcmp(r.plot, 'all') || strcmp(r.plot, 'mphiy')
                plt = figure();
                movegui(plt, 'center');
                set(gcf, 'name', 'Momento curvatura');
                hold on;
                if strcmp(r.m, 'all')
                    plot(phiy, mxInt, '-', 'LineWidth', 1.5);
                    plot(phiy, myInt, '-', 'LineWidth', 1.5);
                    leg = {'M_x', 'M_y'};
                elseif strcmp(r.m, 'x')
                    plot(phiy, mxInt, '-', 'LineWidth', 1.5);
                    leg = {'M_x'};
                elseif strcmp(r.m, 'y')
                    plot(phiy, myInt, '-', 'LineWidth', 1.5);
                    leg = {'M_y'};
                else
                    error('Valor incorrecto parametro m: all,x,y');
                end
                
                % Carga sap
                if ~strcmp(r.sapfile, '')
                    sapF = load(r.sapfile);
                    sapPhi = sapF(:, r.sapcolumnPhi) .* r.sapfactorPhi;
                    sapM = sapF(:, r.sapcolumnM) .* r.sapfactorM;
                    sapMint = interp1(sapPhi, sapM, phiy, 'linear', 'extrap');
                    plot(phiy, sapMint, '-', 'LineWidth', 1.5);
                    if ~strcmp(r.saplegend, '')
                        leg{length(leg)+1} = r.saplegend;
                    end
                end
                
                grid on;
                grid minor;
                xlabel(sprintf('Curvatura \\phi_y (%s)', r.unitlength));
                ylabel(sprintf('Momento M (%s)', r.unitload));
                title(sprintf('Momento curvatura M/\\phi_y - %s', secName));
                legend(leg, 'location', r.legend);
                if r.limPos
                    ylim([0, max(get(gca, 'ylim'))]);
                end
            end
            
            if strcmp(r.plot, 'all') || strcmp(r.plot, 'mphix')
                plt = figure();
                movegui(plt, 'center');
                set(gcf, 'name', 'Momento curvatura');
                hold on;
                if strcmp(r.m, 'all')
                    plot(phix, mxInt, '-', 'LineWidth', 1.5);
                    plot(phix, myInt, '-', 'LineWidth', 1.5);
                    leg = {'M_x', 'M_y'};
                elseif strcmp(r.m, 'x')
                    plot(phix, mxInt, '-', 'LineWidth', 1.5);
                    leg = {'M_x'};
                elseif strcmp(r.m, 'y')
                    plot(phix, myInt, '-', 'LineWidth', 1.5);
                    leg = {'M_y'};
                else
                    error('Valor incorrecto parametro m: all,x,y');
                end
                
                % Carga sap
                if ~strcmp(r.sapfile, '')
                    sapF = load(r.sapfile);
                    sapPhi = sapF(:, r.sapcolumnPhi) .* r.sapfactorPhi;
                    sapM = sapF(:, r.sapcolumnM) .* r.sapfactorM;
                    sapMint = interp1(sapPhi, sapM, phix, 'linear', 'extrap');
                    plot(phix, sapMint, '-', 'LineWidth', 1.5);
                    if ~strcmp(r.saplegend, '')
                        leg{length(leg)+1} = r.saplegend;
                    end
                end
                
                grid on;
                grid minor;
                xlabel(sprintf('Curvatura \\phi_x (%s)', r.unitlength));
                ylabel(sprintf('Momento M (%s)', r.unitload));
                title(sprintf('Momento curvatura M/\\phi_x - %s', secName));
                legend(leg, 'location', r.legend);
                if r.limPos
                    ylim([0, max(get(gca, 'ylim'))]);
                end
            end
            
            if strcmp(r.plot, 'all') || strcmp(r.plot, 'pphix')
                plt = figure();
                movegui(plt, 'center');
                set(gcf, 'name', 'P vs \phi_x');
                plot(phix, pInt, '-', 'LineWidth', 1.5);
                grid on;
                grid minor;
                xlabel(sprintf('Curvatura \\phi_x (%s)', r.unitload));
                ylabel('Carga axial P');
                title(sprintf('Carga axial vs curvatura \\phi_x - %s', secName));
                if r.limPos
                    ylim([0, max(get(gca, 'ylim'))]);
                end
            end
            
            if strcmp(r.plot, 'all') || strcmp(r.plot, 'pphiy')
                plt = figure();
                movegui(plt, 'center');
                set(gcf, 'name', 'P vs \phi_y');
                plot(phiy, pInt, '-', 'LineWidth', 1.5);
                grid on;
                grid minor;
                xlabel(sprintf('Curvatura \\phi_y (%s)', r.unitload));
                ylabel('Carga axial P');
                title(sprintf('Carga axial vs curvatura \\phi_y - %s', secName));
                if r.limPos
                    ylim([0, max(get(gca, 'ylim'))]);
                end
            end
            
            % Finaliza el grafico
            drawnow();
            
        end % plote_0M function
        
        function disp(obj)
            % disp: Imprime la informacion del objeto en consola
            
            fprintf('Analisis de seccion:\n');
            disp@BaseModel(obj);
            
        end % disp function
        
    end % public methods
    
end % SectionAnalysis class