# 01 — Teoría: ¿qué es un keylogger?

## Definición

Un **keylogger** (registrador de teclas) es cualquier mecanismo —software, hardware o
firmware— que intercepta y registra las pulsaciones del teclado. Lo que lo convierte en
herramienta ofensiva no es la captura en sí, sino **la captura no autorizada y encubierta**.

## Casos de uso legítimos (con consentimiento explícito)

- Diagnóstico y soporte técnico (p. ej. verificar layout de teclado, accesibilidad).
- Software parental y control empresarial **con aviso y consentimiento** conforme a la ley.
- Investigación de malware y análisis forense en entornos controlados.
- Estudios de usabilidad (captura dentro de una aplicación propia, visible para el usuario).

## Casos ilegítimos

- Robo de credenciales (banca online, VPN, correo).
- Espionaje corporativo, stalkerware y vigilancia doméstica sin consentimiento.
- Exfiltración de secretos comerciales.

## Taxonomía

### 1. Keyloggers de software (user-mode)

Los más comunes en campañas reales. Se apoyan en mecanismos que Windows ofrece
legítimamente a las aplicaciones (ver `02-funcionamiento-interno.md`):

| Mecanismo | Idea central | Visibilidad para el defensor |
|---|---|---|
| Hook de teclado de bajo nivel (`WH_KEYBOARD_LL`) | Se registra una función que recibe las pulsaciones antes que la ventana destino | Alta: aparece en la lista de hooks, DLL sospechosa cargada |
| Sondeo de estado (`GetAsyncKeyState` / `GetKeyboardState`) | Bucle que consulta si cada tecla está presionada | Media: proceso con bucle de sondeo y consumo regular de CPU |
| Registro por mensaje a ventana (`SetWindowsHookEx` clásico) | Inyección de DLL en procesos que reciben teclas | Alta: módulo inyectado en procesos ajenos (detectable con Process Explorer) |
| Hook de foco / formularios | Intercepta solo campos de contraseña o ventanas concretas | Media-alta |
| Portapapeles + capturas de pantalla | Complementa teclas con copiar/pegar y screens | Alta en red y en disco |

### 2. Keyloggers de kernel (driver-mode)

Un driver firmado (o cargado con bypass de firma) intercepta a nivel de pila de
teclado. Mucho más sigilosos y potentes; requieren privilegios de administrador y suelen
dejar rastros en controladores cargados (`Autoruns → Drivers`).

### 3. Keyloggers de hardware

Dispositivos intercalados físicamente entre teclado y PC (USB/PS2) o integrados en
teclados inalámbricos comprometidos. No ejecutan software en el host: se detectan con
**inspección física**, no con antivirus. Riesgo típico en kioscos, recepciones y equipos
compartidos.

### 4. Keyloggers de firmware / nivel BIOS-UEFI

Modifican firmware (del teclado, del controlador embebido o UEFI). Raros, caros y
persistentes incluso tras reinstalar el SO. Detección: análisis de integridad de firmware,
secure boot, TPM.

### 5. Acústicos y electromagnéticos (analíticos)

Inferencia de teclas por sonido o emanaciones. Tema de investigación académica; relevante
para amenaza estatal, no para el lab práctico.

## Por qué existen tantos tipos

Cada uno ataca una **capa distinta** del camino que sigue una tecla:

```
Teclado físico → controlador USB/PS2 → pila de teclado del kernel
   → cola de entrada (raw input / messages) → hooks → ventana destino
```

Un keylogger se posiciona en una de esas capas. Cuanto más abajo, más sigiloso y más
privilegiado; cuanto más arriba, más fácil de desarrollar y de detectar.

## Contexto real

- Familias como **Agent Tesla**, **Snake Keylogger**, **RedLine Stealer** y variantes de
  **LokiBot** incluyen keylogging como módulo dentro de un stealer mayor: no roban solo
  teclas, sino credenciales del navegador, cookies y monederos cripto.
- El keylogging puro "de libro" es hoy un componente más dentro de malware-as-a-service.
- MITRE ATT&CK lo cataloga como [T1056.001 – Input Capture: Keylogging](https://attack.mitre.org/techniques/T1056/001/).

## Marco legal (Argentina)

- El **Código Penal Argentino** sanciona el acceso ilegítimo a sistemas y la interceptación
  no autorizada de comunicaciones y datos (arts. 153 y ss. y Ley 26.388 de delitos
  informáticos).
- La **Ley 25.326 de Protección de Datos Personales** exige consentimiento para la
  recolección de datos de personas identificables.
- Fuera de un laboratorio aislado y sin autorización escrita del dueño del sistema, operar
  un keylogger es un delito, aunque el objetivo sea "probar seguridad".
- Por eso el lab trabaja **dentro de la VM**, con datos ficticios y sin conexión externa.
