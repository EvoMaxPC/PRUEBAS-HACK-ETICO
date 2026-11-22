# 05 — Práctica de laboratorio (guía de clase, 90–120 min)

## Preparación (antes de la clase, por el docente)

1. VM Windows 11 importada en VirtualBox (ya descargada según `02.jpg`), red **Solo-Anfitrión** o **Interna**, sin Internet.
2. Snapshot `lab-limpio` tomado tras instalar Sysmon + herramientas (Autoruns, procmon, Process Explorer, Wireshark).
3. Verificar que el visualizador corre en la VM (nativo Windows, recomendado):
   `powershell -ExecutionPolicy Bypass -File .\03-demo-visualizador-windows.ps1`
   (alternativa Python: `python 03-demo-visualizador.py`).
4. Proyector/pantalla para mostrar el visualizador y las consolas.

## Bloque A — Teoría relámpago (10 min)

- Dibujar en pizarra el camino de una tecla (ver `02`, §1) y ubicar los 4 puntos donde un
  keylogger puede anclarse.
- Pregunta gancho: *“Si el antivirus no ve nada, ¿cómo nos damos cuenta?”* → respuesta guía:
  comportamiento, no firma.

## Bloque B — Demo interactivo con el visualizador (15 min)

1. Abrir `03-demo-visualizador-windows.ps1` proyectado (o la versión Python como respaldo).
2. Escribir con distintas combinaciones: `a`, `Shift+A`, `Ctrl+C`, `Alt+Tab`, `F5`,
   flechas, `teclado numérico`.
3. Cada estudiante identifica en pantalla: Virtual-Key, hex VK, modificadores y char generado.
4. **Preguntas de discusión**:
   - ¿Por qué Windows reporta `VK` y no el scan code directo a la aplicación?
   - ¿Qué diferencia hay entre que una app reciba la tecla (evento local) y que un proceso
     se entere de **todas** las teclas sin foco (hook global)?
   - ¿Por qué `Shift+A` produce `char = 'A'` pero `Ctrl+C` produce `char` vacío?
5. Exportar el CSV de la sesión y abrirlo: mostrar que es texto plano → por eso los
   keyloggers reales cifran sus logs.

## Bloque B-bis (opcional) — Validar la detección con simulación de adversario (20 min)

Con el EDR/Sysmon activo en la VM, ejecutar un procedimiento de prueba de **MITRE Caldera**
o **Atomic Red Team** mapeado a **T1056.001** y verificar que la telemetría (Event IDs 1, 3,
7, 8, 13) dispara las alertas esperadas. El foco es comprobar qué ve el defensor, no operar
ofensivamente. Anotar qué regla disparó y con qué latencia.

## Bloque C — Caza con herramientas (35 min)

Objetivo: que cada estación inspeccione la VM y produzca un mini-informe de 10 líneas.

### C.1 Autoruns (10 min)
- Abrir `Autoruns` → pestaña `Logon`, `Scheduled Tasks`, `Services`, `Drivers`.
- Ejercicio: localizar 3 entradas de Microsoft firmadas y 1 de terceros; anotar ruta y
  empresa. Discutir: *¿qué columna usarían para decidir si investigar?* (firma, ruta,
  entropía del nombre, primera vista en la red, etc.)

### C.2 Process Explorer (10 min)
- Vista de DLLs (`Ctrl+D`) sobre un proceso conocido (notepad).
- Ejercicio: ¿qué significaría encontrar una DLL **sin firma** o en `%TEMP%` en ese listado?
- Comparar con la documentación pública: un hook DLL clásico se vería exactamente ahí.

### C.3 Procmon (10 min)
- Filtros: `Process Name is <proceso>` / `Path contains %TEMP%` / `Operation is WriteFile`.
- Ejercicio: ejecutar una app inofensiva que escriba en %TEMP% y seguir el archivo
  creciendo; discutir el paralelo con el volcado de un log de teclado.

### C.4 Wireshark (5 min)
- Capturar en la interfaz de la VM mientras navega una página de prueba interna.
- Ejercicio: ¿cómo distinguirían un *beacon* (POSTs reguloso) de tráfico normal? Intervalos,
  destinos repetitivos, tamaño de payload similar.

## Bloque D — Respuesta a incidentes en mesa (15 min)

Caso impreso para cada equipo: *“Detectaron que en el equipo de recepción apareció una
tarea programada nueva apuntando a `%APPDATA%\update\svc.exe` sin firma. No hay aviso del
EDR. ¿Qué hacen en orden?”*

Rúbrica esperada:
1. Aislar (red) → 2. Preservar (no apagar, capturar evidencia) → 3. Revocar credenciales
desde otro equipo → 4. Escalar/notificación → 5. Reinstalar → 6. Post-mortem y mejoras.

## Bloque E — Cierre y rúbrica (15 min)

### Rúbrica de evaluación (100 pts)
| Criterio | Pts |
|---|---|
| Explica los 4 anclajes del camino de la tecla | 15 |
| Diferencia hook global, sondeo y driver | 15 |
| Usa Autoruns/Procmon/Process Explorer correctamente | 25 |
| Identifica al menos 5 indicadores (IoCs) concretos | 20 |
| Propone respuesta a incidentes completa y ordenada | 15 |
| Respeta el marco ético (no saca nada de la VM) | 10 |

## Preguntas de examen / debate

1. ¿Por qué MFA es el control compensatorio más importante contra keyloggers?
2. ¿Qué ventaja de detección tiene Sysmon Event ID 3 sobre el firewall local?
3. Un hardware keylogger USB: ¿qué controles del lab aplican y cuáles no? (Respuesta:
   físicos/inventario; ninguna del plano software lo ve.)
4. Diferencia entre detección por firma y por comportamiento; de un ejemplo de cada una.
5. ¿Por qué el antivirus puede "no ver nada" y aun así el equipo estar comprometido?

## Limpieza después de la práctica

- Revertir la VM al snapshot `lab-limpio`.
- Borrar archivos exportados (CSV, pcaps).
- Confirmar que nada salió de la VM (la red era solo-anfitrión/interna).
