# 02 — Funcionamiento interno (conceptual)

> Este capítulo explica el **mecanismo**, no entrega un artefacto ofensivo. Las APIs se
> mencionan con fines de comprensión y detección. Detalle deliberado: se explica el qué y
> el porqué; no se incluye código de captura global encubierta listo para usar.

## 1. El camino de una tecla en Windows

```
[1] Tecla física
      │  scan code (hardware)
      ▼
[2] Controlador de teclado / i8042 o USB HID
      │  interrupción → driver de clase (kbdclass.sys / kbdhid.sys)
      ▼
[3] Pila de entrada del kernel (win32k.sys)
      │  traducción scan code → virtual key code (layout del teclado)
      ▼
[4] Raw Input / cola de mensajes (thread de la ventana en primer plano)
      │
      ├──► [5a] Hooks WH_KEYBOARD / WH_KEYBOARD_LL (si algún proceso los registró)
      │
      ▼
[6] Window Procedure de la ventana activa → aplicación (notepad, navegador…)
```

Un keylogger se instala en **[5a]** (hooks), en **[4]** (sondeo de estado global) o en
**[3]** (driver de kernel). Entender el punto de anclaje es clave para detectarlo:

- Hook user-mode → visible en la lista de hooks del sistema y como DLL cargada.
- Sondeo → ningún hook; delata un proceso "sano" haciendo llamadas raras en bucle.
- Driver → delata un controlador sin firma/extraño cargado en el kernel.

## 2. Mecanismos de captura en user-mode (conceptos)

### a) Hook de teclado de bajo nivel — `WH_KEYBOARD_LL`

Windows permite que un proceso registre una callback que el sistema invoca por cada
pulsación **antes** de entregarla a la ventana destino. Concepto:

1. El proceso llama a `SetWindowsHookEx(WH_KEYBOARD_LL, callback, mod, 0)`.
2. El sistema mantiene la callback en una lista. **No requiere inyectar DLL** en otros
   procesos (a diferencia de los hooks clásicos), lo que lo hace atractivo para el malware.
3. Por cada pulsación, el sistema hace un "callback" al proceso; éste puede registrar el
   Virtual-Key (p. ej. `0x41` = `A`) y el estado de modificadores (Shift/Ctrl/Alt).
4. La callback debe ser rápida: si tarda, el sistema la desengancha (`LowLevelHooksTimeout`).

**Señales defensivas:** proceso persistente de GUI con una LL hook instalada; DLL
navegadora de hooks en Process Explorer/Autoruns; entradas de registro de auto-inicio.

### b) Hook clásico con inyección — `WH_KEYBOARD`

Variante antigua: la DLL del hook se **carga dentro de cada proceso** que recibe teclas.
Produce módulos extraños visibles en todos los procesos (muy detectable hoy).

### c) Sondeo de estado — `GetAsyncKeyState`

Sin hooks: un bucle consulta el estado de las 256 virtual-keys unas decenas de veces por
segundo. Si el bit bajo indica "pulsada desde la última consulta", la registra.

**Señales defensivas:** bucle de alta frecuencia de llamadas a `user32!GetAsyncKeyState`,
consumo de CPU periódico, ausencia de hooks (lo que despista a herramientas básicas).

### d) Registro de foco / hooks de formularios

En vez de todo el teclado, observa qué ventana tiene foco (`GetForegroundWindow`) y solo
registra cuando es, por ejemplo, un navegador o un diálogo de autenticación. Minimiza el
ruido → menos sospechoso para heurísticas simples.

## 3. Persistencia (cómo sobrevive un reinicio)

Conceptos típicos (todos detectables con Autoruns):

- Clave `HKCU\...\Run` / `RunOnce` (requiere solo usuario).
- Carpetas de inicio (`shell:startup`).
- Tareas programadas (`schtasks`) con trigger de logon.
- Servicio de Windows (requiere admin).
- WMI Event Subscription (avanzado, fileless).

En el lab se revisan con **Autoruns** marcando todo lo que no sea de Microsoft/firmado.

## 4. Almacenamiento y exfiltración (conceptos)

| Fase | Qué hace típicamente | Rastro que deja |
|---|---|---|
| Buffer en memoria | Acumula teclas en un ring buffer | Poca huella en disco |
| Volcado a disco | Escribe cifrado (XOR/base64) en `%TEMP%`, `%APPDATA%` | Archivo crece linealmente; entropía alta |
| Exfiltración | HTTP(S) POST a C2, SMTP, Telegram Bot API, FTP | Beacon periódico saliente; DNS anómalo |
| Borrado | Anti-forense básico (borrar el log tras enviar) | Gaps en telemetría de disco |

En VM aislada se puede observar la telemetría de red con **Wireshark** y comprobar que
los POST salen en intervalos regulares (patrón "beaconing").

## 5. Anti-detección (por qué se esconden, conceptualmente)

- **Ofuscación/packing** del binario (UPX, crypters) → evade firmas estáticas.
- **Nombres de proceso/copia** que imitan binarios del sistema (`svchost` falso, etc.).
- **Verificación de VM/sandbox** (limitar ejecución) → la VM del lab debe ser indistinguible.
- **Ubicación en rutas de usuario** con nombres neutros.

No es necesario (ni apropiado) reproducir estas técnicas en el lab; basta con **saber que
existen** y enseñar a buscar comportamientos, no cadenas.

## 6. Mapeo MITRE ATT&CK

| Etapa | Técnica |
|---|---|
| Captura de teclado | **T1056.001 — Input Capture: Keylogging** |
| Persistencia | T1547.001 (Run keys), T1053.005 (Scheduled Task), T1543.003 (Service) |
| Descubrimiento de foco | T1010 (Application Window Discovery) |
| Recolección | T1115 (Clipboard Data), T1113 (Screen Capture) |
| Comando y control | T1071.001 (Web Protocols), T1105 (Ingress Tool Transfer) |
| Evasión | T1027 (Obfuscated Files), T1497 (Virtualization/Sandbox Evasion) |

## 7. Por qué esto importa para la defensa

Si entendés **dónde** se ancla el keylogger y **qué** tiene que hacer para capturar,
guardar y enviar, cada paso es una oportunidad de detección: hooks inusuales, bucles de
sondeo, archivos de log cifrados en `%TEMP%`, tareas programadas nuevas, beacons HTTPS
periódicos. La clase práctica (`05-practica-laboratorio.md`) recorre esas oportunidades.
