# ADR-02 — Reglas de Dependencia y Límites de Módulo
## Patitas Urbanas · Módulo 4

---

## Estado

**Propuesta** — pendiente de veredicto del mini-comité (Semana 8).

Veredicto del comité: _pendiente_ (confirmada / ajustada /
reconsiderada)

---

## Contexto

La adopción del monolito modular (ADR-01) establece que el sistema
se organiza en módulos de negocio con fronteras explícitas. Sin
embargo, declarar los módulos no es suficiente: sin reglas claras
de qué puede depender de qué, las fronteras se rompen por descuido
y el beneficio del estilo se pierde.

Este ADR decide cómo se controlan las dependencias entre módulos
dentro del monolito modular de Patitas Urbanas.

**Problema observado en el estado actual:**
El paquete plano `com.patitasurbanas.api` no impide que cualquier
clase acceda directamente a repositorios o modelos de otro dominio.
No existe ningún mecanismo, ni estructural ni por convención
documentada, que prevenga ese acoplamiento.

---

## Problema

> ¿Cómo se controlan las dependencias entre módulos para que las
> fronteras declaradas en ADR-01 no se rompan a medida que el
> sistema crece?

---

## Alternativas consideradas

### Alternativa A — Convención documentada + revisión de PR

Las reglas de dependencia se declaran en documentación
(`dossier/15-diseno-modular-s7.md` y este ADR) y se verifican
manualmente durante la revisión de cada PR.

| Criterio | Evaluación |
|---|---|
| Costo de implementación | Ninguno — no requiere nuevas dependencias |
| Efectividad | Depende de la disciplina del equipo y la calidad de la revisión |
| Detección de violaciones | Manual — solo se detecta si el revisor lo nota |
| Costo operativo | Mínimo |
| Adecuación al equipo (2p) | Alta — no agrega fricción al flujo de trabajo |

### Alternativa B — ArchUnit para refuerzo estructural automático

Agregar la dependencia `archunit` al `pom.xml` y escribir tests
que verifiquen automáticamente que ningún módulo importa clases
internas de otro.

```xml
<dependency>
    <groupId>com.tngtech.archunit</groupId>
    <artifactId>archunit-junit5</artifactId>
    <version>1.3.0</version>
    <scope>test</scope>
</dependency>
```

| Criterio | Evaluación |
|---|---|
| Costo de implementación | Bajo-medio — agregar dependencia y escribir tests de arquitectura |
| Efectividad | Alta — las violaciones se detectan automáticamente en cada build |
| Detección de violaciones | Automática — falla el build si se rompe una regla |
| Costo operativo | Mínimo — se ejecuta junto con los tests existentes |
| Adecuación al equipo (2p) | Media — requiere aprender la API de ArchUnit |

### Alternativa C — Módulos de Java (JPMS)

Usar el sistema de módulos de Java 9+ para declarar
dependencias entre módulos a nivel de la JVM.

| Criterio | Evaluación |
|---|---|
| Costo de implementación | Alto — requiere reestructurar el proyecto completo con `module-info.java` |
| Efectividad | Muy alta — el compilador impide violaciones |
| Detección de violaciones | En tiempo de compilación |
| Costo operativo | Medio — Spring Boot tiene restricciones conocidas con JPMS |
| Adecuación al equipo (2p) | Baja — curva de aprendizaje alta, compatibilidad con Spring Boot no trivial |

---

## Costo de cada alternativa

| Alternativa | Costo de implementación | Automatización | Riesgo |
|---|---|---|---|
| A — Convención + PR | Ninguno | Manual | Fronteras se rompen sin que el build falle |
| B — ArchUnit | Bajo — 1 dependencia + tests | Automática en build | Curva de aprendizaje de ArchUnit |
| C — JPMS | Alto — reestructuración completa | En compilación | Incompatibilidades con Spring Boot |

---

## Razones para descartar alternativas

**C — JPMS:** el costo de reestructuración y las incompatibilidades
conocidas de Spring Boot con JPMS hacen que esta alternativa sea
desproporcionada para el contexto actual. No se evalúa en detalle.

---

## Decisión

Se adopta provisionalmente la **Alternativa A — Convención
documentada + revisión de PR**, con la condición de que si el
mini-comité de Semana 8 determina que es insuficiente, se incorpora
ArchUnit (Alternativa B) como refuerzo.

