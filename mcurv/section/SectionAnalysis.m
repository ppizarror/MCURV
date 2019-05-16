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
    end % protected properties
    
    methods(Access = public)
        
        function obj = SectionAnalysis(analysisName, maxiter, tol)
            % SectionAnalysis: Constructor de la clase
            
            obj = obj@BaseModel(analysisName);
            obj.maxiter = maxiter;
            obj.tol = tol;
            obj.lastsole0p = {};
            
        end % SectionAnalysis constructor
        
        function [mxInt, myInt, pInt, pE0, jacIter, deltaE0Iter, ...
                err, defTotal, problmIter, iters] = calc_e0M(obj, section, p, phix, phiy)
            % calc_e0M: Calcula e0 y M dado un arreglo de cargas y
            % curvaturas
            
            fprintf('Calculando e0 y M dado arreglo de P y phix,phiy\n');
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
            problmIter = zeros(n, 1); % Indica que iteracion tuvo problemas
            
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
                mxInt(i) = section.calcMx(defTotal(i), phix(i), phiy(i));
                myInt(i) = section.calcMy(defTotal(i), phix(i), phiy(i));
                
                % Escribe el porcentaje
                msg = sprintf('\tCalculando... (%.1f/100)', i/n*100);
                fprintf([reverse_porcent, msg]);
                reverse_porcent = repmat(sprintf('\b'), 1, length(msg));
                
            end
            
            % Imprime resultados
            fprintf('\n');
            fprintf('\tIteraciones totales: %d\n', sum(iters));
            fprintf('\tUsado primera matriz rigidez desde i: %d\n', usar1JACNITER);
            
            % Guarda la solucion
            obj.lastsole0p = {mxInt, myInt, phix, phiy, pInt, p, pE0};
            
        end % calc_e0M function
        
        function plot_e0M(obj, varargin)
            % plot_e0M: Grafica el ultimo analisis de e0M
            %
            % Parametros opcionales:
            %   scalefactor     Factor de escala para el momento
            
            p = inputParser;
            p.KeepUnmatched = true;
            p.addOptional('scalefactor', 0.00010197162129779283 / 1000); % Si se usan N*mm a tonf-m
            p.addOptional('plot', 'all');
            parse(p, varargin{:});
            r = p.Results;
            
            if isempty(obj.lastsole0p)
                error('Analisis e0M no ha sido ejecutado');
            end
            
            if strcmp(r.plot, 'all') || strcmp(r.plot, 'mphiy')
                plt = figure();
                movegui(plt, 'center');
                set(gcf, 'name', 'Momento curvatura');

                plot(obj.lastsole0p{4}, obj.lastsole0p{1}.*r.scalefactor, '-', ...
                    'LineWidth', 1.5);
                hold on;
                plot(obj.lastsole0p{4}, obj.lastsole0p{2}.*r.scalefactor, '-', ...
                    'LineWidth', 1.5);
                grid on;
                grid minor;
                xlabel('Curvatura \phi_y (1/mm])');
                ylabel('Momento M (tonf-m)');
                title('Momento curvatura M/\phi_y');
                legend({'M_x', 'M_y'}, 'location', 'best');
            end
            
            if strcmp(r.plot, 'all') || strcmp(r.plot, 'mphix')
                plt = figure();
                movegui(plt, 'center');
                set(gcf, 'name', 'Momento curvatura');

                plot(obj.lastsole0p{3}, obj.lastsole0p{1}.*r.scalefactor, '-', ...
                    'LineWidth', 1.5);
                hold on;
                plot(obj.lastsole0p{3}, obj.lastsole0p{2}.*r.scalefactor, '-', ...
                    'LineWidth', 1.5);
                grid on;
                grid minor;
                xlabel('Curvatura \phi_x (1/mm])');
                ylabel('Momento M (tonf-m)');
                title('Momento curvatura M/\phi_x');
                legend({'M_x', 'M_y'}, 'location', 'best');
            end
            
            if strcmp(r.plot, 'all') || strcmp(r.plot, 'pphix')
                plt = figure();
                movegui(plt, 'center');
                set(gcf, 'name', 'P vs \phi_x');

                plot(obj.lastsole0p{3}, obj.lastsole0p{5}, '-', ...
                    'LineWidth', 1.5);
                grid on;
                grid minor;
                xlabel('Curvatura \phi_x (1/mm])');
                ylabel('Carga axial P');
                title('Carga axial vs curvatura');
            end
            
        end % plote0M
        
        function disp(obj)
            % disp: Imprime la informacion del objeto en consola
            
            fprintf('Analisis de seccion:\n');
            disp@BaseModel(obj);
            
        end % disp function
        
    end % public methods
    
end % SectionAnalysis class