% Testea material aceros

% Acero A36 Chileno (Salas 2016)
% http://repositorio.uchile.cl/handle/2250/142560
elastoplastic = ElastoplasticSteel('A36', 294.31, 200894, 1120.5, 0.246);
elastoplastic.disp();
% elastoplastic.plot('emin', -0.3, 'emax', 0.3, 'plotType', 'elastic');
% t = elastoplastic.getTensionDeformation();

% Acero Mander et al. (1984)
mandersteel = ManderSteel('Acero Mander', 420, 200000, 600, 200000/20, 0.01, 0.1, 0.3);
mandersteel.disp();
mandersteel.plot('emin', -0.3, 'emax', 0.3, 'plotType', 'tension');