# 04 — Detección y prevención

La mitad más importante del módulo. Si solo enseñamos el ataque, la clase queda en
"wow"; si enseñamos a verlo y cortarlo, queda en competencia profesional.

## 1. Prevención (reducir la superficie)

### Endurecimiento de Windows
- **Parcheado** del SO y navegador al día; muchas infecciones de stealers entran por exploits
  del navegador y buscadores de "cracked software".
- **UAC** en nivel alto; cuenta de usuario estándar para el día a día (sin admin).
- **Control de aplicaciones**: AppLocker o WDAC para permitir solo binarios firmados/conocidos.
- **Microsoft Defender** con protección en tiempo real, PUA/PUA bloqueado y tamper protection.
- **EDR** con reglas de comportamiento (no solo firmas): detecta bucles de sondeo, hooks LL,
  inyección de DLL y beaconing C2.
- **MFA siempre**: un keylogger que robe la contraseña igual choca con el segundo factor.
  Preferir **app authenticator / llaves FIDO2** sobre SMS; FIDO2 es resistente a replay.
- **Gestor de contraseñas**: contraseñas únicas y largas; el daño de una tecla robada se
  limita a una cuenta. (El autotipeado del gestor reduce exposición aunque no la elimina.)
- **Teclado en pantalla** mitiga algunos keyloggers de software básicos (no todos), pero
  **nunca** protege contra uno de kernel bien hecho ni contra hardware keyloggers.
- **USB**: bloquear puertos no autorizados / lista blanca de dispositivos (GPO) para
  hardware keyloggers; inspección física periódica en puestos compartidos (kioscos,
  recepción, salas de reuniones).
- **Cuentas de servicio** con privilegio mínimo; nada de admin para uso cotidiano.
- **Segmentación**: la VM del lab, los endpoints de producción y la administración nunca
  comparten credenciales ni red.

### Higiene de navegación y correo
- Bloqueo de macros de Office por GPO; bloqueo de ejecutables en carpetas de usuario.
- Formación anti-phishing: la vía de entrega #1 de los stealers con keylogger.
- Bloqueo de dominios recién registrados y categorías de riesgo en el proxy web.

## 2. Detección (ver lo que pasa)

### Herramientas del lab
| Herramienta | Para qué
|---|---|
| **Sysmon** + config tipo *SwiftOnSecurity* o *sysmon-modular* | Telemetría rica: creación de procesos, carga de drivers, acceso a procesos, conexiones de red. |
| **Visor de eventos** (`eventvwr.msc`) | Canales de seguridad y de Defender; hallazgos de tamper/PUA. |
| **Process Explorer** | Árbol de procesos, firma de binarios, DLLs cargadas (detección de hook DLL clásico). |
| **Process Monitor (procmon)** | Trazas de registro/archivo: archivos de log cifrados creciendo en `%TEMP%`/`%APPDATA%`. |
| **Autoruns** | Persistencia: Run keys, tareas, servicios, drivers, suscripciones WMI. |
| **Wireshark / pktmon** | Beaconing HTTPS/DNS periódico a C2. |
| **Microsoft Defender (o EDR de prueba)** | Veredictos y cuarentena en vivo durante la demo. |

### Eventos y señales clave (Sysmon)
- **Event ID 1** — Creación de proceso: binarios en `%TEMP%`, `%APPDATA%`, nombres que
  imitan sistema, comandos con ofuscación.
- **Event ID 3** — Conexión de red: endpoints con **beaconing periódico** (ej. POST cada
  5 min) y destinos no habituales.
- **Event ID 7** — Carga de imagen/DLL: DLLs sin firma cargadas en procesos comunes.
- **Event ID 8** — CreateRemoteThread: inyección (hooks clásicos con DLL).
- **Event ID 13/14** — Escritura en registro (Run keys).
- **Event ID 15/11/26** — Creación/stream de archivo anómalo en carpetas temporales.
- **Event ID 6** — Driver cargado: controlador no estándar o sin firma → posible keylogger de kernel.

### Reglas de detección (conceptuales — para adaptar en el EDR/SIEM)
1. **Proceso de usuario con hook LL instalado + Run key** → casi siempre malicioso.
2. **Bucle de sondeo**: alta frecuencia de `user32!GetAsyncKeyState` con bajo volumen de
   otras llamadas → heurística de stealers.
3. **Archivo que crece linealmente** en rutas de usuario con contenido de alta entropía
   (cifrado) y luego se borra → posible log de keylogger.
4. **Beaconing**: conexiones salientes periódicas de intervalos regulares a un mismo
   destino; combinado con "proceso sin descripción/firma" es hallazgo sólido.
5. **Auto-inicio duplicado**: misma ruta en `Run` y en tarea programada → sospechoso.

> En el lab, las "reglas" se ejercitan como **ejercicios de caza** (ver 05): se observan
> telemetrías y el estudiante propone el disparador, no se memoriza una firma.

### IoCs típicos de familias reales (ejemplos de clase)
- **Agent Tesla**: exfil vía SMTP/FTP/Telegram; inyección en `RegAsm.exe`/`MSBuild.exe`;
  prevalece como adjunto de correo con doble extensión (`factura.pdf.exe`).
- **Snake Keylogger**: parecido patrón; suele usar formularios web C2 y persistencia por
  `HKCU\Run`; empaquetado con packers comerciales.
- **RedLine/Vidar**: focus en credenciales de navegador + wallets; drops en `%APPDATA%`.
- **LokiBot**: inyección en procesos legítimos y exfil HTTP POST clásico.

(Estos nombres son públicos en informes de threat intel — CISA, Unit42, Microsoft DCR —;
usarlos como casos de estudio, nunca como “recetas”.)

## 3. Respuesta ante un hallazgo

1. **Aislar** el equipo (desconectar de red) — cortar exfiltración en curso.
2. **Preservar evidencia**: imagen de RAM/disco si hay forensics; no apagar a lo bruto si
   se puede hibernar/capturar memoria.
3. **Revocar credenciales** usadas en ese equipo desde otro dispositivo limpio (correo,
   banca, VPN, gestores). Asumir compromiso de todo lo tecleado.
4. **Reinstalar desde imagen limpia** (mejor que "limpiar" un host comprometido).
5. **Post-mortem**: ¿vector de entrada? ¿qué controles fallaron? Actualizar reglas y
   conciencia del usuario.
6. **Notificación**: internamente y, si corresponde, al regulador (en AR: AAIP) y al
   titular de datos si hubo fuga personal.

## 4. Hardware keyloggers: controles específicos

- Inventario físico periódico de periféricos en puestos expuestos.
- Sellos/inspección de puertos USB en kioscos y equipos de recepción.
- Cámaras o control de acceso físico a salas de servidores/recepción.
- Política de periféricos personales: teclados propios no se conectan a puestos sensibles.
- Cables USB "de confianza" o con filtro de datos para estaciones críticas.

## 5. Checklist rápida para enseñar en clase

- [ ] MFA activado en todo acceso remoto y correo.
- [ ] Sysmon desplegado con config comunitaria.
- [ ] Autoruns revisado mensualmente.
- [ ] AppLocker/WDAC en modo audit o enforce.
- [ ] USB restringido por GPO/lista blanca.
- [ ] EDR con reglas de comportamiento activas.
- [ ] Plan de respuesta a incidentes impreso y probado (simulacro).
- [ ] Formación anti-phishing trimestral con métricas.
- [ ] Inventario de periféricos en puestos públicos.
- [ ] Backups 3-2-1 offline para recuperación post-incidente.
