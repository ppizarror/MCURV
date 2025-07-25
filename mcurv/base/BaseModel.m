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
%| BaseModel                                                            |
%|                                                                      |
%| Definicion de un modelo u elemento basico de la plataforma, posee    |
%| funciones generales para definir objetos con nombres e identificado- |
%| res.                                                                 |
%|                                                                      |
%| Autor: Pablo Pizarro R. @ppizarror.com                               |
%| Licencia: MIT                                                        |
%| Codigo fuente: https://github.com/ppizarror/MCURV                    |
%|______________________________________________________________________|

classdef BaseModel < handle

    properties (Access = private)
        objName % Nombre del objeto
        objID % Identificador del objeto
    end % private properties

    methods (Access = public)

        function obj = BaseModel(name)
            % BaseModel: Crea un modelo basico, requiere el nombre del
            % objeto

            if ~exist('name', 'var') || strcmp(name, '')
                name = 'Undefined';
            end
            obj.objName = name;
            obj.objID = char(java.util.UUID.randomUUID);

        end % BaseModel constructor

        function name = getName(obj)
            % getName: Retorna el nombre del objeto

            name = obj.objName;

        end % getName function

        function setName(obj, name)
            % setName: Estabelce el nombre del objeto

            obj.objName = name;

        end % setName function

        function id = getID(obj)
            % getName: Retorna el identificador del objeto

            id = obj.objID;

        end % getID function

        function e = equals(obj, b)
            % equals: Verifica que el objeto sea identico a otro

            e = strcmp(obj.objID, b.objID);

        end % equals function

        function disp(obj)
            % disp: Imprime la informacion del objeto en la consola

            fprintf('\tEtiqueta: %s\n', obj.objName);

        end % disp function

    end % public methods

end % BaseModel class