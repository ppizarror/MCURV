% ______________________________________________________________________
%|                                                                      |
%|                iniciar_MCURV - Inicia la libreria MCURV              |
%|                                                                      |
%|                   Area  de Estructuras y Geotecnia                   |
%|                   Departamento de Ingenieria Civil                   |
%|              Facultad de Ciencias Fisicas y Matematicas              |
%|                         Universidad de Chile                         |
%|______________________________________________________________________|

MCURV_ver = 'v0.10';

% Agrega las carpetas de la plataforma MCURV al PATH
addpath('mcurv');
addpath('mcurv/analysis');
addpath('mcurv/material');
addpath('mcurv/section');

% Agrega los test al path
addpath('test');