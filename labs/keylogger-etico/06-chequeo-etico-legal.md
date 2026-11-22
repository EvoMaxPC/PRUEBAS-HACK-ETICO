# 06 — Marco ético y legal (lectura obligatoria)

## Principios del laboratorio

1. **Consentimiento.** Solo se ejecutan prácticas sobre sistemas propios, en la VM
   aislada, con datos ficticios. Jamás sobre equipos ajenos, ni en horario laboral,
   ni con datos reales de personas.
2. **Aislamiento.** La VM no tiene salida a Internet ni a la LAN institucional durante
   las prácticas. Red: Solo-Anfitrión o Interna.
3. **Minimización.** El material de clase no incluye un keylogger operativo global
   listo para desplegar. Se enseña el mecanismo y la defensa, no el arma.
4. **No divulgación.** Nada de lo practicado se publica, comparte ni "prueba" en
   sistemas fuera de alcance. El conocimiento se aplica a defender.
5. **Reporte responsable.** Si en el lab aparece comportamiento real sospechoso, se
   informa por los canales del curso; nunca se “experimenta” sobre él.

## Argumento legal (Argentina, orientativo — no es asesoría jurídica)

- **CP art. 153 y concordantes** (Ley 26.388): acceso ilegítimo y violación de
  comunicaciones/datos son delitos penales aunque no haya daño económico.
- **Ley 25.326 (Datos Personales)**: recolectar teclas o pulsaciones de una persona
  identificable sin consentimiento viola el principio de finalidad y licitud del tratamiento.
- **Ley 27.275 de Acceso a la Información Pública** y las pautas de la **AAIP** rigen la
  gestión de datos en organismos públicos; informarse ahí si el lab se hace en contexto estatal.
- En el ámbito laboral: el monitoreo de empleados solo es válido con política escrita,
  aviso previo y alcance proporcional; incluso así, keyloggers totales suelen ser
  desproporcionados y conflictivos con la Ley 25.326 y jurisprudencia de privacidad.

## Reglas de engagement del curso

| Regla | Descripción |
|---|---|
| Alcance | Solo la VM `lab-keylogger` del curso. |
| Ventana | Solo durante el horario de la práctica. |
| Datos | Ficticios (usuarios `estudiante01…`, contraseñas `ClaveFalsa123!`). |
| Herramientas | Las provistas en el lab; ninguna externa sin aprobación docente. |
| Reporte | Informe de práctica entregado al docente; confidencial. |
| Sanciones | Cualquier prueba fuera de alcance ⇒ expulsión del lab y aviso a la institución. |

## Por qué este enfoque es el correcto profesionalmente

Los cursos serios de seguridad (OSCP, SANS, CNCF, universidades) comparten el mismo
principio: **comprender la ofensiva para construir defensiva**, jamás producir ni
distribuir herramientas operables contra terceros. Esa es la diferencia entre un
profesional de seguridad y un delincuente con el mismo conocimiento.

## Para profundizar (fuentes abiertas)

- MITRE ATT&CK — T1056.001 Input Capture: Keylogging: https://attack.mitre.org/techniques/T1056/001/
- Microsoft Learn — Windows Hooks (WH_KEYBOARD_LL): documentación oficial de Win32.
- CISA — "Understanding and Mitigating Threats from Keyloggers" (informes públicos).
- Approved academic curricula (p. ej. materiales de cursos de seguridad de universidades
  públicas) para ejemplos de prácticas aisladas.
