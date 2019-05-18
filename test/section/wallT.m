% Muro T
% Tarea 3 - Curso CI5221-1 Hormigón Estructural II
% Departamento de Ingenieria Civil, Universidad de Chile

wallt = SectionDesigner();

% Genera los materiales
hormigonA = HognestadModifiedConcrete('Hognestad-A', 30, 0.002, 0.004);
hormigonB = HognestadModifiedConcrete('Hognestad-B', 40, 0.007, 0.02);
acero = ManderSteel('Acero', 420, 200000, 600, 200000/20, 0.01, 0.1, 0.3);
acero.setColor([0.8, 0, 0]);

% Agrega los elementos
caso = '3';
h = 5000;
b = 4000;
bw = 300;
d = 125;
bw2 = 500;
incrementos = 500;

% Genera la seccion
if strcmp(caso, '1')
    As = 4000;
    Asp = 4000;
    wallt.addDiscreteRect((-h + bw)/2, 0, bw, b, 10, 1, hormigonA);
    wallt.addDiscreteRect(bw/2, 0, h-bw, bw, 90, 1, hormigonA);
    wallt.addFiniteArea(-h/2+d, -b/2+d, As/2, acero);
    wallt.addFiniteArea(-h/2+d, b/2-d, As/2, acero);
    wallt.addFiniteArea(h/2-d, 0, Asp, acero);
    p = linspace(0, 0, incrementos)';
    phix = linspace(0, 0, incrementos)';
    phiy = linspace(0, 4e-5, incrementos)';
elseif strcmp(caso, '2')
    As = 8000;
    Asp = 8000;
    wallt.addDiscreteRect((-h + bw)/2, 0, bw, b, 10, 1, hormigonA);
    wallt.addDiscreteRect(bw/2, 0, h-bw, bw, 90, 1, hormigonA);
    wallt.addFiniteArea(-h/2+d, -b/2+d, As/2, acero);
    wallt.addFiniteArea(-h/2+d, b/2-d, As/2, acero);
    wallt.addFiniteArea(h/2-d, 0, Asp, acero);
    p = ones(incrementos, 1) .* 9000 * 1000; % N
    phix = linspace(0, 0, incrementos)';
    phiy = linspace(0, 4e-5, incrementos)';
elseif strcmp(caso, '3')
    As = 8000;
    Asp = 8000;
    wallt.addDiscreteRect((-h + bw)/2, 0, bw, b, 10, 1, hormigonB);
    wallt.addDiscreteRect(bw/2, 0, h-bw, bw, 90, 1, hormigonB);
    wallt.addFiniteArea(-h/2+d, -b/2+d, As/2, acero);
    wallt.addFiniteArea(-h/2+d, b/2-d, As/2, acero);
    wallt.addFiniteArea(h/2-d, 0, Asp, acero);
    p = ones(incrementos, 1) .* 9000 * 1000; % N
    phix = linspace(0, 0, incrementos)';
    phiy = linspace(0, 4e-5, incrementos)';
elseif strcmp(caso, '4.1')
    As = 8000;
    Asp = 8000;
    wallt.addDiscreteRect((-h + bw)/2, 0, bw, b, 10, 1, hormigonB);
    wallt.addDiscreteRect((bw - bw2)/2, 0, h-bw-bw2, bw, 80, 1, hormigonB);
    wallt.addDiscreteRect((h - bw2)/2, 0, bw2, bw2, 10, 1, hormigonB);
    wallt.addFiniteArea(-h/2+d, -b/2+d, As/2, acero);
    wallt.addFiniteArea(-h/2+d, b/2-d, As/2, acero);
    wallt.addFiniteArea(h/2-d, 0, Asp, acero);
    p = ones(incrementos, 1) .* 9000 * 1000; % N
    phix = linspace(0, 0, incrementos)';
    phiy = linspace(0, 4e-5, incrementos)';
elseif strcmp(caso, '4.2')
    As = 8000;
    Asp = 8000;
    wallt.addDiscreteRect((-h + bw)/2, 0, bw, b, 1, 80, hormigonB);
    wallt.addDiscreteRect((bw - bw2)/2, 0, h-bw-bw2, bw, 1, 10, hormigonB);
    wallt.addDiscreteRect((h - bw2)/2, 0, bw2, bw2, 1, 10, hormigonB);
    wallt.addFiniteArea(-h/2+d, -b/2+d, As/2, acero);
    wallt.addFiniteArea(-h/2+d, b/2-d, As/2, acero);
    wallt.addFiniteArea(h/2-d, 0, Asp, acero);
    p = ones(incrementos, 1) .* 9000 * 1000; % N
    phix = linspace(0, 4.5e-5, incrementos)';
    phiy = linspace(0, 0, incrementos)';
else
    error('Caso invalido');
end
ppos = [0, 0]; % Ubicado en h/2, o sea, al centro geometrico del muro

wallt.setName(sprintf('Muro T - Caso %s', caso));
wallt.disp();
wallt.plot('showdisc', true);

% Ejecuta el analisis
analysis = SectionAnalysis('Analisis', 500, 0.01, 'showprogress', true);
e0 = analysis.calc_e0M(wallt, p, phix, phiy, ppos);

% Grafica
if ~strcmp(caso, '4.2')
    analysis.plot_e0M('plot', 'mphiy', 'factor', 1e-6); % N*mm -> kN*m
else
    analysis.plot_e0M('plot', 'mphix', 'factor', 1e-6); % N*mm -> kN*m
end
wallt.plotStress(e0, phix, phiy, 'i', 1, 'mfactor', 1e-6, 'pfactor', 1e-3);