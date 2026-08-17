# Gitflow para GitCaraxes

## Ramas principales

- `master`: rama estable y de producción
- `develop`: rama de integración para desarrollo activo
- `feature/*`: nuevas funcionalidades
- `release/*`: preparación de versiones
- `hotfix/*`: correcciones urgentes
- `chore/*`: tareas de mantenimiento, configuración y tooling

## Flujo recomendado

1. Crear rama desde `develop` para cada tarea:
   - `git checkout develop`
   - `git pull --ff-only origin develop`
   - `git checkout -b feature/nombre-tarea`

2. Hacer commits con Gitmoji:
   - `:sparkles:` para nuevas funcionalidades
   - `:bug:` para correcciones
   - `:wrench:` para configuración
   - `:books:` para localización o documentación
   - `:rocket:` para despliegues o release

3. Integrar en `develop`:
   - `git checkout develop`
   - `git merge --no-ff feature/nombre-tarea`
   - `git push origin develop`

4. Para una versión estable:
   - `git checkout develop`
   - `git checkout -b release/x.y.z`
   - preparar ajustes finales y tags
   - `git checkout master`
   - `git merge --no-ff release/x.y.z`
   - `git tag vX.Y.Z`
   - `git push origin master --tags`

5. Para hotfix:
   - `git checkout master`
   - `git checkout -b hotfix/correcion-urgente`
   - corregir y confirmar
   - mezclar en `master` y `develop`

## Reglas de estilo

- Usar LF para todos los archivos de texto.
- No mezclar CRLF en archivos que se editan.
- Mantener mensajes de commit claros y breves.
- Ejecutar `git add --renormalize .` cuando se quiera normalizar salto de línea tras cambios grandes.

## Ejemplos de commits con Gitmoji

```bash
git commit -m ":sparkles: add new country focus tree"
git commit -m ":bug: fix AI strategy crash"
git commit -m ":wrench: enforce LF line endings"
git commit -m ":books: update localization strings"
```
