# Laboratorio: Keyloggers en Windows — Funcionamiento interno y defensa

Material para la clase de laboratorio de hacking ético del curso. Todo el trabajo se
realiza exclusivamente dentro de la VM de Windows 11 aislada (VirtualBox), en un entorno
de laboratorio controlado, con fines educativos y de concientización.

## Objetivos de aprendizaje

Al finalizar el módulo, el/la estudiante podrá:

1. Explicar qué es un keylogger, qué tipos existen y dónde actúan en el sistema.
2. Describir el flujo interno típico (captura → buffer → almacenamiento → exfiltración)
   sin necesidad de ejecutar ningún artefacto ofensivo.
3. Relacionar cada etapa del ataque con técnicas del framework **MITRE ATT&CK**.
4. Detectar indicadores de compromiso (IoCs) en Windows con Sysmon, Visor de eventos,
   Process Explorer/Procmon y un EDR.
5. Aplicar medidas preventivas: hardening, MFA, control de aplicaciones y políticas USB.

## Contenido del módulo

| # | Archivo | Descripción |
|---|---------|-------------|
| 1 | [01-teoria.md](01-teoria.md) | Qué es un keylogger, taxonomía (software/hardware/firmware), casos de uso legítimos e ilegítimos, marco legal y ético. |
| 2 | [02-funcionamiento-interno.md](02-funcionamiento-interno.md) | Mecánica interna en Windows a nivel conceptual: APIs implicadas, flujo de datos, persistencia y exfiltración. Mapeo a MITRE ATT&CK. |
| 3a | [03-demo-visualizador-windows.ps1](03-demo-visualizador-windows.ps1) | **Demo nativo de Windows** (PowerShell + WinForms): visualiza KeyCode/VK, modificadores y auto-repeat **solo dentro de su ventana**. Sin hooks, sin persistencia, sin red. Recomendado para el lab (VM ya es Windows 11). |
| 3b | [03-demo-visualizador.py](03-demo-visualizador.py) | Alternativa multiplataforma (Python + Tkinter), mismos límites y propósito. |
| 4 | [04-deteccion-y-prevencion.md](04-deteccion-y-prevencion.md) | Guía defensiva: Sysmon, reglas de detección conceptuales, IoCs, hardening de Windows, MFA, control de apps y USB. |
| 5 | [05-practica-laboratorio.md](05-practica-laboratorio.md) | Guía para la clase: preparación de la VM, ejercicios paso a paso, preguntas de discusión y rúbrica de evaluación. |
| 6 | [06-chequeo-etico-legal.md](06-chequeo-etico-legal.md) | Reglas de engagement, consideraciones legales (Argentina y general) y consentimiento. **Lectura obligatoria antes de la práctica.** |

## Alcance y límites del módulo

- ✅ Teoría, diagramas de arquitectura, análisis de comportamiento, detección y prevención.
- ✅ Un visualizador de eventos de teclado acotado a su propia ventana (inofensivo).
- ✅ Demos de defensa: cómo ver en vivo con Sysmon/EDR qué "se ve" cuando algo intercepta teclado.
- ✅ Validación de detecciones con frameworks legítimos de simulación de adversario
  (p. ej. **MITRE Caldera** o **Atomic Red Team**) en la VM aislada: ejercitan TTPs
  conocidas para que el EDR/SIEM las detecte, sin construir armas nuevas.
- ❌ Este módulo **no** incluye un keylogger operativo y listo para desplegar (captura
  encubierta global, persistencia, anti-análisis ni exfiltración). Entregar ese artefacto
  no es necesario para enseñar defensiva y sí sería directamente utilizable para espiar.

## Requisitos del entorno

- VM Windows 11 (la ISO ya está en la carpeta `PRUEBAS`, ver `02.jpg`).
- Red configurada como **Solo-Anfitrión (Host-Only)** o **Interna** — sin salida a Internet.
- Snapshot limpio tomado antes de cada práctica (`Máquina → Tomar snapshot`).
- Herramientas dentro de la VM: Sysmon, Process Explorer, Process Monitor, Autoruns,
  Wireshark, y opcionalmente un EDR de prueba (p. ej. el agente gratuito de un proveedor
  con licencia de evaluación, o Microsoft Defender for Endpoint trial).

> ⚠️ **Regla de oro del lab:** ningún artefacto de estas prácticas sale de la VM.
> Nada de esto se ejecuta en equipos personales, ajenos ni de producción.
