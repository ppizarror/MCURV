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
- Perfil angular (*addDiscreteLChannel*)
- Perfil cajón cuadrado (*addDiscreteSquareChannel*)
- Perfil cajón rectangular (*addDiscreteBoxChannel*)
- Perfil doble T (*addDiscreteISection*)
- Perfil H (*addDiscreteHSection*)
- Perfil T (*addDiscreteHSection.
- Rectángulo (*addDiscreteRect*)
- Sección canal (*addDiscreteChannel*)
- Sección circular (*addDiscreteCircle*)
- Sección tubular (*addDiscreteTubular*)

## Documentación

La documentación del proyecto se puede encontrar en [https://ppizarror.com/MCURV/docs/](https://ppizarror.com/MCURV/docs/)

## Ejemplos

| Modelo | Resultado |
|:---:|:---:|
| ![ADVANCED-SHAPES](https://ppizarror.com/resources/images/mcurv/advshapes-1.png)  | ![ADVANCED-SHAPES](https://ppizarror.com/resources/images/mcurv/advshapes-2.png) |
| ![SIMPLE-BEAM](https://ppizarror.com/resources/images/mcurv/simplebeam-1.png)  | ![SIMPLE-BEAM](https://ppizarror.com/resources/images/mcurv/simplebeam-2.png) |
| ![CINTAC-H](https://ppizarror.com/resources/images/mcurv/cintac-model1.png)  | ![CINTAC-H](https://ppizarror.com/resources/images/mcurv/cintac-model2.png) |
| ![BOXBEAM](https://ppizarror.com/resources/images/mcurv/boxbeam-1.png)  | ![BOXBEAM](https://ppizarror.com/resources/images/mcurv/boxbeam-2.png) |
| ![WALL-T](https://ppizarror.com/resources/images/mcurv/wallt-1.png)  | ![ADVANCED-SHAPES](https://ppizarror.com/resources/images/mcurv/wallt-2.png) |

## Autor

[Pablo Pizarro R.](https://ppizarror.com) | 2019

## Licencia

Este proyecto está licenciado bajo la licencia MIT [https://opensource.org/licenses/MIT]