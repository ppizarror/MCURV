% Muro T
% Tarea 3 - Curso CI5221-1 Hormigon Estructural II
% Departamento de Ingenieria Civil, Universidad de Chile

wallt = SectionDesigner(); %#ok<*UNRCH>

% Genera los materiales
concreteA = HognestadModifiedConcrete('Hognestad-A', 30, 0.002, 0.004);
concreteB = HognestadModifiedConcrete('Hognestad-B', 40, 0.007, 0.02);
steel = ManderSteel('Acero', 420, 200000, 600, 200000/20, 0.01, 0.1, 0.3);
steel.setColor([1, 0, 0]);

concreteA.disp();
concreteA.getStressDeformation('emin', -1e-3, 'emax', 5e-3, ...
    'file', 'test/section/mat/concreteA.txt');
% concreteA.plot('emin', -1e-3, 'emax', 5e-3);

concreteB.disp();
concreteB.getStressDeformation('emin', -5e-4, 'emax', 2.1e-2, ...
    'file', 'test/section/mat/concreteB.txt');
% concreteB.plot('emin', -5e-4, 'emax', 2.1e-2);

steel.disp();
steel.getStressDeformation('emin', -2.5e-1, 'emax', 3.1e-1, ...
    'file', 'test/section/mat/steel.txt');
% steel.plot('emin', -2.5e-1, 'emax', 3.1e-1);

% Agrega los elementos
caseNum = '1';
h = 5000;
b = 4000;
bw = 300;
d = 125;
bw2 = 500;
increments = 100;
showSap = false; % En sap P=0
showST = false; % Muestra esfuerzo deformacion

% Genera la seccion
if strcmp(caseNum, '1')
    As = 4000;
    Asp = 4000;
    wallt.addDiscreteRect((-h + bw)/2, 0, bw, b, 10, 1, concreteA);
    wallt.addDiscreteRect(bw/2, 0, h-bw, bw, 90, 1, concreteA);
    wallt.addFiniteArea(-h/2+d, -b/2+d, As/2, steel);
    wallt.addFiniteArea(-h/2+d, b/2-d, As/2, steel);
    wallt.addFiniteArea(h/2-d, 0, Asp, steel);
    p = linspace(0, 0, increments)';
    curv = 3.2e-5;
    curvang = -90;
    iDef3 = 46; % Posicion deformacion a 0.003
    phiDef3 = -1.454545e-05;
    iDef8 = 0; % Posicion deformacion a 0.008
    phiDef8 = Inf;
elseif strcmp(caseNum, '2')
    As = 8000;
    Asp = 8000;
    wallt.addDiscreteRect((-h + bw)/2, 0, bw, b, 10, 1, concreteA);
    wallt.addDiscreteRect(bw/2, 0, h-bw, bw, 90, 1, concreteA);
    wallt.addFiniteArea(-h/2+d, -b/2+d, As/2, steel);
    wallt.addFiniteArea(-h/2+d, b/2-d, As/2, steel);
    wallt.addFiniteArea(h/2-d, 0, Asp, steel);
    p = ones(increments, 1) .* 9000 * 1000 * ~showSap; % N
    if showSap % P=0
        curv = 3.7e-5;
    else
        curv = 5e-6;
    end
    curvang = -90;
    iDef3 = 47; % Posicion deformacion a 0.003
    phiDef3 = -2.323232e-06;
    iDef8 = 66; % Posicion deformacion a 0.008
    phiDef8 = -3.282828e-06;
elseif strcmp(caseNum, '3')
    As = 8000;
    Asp = 8000;
    wallt.addDiscreteRect((-h + bw)/2, 0, bw, b, 10, 1, concreteB);
    wallt.addDiscreteRect(bw/2, 0, h-bw, bw, 90, 1, concreteB);
    wallt.addFiniteArea(-h/2+d, -b/2+d, As/2, steel);
    wallt.addFiniteArea(-h/2+d, b/2-d, As/2, steel);
    wallt.addFiniteArea(h/2-d, 0, Asp, steel);
    p = ones(increments, 1) .* 9000 * 1000 * ~showSap; % N
    if showSap % P=0
        curv = 3.2e-5;
    else
        curv = 3.2e-5;
    end
    curvang = -90;
    iDef3 = 6; % Posicion deformacion a 0.003
    phiDef3 = -1.616162e-06;
    iDef8 = 22; % Posicion deformacion a 0.008
    phiDef8 = -6.787879e-06;
