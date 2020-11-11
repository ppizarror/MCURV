<h1 align="center">
  <img alt="MCURV" src="https://res.ppizarror.com/other/matlab.png" width="200px" height="200px" />
  <br /><br />
  MCURV</h1>
<p align="center">Genera el diagrama de momento curvatura para secciones prismáticas de cualquier tipo de material, sometidas a un momento y compresión axial</p>
<div align="center"><a href="https://ppizarror.com"><img alt="@ppizarror" src="https://res.ppizarror.com/badges/autor.svg" /></a>
<a href="https://opensource.org/licenses/MIT"><img alt="MIT" src="https://res.ppizarror.com/badges/licenciamit.svg" /></a>
</div><br />

Calcula diagramas de momento curvatura de secciones de cualquier geometría usando la metodología numérica Newton Rhapson. Permite el uso de materiales no lineales.

## Materiales incorporados

- Material genérico (*GenericMaterial*)
- Acero con endurecimiento bilineal (*ElastoplasticSteel*)
- Acero modelo Mander et al. (*ManderSteel*)
- Concreto, modelo Hognestad (*HognestadConcrete*)
- Concreto, modelo Hognestad modificado (*HognestadModifiedConcrete*)

## Definición geométrica

El generador de secciones (*SectionDesigner*) permite añadir los sigientes componentes:

- Área finita (*addFiniteArea*)
- Cuadrado (*addDiscreteSquare*)
- Elipse inscrita en rectángulo (*addDiscreteEllipseRect*)
- Perfil angular (*addDiscreteLChannel*)
- Perfil cajón cuadrado (*addDiscreteSquareChannel*)
- Perfil cajón rectangular (*addDiscreteBoxChannel*)
- Perfil doble T (*addDiscreteISection*)
- Perfil H (*addDiscreteHSection*)
- Perfil T (*addDiscreteHSection*)
- Rectángulo (*addDiscreteRect*)
- Sección canal (*addDiscreteChannel*)
- Sección circular (*addDiscreteCircle*)
- Sección tubular (*addDiscreteTubular*)

## Documentación

La documentación del proyecto se puede encontrar en [https://ppizarror.com/MCURV/docs/](https://ppizarror.com/MCURV/docs/)

## Ejemplos

| Modelo | Resultado |
|:---:|:---:|
| ![ADVANCED-SHAPES](https://res.ppizarror.com/images/mcurv/advshapes-1.png)  | ![ADVANCED-SHAPES](https://res.ppizarror.com/images/mcurv/advshapes-2.png) |
| ![SIMPLE-BEAM](https://res.ppizarror.com/images/mcurv/simplebeam-1.png)  | ![SIMPLE-BEAM](https://res.ppizarror.com/images/mcurv/simplebeam-2.png) |
| ![CINTAC-H](https://res.ppizarror.com/images/mcurv/cintac-model1.png)  | ![CINTAC-H](https://res.ppizarror.com/images/mcurv/cintac-model2.png) |
| ![BOXBEAM](https://res.ppizarror.com/images/mcurv/boxbeam-1.png)  | ![BOXBEAM](https://res.ppizarror.com/images/mcurv/boxbeam-2.png) |
| ![WALL-T](https://res.ppizarror.com/images/mcurv/wallt-1.png)  | ![ADVANCED-SHAPES](https://res.ppizarror.com/images/mcurv/wallt-2.png) |
| ![CIRCLE](https://res.ppizarror.com/images/mcurv/circle-1.png)  | ![CIRCLE](https://res.ppizarror.com/images/mcurv/circle-2.png) |

## Autor

[Pablo Pizarro R.](https://ppizarror.com) | 2019 - 2020

## Licencia

Este proyecto está licenciado bajo la licencia MIT [https://opensource.org/licenses/MIT]
