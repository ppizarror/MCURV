% ______________________________________________________________________
%|                                                                      |
%|                iniciar_MCURV - Inicia la libreria MCURV              |
%|                                                                      |
%|                   Area  de Estructuras y Geotecnia                   |
%|                   Departamento de Ingenieria Civil                   |
%|              Facultad de Ciencias Fisicas y Matematicas              |
%|                         Universidad de Chile                         |
%|______________________________________________________________________|

MCURV_ver = 'v1.2';

% Agrega las carpetas de la plataforma MCURV al PATH
addpath('mcurv');
addpath('mcurv/base');
addpath('mcurv/lib');
addpath('mcurv/material');
addpath('mcurv/material/concrete');
addpath('mcurv/material/steel');
addpath('mcurv/section');
addpath('mcurv/utils');

% Agrega los test al path
addpath('test');
addpath('test/material');
addpath('test/section');