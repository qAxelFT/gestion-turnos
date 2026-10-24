# Guía de contribución

Este documento define cómo se trabaja en el repositorio: **flujo de ramas Gitflow** (solo el flujo, sin la herramienta `git-flow`) y **Conventional Commits**.

## Ramas

| Rama | Origen | Se integra en | Propósito |
|---|---|---|---|
| `main` | — | — | Código estable y entregable. Cada merge lleva una etiqueta de versión |
| `develop` | `main` | — | Integración continua del trabajo del sprint |
| `feature/*` | `develop` | `develop` | Una historia o tarea de Jira |
| `release/*` | `develop` | `main` y `develop` | Preparar una versión (ajustes finales, versión, documentación) |
| `hotfix/*` | `main` | `main` y `develop` | Corrección urgente de algo ya publicado |

Reglas:

- Nunca se hace commit directo en `main` ni en `develop`; todo entra por pull request.
- Nombres en minúsculas y con guiones, con la clave de Jira al inicio: `feature/GT-12-reservar-slot`. Sustituye `GT` por la clave real del proyecto en Jira.
- Las ramas `feature/*` son cortas: una historia, un pull request.

### Flujo de una feature

```bash
git switch develop && git pull
git switch -c feature/GT-12-reservar-slot

# trabajar y hacer commits (ver Conventional Commits)

git push -u origin feature/GT-12-reservar-slot
# abrir pull request hacia develop; al integrarlo, usar "Create a merge commit"
git branch -d feature/GT-12-reservar-slot
```

Se usa merge commit (no squash) para conservar el historial de la feature, que es evidencia de contribución del proyecto.

### Release

Se hace una release al cierre de cada sprint con entregable:

```bash
git switch develop && git pull
git switch -c release/0.1.0
# solo ajustes finales: versión, documentación, correcciones menores
git switch main && git merge --no-ff release/0.1.0
git tag -a v0.1.0 -m "Sprint 1: BD y núcleo concurrente"
git switch develop && git merge --no-ff release/0.1.0
git push origin main develop --tags
git branch -d release/0.1.0
```

Versionado semántico: `v0.1.0` (Sprint 1), `v0.2.0` (Sprint 2) y `v1.0.0` (entrega final).

### Hotfix

```bash
git switch main && git pull
git switch -c hotfix/GT-40-deadlock-cancelar
# corregir, commit con fix:
git switch main && git merge --no-ff hotfix/GT-40-deadlock-cancelar
git tag -a v0.2.1 -m "Corrige deadlock al cancelar"
git switch develop && git merge --no-ff hotfix/GT-40-deadlock-cancelar
```

## Conventional Commits

Formato:

```
<tipo>(<alcance>): <descripción en imperativo, minúsculas, sin punto>

[cuerpo opcional: qué y por qué]

[pie opcional: Refs: GT-12]
```

**Tipos**

| Tipo | Uso |
|---|---|
| `feat` | Funcionalidad nueva |
| `fix` | Corrección de un error |
| `docs` | Solo documentación |
| `style` | Formato sin cambio de lógica |
| `refactor` | Reestructura sin cambiar comportamiento |
| `perf` | Mejora de rendimiento |
| `test` | Pruebas o probador de carga |
| `build` | Makefile, dependencias, compilación |
| `chore` | Tareas de mantenimiento |
| `revert` | Revierte un commit anterior |

**Alcances sugeridos:** `db`, `core`, `api`, `web`, `load`, `docs`, `build`.

**Ejemplos**

```
feat(core): agrega mutex por slot con orden de bloqueo fijo
fix(api): responde 409 cuando el slot ya fue reservado
test(load): agrega prueba de 50 clientes sobre el mismo slot
build: agrega objetivo make tsan con ThreadSanitizer
docs: actualiza diagrama de concurrencia

feat(db)!: cambia estado del slot a ENUM

BREAKING CHANGE: requiere volver a ejecutar make db-init.
Refs: GT-15
```

Un cambio incompatible se marca con `!` después del tipo o alcance, y con el pie `BREAKING CHANGE:`.

Buenas prácticas: un commit por cambio lógico, descripción de máximo 72 caracteres y la clave de Jira en el pie (`Refs: GT-12`) para enlazar con el tablero.

## Definition of Done

Una historia se integra a `develop` cuando:

1. Compila sin advertencias con `make`.
2. Pasa las pruebas de concurrencia y la ejecución con ThreadSanitizer (`make tsan`) sin carreras de datos.
3. Las operaciones sobre la base de datos son transaccionales e íntegras.
4. Los commits siguen Conventional Commits y el pull request enlaza la tarea de Jira.
5. Está documentada y demostrable en la Sprint Review.

Como el equipo es de una persona, la revisión del pull request es una autorrevisión con esta lista.

## Convenciones de código

- C++17, `snake_case` para funciones y variables, `PascalCase` para tipos.
- Bloqueos solo con RAII (`std::lock_guard`, `std::unique_lock`); nunca `lock()` y `unlock()` manuales.
- Todo recurso compartido se documenta con un comentario que indique qué mutex lo protege.
- Si una operación necesita varios slots, se bloquean siempre en orden ascendente de id.
- Una conexión de base de datos por hilo; nunca se comparten entre hilos.
- No se versionan binarios ni `build/`.
- Nunca se suben credenciales: van en `.env`, que está en `.gitignore`. Si una contraseña llega a un commit, se cambia de inmediato; borrar el commit no basta.
- Cada archivo fuente nuevo inicia con `// SPDX-License-Identifier: MIT`.
