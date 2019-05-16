% Viga simple
simplebeam = SectionDesigner('Viga plana');

% Genera los materiales
steel = ElastoplasticSteel('Acero', 420, 200000, 2000, 0.2);
steel.setColor([0, 0, 0.5]);
concrete = HognestadConcrete('Hormigon', 25, 0.0025);

% Agrega los elementos a la seccion
simplebeam.addDiscreteRect(0, 0, 350, 700, 10, 10, concrete);
simplebeam.addFiniteArea(-130, -350+55, 1100, steel);
simplebeam.addFiniteArea(-130, 350-55, 1100, steel);
simplebeam.addFiniteArea(130, -350+55, 1100, steel);
simplebeam.addFiniteArea(130, 350-55, 1100, steel);

simplebeam.disp();

% Grafica la seccion
% simplebeam.plot('showdisc', false);

% Ejecuta un analisis
analysis = SectionAnalysis('Analisis', 100);
p = linspace(0, 0, 500)';
phix = linspace(0, 1.2e-4, 500)';
phiy = linspace(0, 0, 500)';
[pf, mxf, myf, delta_e0_iter, delta_phix_iter, delta_phiy_iter, err_p, err_mx, err_my, ...
    tol_itr, p_iter, mx_iter, my_iter, e0_total, phix_total, phiy_total, ...
    j_itr] = analysis.mcurv(simplebeam, p, phix, phiy);