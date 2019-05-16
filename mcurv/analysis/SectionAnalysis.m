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
    end % protected properties
    
    methods(Access = public)
        
        function obj = SectionAnalysis(analysisName, maxiter)
            % SectionAnalysis: Constructor de la clase
            
            obj = obj@BaseModel(analysisName);
            obj.maxiter = maxiter;
            
        end % SectionAnalysis constructor
        
        function [pf, mxf, myf, delta_e0_iter, delta_phix_iter, ...
                delta_phiy_iter, err_p, err_mx, err_my, tol_itr, p_iter, mx_iter, my_iter, ...
                e0_total, phix_total, phiy_total, j_itr] = mcurv(obj, section, p, phix, phiy)
            % mcurv: Calcula el diagrama momento curvatura de una seccion
            
            % Actualiza propiedades de la seccion
            section.updateProps();
            
            if length(p) ~= length(phix) || length(p) ~= length(phiy)
                error('P y PHIX/PHIY deben tener igual dimension');
            end
            if ~isa(section, 'SectionDesigner')
                error('Objeto seccion debe ser del tipo SectionDesigner');
            end
            n_pasos = length(p);
            
            % Crea matriz de iteraciones de la deformacion total
            delta_e0_iter = zeros(n_pasos, obj.maxiter);
            delta_phix_iter = zeros(n_pasos, obj.maxiter);
            delta_phiy_iter = zeros(n_pasos, obj.maxiter);
            
            e0_total = zeros(n_pasos, 1);
            phix_total = phix;
            phiy_total = phiy;
            
            % Error de cada iteracion
            err_p = zeros(n_pasos, obj.maxiter);
            err_mx = zeros(n_pasos, obj.maxiter);
            err_my = zeros(n_pasos, obj.maxiter);
            
            % Valores de las iteraciones
            p_iter = zeros(n_pasos, obj.maxiter);
            mx_iter = zeros(n_pasos, obj.maxiter);
            my_iter = zeros(n_pasos, obj.maxiter);
            
            % Error total
            tol_itr = zeros(n_pasos, obj.maxiter);
            
            % J-iteraciones por cada i-incremento
            j_itr = zeros(n_pasos, 1);
            
            % Calcula el primer jacobiano
            jac_E = section.calcJac(e0_total(1), phix_total(1), phiy_total(1));
            
            % Finales
            pf = zeros(n_pasos, 1);
            mxf = zeros(n_pasos, 1);
            myf = zeros(n_pasos, 1);
            
            % Recorre cada incremento de carga
            reverse_porcent = '';
            tol = 1;
            for i = 1:n_pasos
                
                % Medidos c/r al eje x
                Mxi = section.calcMx(e0_total(i), phix_total(i), phiy_total(i));
                Myi = section.calcMy(e0_total(i), phix_total(i), phiy_total(i));
                Pi = section.calcP(e0_total(i), phix_total(i), phiy_total(i));
                % Calcula el primer valor de e0, phix, phiy para las iteraciones
                jac = section.calcJac(e0_total(i), phix_total(i), phiy_total(i));
                de = jac^-1 * [p(i) - Pi; Mxi; Myi]; % delta[e0, phix, phiy]
                
                % Guarda la primera deformacion
                delta_e0_iter(i, 1) = de(1);
                delta_phix_iter(i, 1) = de(2);
                delta_phiy_iter(i, 1) = de(3);
                
                % Inicia las j-iteraciones
                for j = 1:(obj.maxiter - 1)
                    
                    % Incrementa iteracion
                    j_itr(i) = j_itr(i) + 1;
                    
                    % Actualiza deformacion total
                    if i > 1
                        e0_total(i) = e0_total(i-1) + sum(delta_e0_iter(i, :));
                        phix_total(i) = phix_total(i-1) + sum(delta_phix_iter(i, :));
                        phiy_total(i) = phiy_total(i-1) + sum(delta_phiy_iter(i, :));
                    else
                        e0_total(i) = sum(delta_e0_iter(i, :));
                        phix_total(i) = sum(delta_phix_iter(i, :));
                        phiy_total(i) = sum(delta_phiy_iter(i, :));
                    end
                    
                    % Calcula la fuerzas internas por cada zapata
                    p_iter(i, j) = section.calcP(e0_total(i), phix_total(i), phiy_total(i));
                    mx_iter(i, j) = section.calcMx(e0_total(i), phix_total(i), phiy_total(i));
                    my_iter(i, j) = section.calcMy(e0_total(i), phix_total(i), phiy_total(i));
                    
                    % Calcula los errores
                    err_p(i, j) = p(i) - p_iter(i, j);
                    err_mx(i, j) = Mxi - mx_iter(i, j);
                    err_my(i, j) = Myi - my_iter(i, j);
                    Mxi = mx_iter(i, j);
                    Myi = my_iter(i, j);
                    
                    % Calcula la tolerancia
                    tol_itr(i, j) = sqrt(1/3*(err_p(i, j)^2 + err_mx(i, j)^2 + err_my(i, j)^2)); % RMS
                    if tol_itr(i, j) < tol % Termina las iteraciones
                        break;
                    end
                    
                    % Calcula el juevo jacobiano para el siguiente incremento
                    jac = section.calcJac(e0_total(i), phix_total(i), phiy_total(i));
                    
                    % Si la matriz es singular utiliza la primera
                    if det(jac) < 1e4
                        jac = jac_E;
                    end
                    
                    % Calcula el nuevo vector de deformaciones
                    de = jac^-1 * [err_p(i, j); err_mx(i, j); err_my(i, j)];
                    
                    % Guarda la primera deformacion
                    delta_e0_iter(i, j+1) = de(1);
                    delta_phix_iter(i, j+1) = de(2);
                    delta_phiy_iter(i, j+1) = de(3);
                    
                end
                
                % Actualiza deformacion total
                if i > 1
                    e0_total(i) = e0_total(i-1) + sum(delta_e0_iter(i, :));
                    phix_total(i) = phix_total(i-1) + sum(delta_phix_iter(i, :));
                    phiy_total(i) = phiy_total(i-1) + sum(delta_phiy_iter(i, :));
                else
                    e0_total(i) = sum(delta_e0_iter(i, :));
                    phix_total(i) = sum(delta_phix_iter(i, :));
                    phiy_total(i) = sum(delta_phiy_iter(i, :));
                end
                
                % Actualiza finales
                pf(i) = section.calcP(e0_total(i), phix_total(i), phiy_total(i));
                mxf(i) = section.calcMx(e0_total(i), phix_total(i), phiy_total(i));
                myf(i) = section.calcMy(e0_total(i), phix_total(i), phiy_total(i));
                
                % Imprime el estado
                msg = sprintf('\tCalculando... (%.1f/100)', i/n_pasos*100);
                fprintf([reverse_porcent, msg]);
                reverse_porcent = repmat(sprintf('\b'), 1, length(msg));
                
            end    

        end % mcurv function
        
        function disp(obj)
            % disp: Imprime la informacion del objeto en consola
            
            fprintf('Analisis de seccion:\n');
            disp@BaseModel(obj);
            
        end % disp function
        
    end % public methods
    
end % SectionAnalysis class