**Razón:** para un equipo de 2 personas con plazo fijo, la Alternativa
A es proporcional al contexto. El equipo ya practica revisión de PR
con criterio (evidencia: PRs #16, #17, #18, #22, #26, #27, #41).
Agregar ArchUnit en esta fase agrega fricción de aprendizaje sin que
exista evidencia de que las fronteras ya se estén rompiendo.

---

## Reglas de dependencia declaradas

Las siguientes reglas son de cumplimiento obligatorio a partir de
esta decisión:

### Permitidas

adopciones/ ──→ shared/
adopciones/ ──→ config/
mascotas/ ──→ shared/
mascotas/ ──→ config/
veterinarias/──→ shared/
veterinarias/──→ config/
adopciones/ ──→ mascotas/ (solo MascotaService, si aplica)


### Prohibidas

adopciones/ ✗──→ MascotaRepository
adopciones/ ✗──→ model/ de mascotas directamente
mascotas/ ✗──→ SolicitudAdopcionRepository
mascotas/ ✗──→ model/ de adopciones directamente
shared/ ✗──→ adopciones/
shared/ ✗──→ mascotas/
shared/ ✗──→ veterinarias/
config/ ✗──→ lógica de negocio de ningún módulo


### Regla general

> Ningún módulo puede importar clases internas (repositorios,
> modelos) de otro módulo. La comunicación entre módulos se hace
> exclusivamente a través de las interfaces de servicio públicas.

---

## Criterio de admisión para `shared/`

Para evitar que `shared/` se convierta en un repositorio de clases
sin cohesión, solo puede contener:

1. **Excepciones base** del sistema (ej. `RecursoNoEncontradoException`).
2. **DTOs de respuesta** que son usados por más de un módulo.
3. **Utilidades transversales** sin lógica de negocio (ej. formateadores
   de fecha, validadores genéricos).

No puede contener: entidades JPA, repositorios, servicios de negocio
ni lógica específica de un dominio.

---

## Consecuencias

### Positivas

- Las reglas de dependencia están documentadas y son auditables
  en cada PR.
- Cualquier integrante del equipo puede verificar si un import
  viola las reglas durante la revisión.
- La ruta de evolución hacia ArchUnit está definida si se necesita
  en el futuro.

### Negativas

- Las violaciones no se detectan automáticamente en el build.
  Dependen de la disciplina del revisor.
- Si el equipo crece o la frecuencia de PRs aumenta, la revisión
  manual puede volverse insuficiente.

---

## Reversibilidad

Alta. Esta decisión es documentación y convención. Revertirla
implica actualizar este ADR y el documento de diseño modular.
No hay código que deshacer.

Si se adopta ArchUnit en Semana 8, la reversibilidad sigue siendo
alta: eliminar la dependencia del `pom.xml` y borrar los tests
de arquitectura.

---

## Supuestos y condición de revisión

| Supuesto | Cómo se verifica |
|---|---|
| El equipo puede mantener las fronteras por convención sin automatización | Verificar en la primera iteración de reorganización si hay violaciones no detectadas |
| `shared/` puede mantenerse pequeño con el criterio de admisión declarado | Revisar el tamaño de `shared/` tras cada PR que agregue clases |

**Condición de revisión:** si en el mini-comité de Semana 8 se
determina que la convención es insuficiente, se incorpora ArchUnit
con los siguientes tests mínimos:

```java
@AnalyzeClasses(packages = "com.patitasurbanas.api")
public class ReglasModularesTest {

    @ArchTest
    static final ArchRule adopciones_no_accede_repositorios_mascotas =
        noClasses().that().resideInAPackage("..adopciones..")
            .should().accessClassesThat()
            .resideInAPackage("..mascotas..")
            .andShould().haveSimpleNameEndingWith("Repository");

    @ArchTest
    static final ArchRule shared_no_depende_de_modulos =
        noClasses().that().resideInAPackage("..shared..")
            .should().accessClassesThat()
            .resideInAnyPackage("..adopciones..", "..mascotas..",
                "..veterinarias..");
}
```

---

## Referencias

- `adr/adr-01-decision-estilo.md`
- `dossier/14-comparacion-estilos-s7.md`
- `dossier/15-diseno-modular-s7.md`

---

*Autores: Kevin Steven Torres Caro · Charry Ríos Daniel Estiven*
*Fecha: 2026-09-13*
*Semana 7 · Módulo 4 · Arquitectura de Software*
