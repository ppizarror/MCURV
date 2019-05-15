% Testea material aceros

% Acero A36 Chileno (Salas 2016)
% http://repositorio.uchile.cl/handle/2250/142560
elastoplastic = ElastoplasticSteel('A36', 294.31, 200894, 1120.5, 0.246);
elastoplastic.disp();
elastoplastic.plot('emin', -0.3, 'emax', 0.3, 'plotType', 'elastic');
t = elastoplastic.getTensionDeformation();

% Acero 