elseif strcmp(caseNum, '4.1')
    As = 8000;
    Asp = 8000;
    wallt.addDiscreteRect((-h + bw)/2, 0, bw, b, 10, 1, concreteB);
    wallt.addDiscreteRect((bw - bw2)/2, 0, h-bw-bw2, bw, 80, 1, concreteB);
    wallt.addDiscreteRect((h - bw2)/2, 0, bw2, bw2, 10, 1, concreteB);
    wallt.addFiniteArea(-h/2+d, -b/2+d, As/2, steel);
    wallt.addFiniteArea(-h/2+d, b/2-d, As/2, steel);
    wallt.addFiniteArea(h/2-d, 0, Asp, steel);
    p = ones(increments, 1) .* 9000 * 1000 * ~showSap; % N
    if showSap % P=0
        curv = 3.5e-5;
    else
        curv = 3.2e-5;
    end
    curvang = -90;
    iDef3 = 7; % Posicion deformacion a 0.003
    phiDef3 = -1.939394e-06;
    iDef8 = 33; % Posicion deformacion a 0.008
    phiDef8 = -1.034343e-05;
elseif strcmp(caseNum, '4.2')
    As = 8000;
    Asp = 8000;
    wallt.addDiscreteRect((-h + bw)/2, 0, bw, b, 10, 1, concreteB);
    wallt.addDiscreteRect((bw - bw2)/2, 0, h-bw-bw2, bw, 80, 1, concreteB);
    wallt.addDiscreteRect((h - bw2)/2, 0, bw2, bw2, 10, 1, concreteB);
    wallt.addFiniteArea(-h/2+d, -b/2+d, As/2, steel);
    wallt.addFiniteArea(-h/2+d, b/2-d, As/2, steel);
    wallt.addFiniteArea(h/2-d, 0, Asp, steel);
    p = ones(increments, 1) .* 9000 * 1000 * ~showSap; % N
    if showSap % P=0
        curv = 3.5e-5;
    else
        curv = 4e-5;
    end
    curvang = 90;
    iDef3 = 38; % Posicion deformacion a 0.003
    phiDef3 = 1.494949e-05;
    iDef8 = 0; % Posicion deformacion a 0.008
    phiDef8 = Inf;
else
    error('Caso invalido');
end
phi = linspace(0, curv, increments);

wallt.setName(sprintf('Muro T - Caso %s', caseNum));
wallt.disp();
wallt.plot('showdisc', true, 'legend', true);

% Ejecuta el analisis
analysis = SectionAnalysis('Analisis', 1000, 0.01, 'showprogress', true);
analysis.calc_e0M_angle(wallt, p, phi, curvang, 'ppos', [0, 0]);

% Grafica, N*mm -> kN*m
if showSap
    analysis.plot_e0M('plot', 'mphi', 'factorM', 1e-6, 'm', 'T', ...
        'sapfile', sprintf('test/section/mcurv-sap2000/wallT%s_%d.txt', caseNum, curvang), ...
        'sapcolumnPhi', 10, 'sapcolumnM', 11, 'sapfactorM', 1e-6, ...
        'sapdiff', true, 'vecphi', [phiDef3, phiDef8], 'vecphiColor', {'r', 'k'});
else
    analysis.plot_e0M('plot', 'mphi', 'factorM', 1e-6, 'm', 'T', ...
        'vecphi', [phiDef3, phiDef8], 'vecphiColor', {'r', 'k'});
end

% Grafica tension y deformacion para deformacion de 0.003 y 0.008 si es que
% aplica
if showST
    analysis.plotStrain(iDef3);
    analysis.plotStress(iDef3);
    if iDef8 ~= 0
        analysis.plotStrain(iDef8);
        analysis.plotStress(iDef8);
    end
end

% analysis.plot_lastIter();