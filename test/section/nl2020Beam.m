% Modela las vigas curso CI7211-1 Introducción al Análisis no Lineal de Estructuras
% Año 2020

% Viga simple
simplebeam = SectionDesigner('Viga Simple');

% Genera los materiales
steel = ElastoplasticSteel('Acero', 420, 200000, 2000, 0.2);
steel.setColor([0, 0, 0.5]);
concrete = HognestadConcrete('Hormigon', 25, 0.0025);

% Crea la viga (dependiendo del grupo)
typeBeam = 1;

if typeBeam == 1
    simplebeam.addDiscreteEllipseRect(0, 0, 350, 700, 1, 100, concrete);
    simplebeam.addFiniteArea(350/4-55, -350+55, 1050, steel);
    simplebeam.addFiniteArea(-350/4+55, -350+55, 1050, steel);
    simplebeam.addFiniteArea(350/4-55, 350-55, 1050, steel);
    simplebeam.addFiniteArea(-350/4+55, 350-55, 1050, steel);
elseif typeBeam == 2
    simplebeam.addDiscreteRect(0, 0, 350, 700, 1, 100, concrete);
    simplebeam.addFiniteArea(350/2-55, -350+55, 1050, steel);
    simplebeam.addFiniteArea(-350/2+55, -350+55, 1050, steel);
elseif typeBeam == 3
    simplebeam.addDiscreteRect(0, 55, 350, 590, 1, 84, concrete);
    simplebeam.addDiscreteRect(0, -350+55, 700, 110, 1, 16, concrete);
    simplebeam.addFiniteArea(350/2-55, -350+55, 1050, steel);
    simplebeam.addFiniteArea(-350/2+55, -350+55, 1050, steel);
    simplebeam.addFiniteArea(350/2-55, 350-55, 1050, steel);
    simplebeam.addFiniteArea(-350/2+55, 350-55, 1050, steel);
elseif typeBeam == 4
    simplebeam.addDiscreteRect(0, -55, 350, 590, 1, 84, concrete);
    simplebeam.addDiscreteRect(0, 350-55, 700, 110, 1, 16, concrete);
    simplebeam.addFiniteArea(350/2-55, -350+55, 1050, steel);
    simplebeam.addFiniteArea(-350/2+55, -350+55, 1050, steel);
    simplebeam.addFiniteArea(350/2-55, 350-55, 1050, steel);
    simplebeam.addFiniteArea(-350/2+55, 350-55, 1050, steel);
elseif typeBeam == 5
    simplebeam.addDiscreteRect(0, 0, 350, 700, 1, 100, concrete);
    simplebeam.addFiniteArea(350/2-55, -350+55, 1050, steel);
    simplebeam.addFiniteArea(-350/2+55, -350+55, 1050, steel);
    simplebeam.addFiniteArea(350/2-55, 350-55, 1050, steel);
    simplebeam.addFiniteArea(-350/2+55, 350-55, 1050, steel);
else
    error('Tipo incorrecto de viga, elegir entre 1 y 5');
end

simplebeam.setName(sprintf('Viga grupo N°%d', typeBeam));
simplebeam.disp();

% Grafica la seccion
simplebeam.plot('showdisc', true, 'legend', true);

% Ejecuta un analisis
analysis = SectionAnalysis('Analisis', 100, 0.0001);
p = linspace(10, 10, 500)';
phix = linspace(0, 1.2e-4, 500)';
phiy = linspace(0, 0, 500)';
analysis.calc_e0M(simplebeam, p, phix, phiy, 'ppos', [0, 0]); % Aplicado en y=h/2 (o el 0,0)

% Grafica resultados
analysis.plot_e0M('plot', 'mphix', 'factorM', 1e-6, 'm', 'x', ...
    'unitloadM', 'kN*m');