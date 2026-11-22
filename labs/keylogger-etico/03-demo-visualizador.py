#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
03-demo-visualizador.py — Visualizador de eventos de teclado (DEMO DE LAB)

¿Qué es esto?
-------------
Una aplicación DIDÁCTICA para mostrar en clase cómo Windows reporta las pulsaciones:
Virtual-Key Codes, estado de modificadores, repetición automática (auto-repeat), etc.

Límites deliberados (importantes):
-----------------------------------
* SOLO registra teclas pulsadas MIENTRAS ESTA VENTANA TIENE EL FOCO.
* NO instala hooks globales, NO lee otras aplicaciones, NO oculta su presencia,
  NO persiste ni exfiltra nada. No es un keylogger.
* El "log" de la sesión se muestra en pantalla y puede exportarse a CSV a petición
  del usuario (para analizarlo en clase). El archivo es local y visible.

Conceptos que ilustra (ver 02-funcionamiento-interno.md):
-----------------------------------------------------------
* Windows traduce el scan code del hardware a un Virtual-Key (VK) según el layout.
* El estado de modificadores (Shift/Ctrl/Alt) viaja en el campo `state` del evento.
* La repetición automática genera eventos repetidos de KeyPress.
* Un keylogger real haría esto mismo pero de forma GLOBAL y ENCUBIERTA vía un hook
  de bajo nivel; este demo lo hace LOCAL y VISIBLE, acotado a su ventana.

Uso:
    python 03-demo-visualizador.py

Requisitos: Python 3 + Tkinter (incluido en el instalador estándar de Windows).
"""

import csv
import datetime
import tkinter as tk
from tkinter import ttk, filedialog, messagebox

# Tabla de Virtual-Key codes frecuentes (documentación oficial de Win32).
# En Windows, `event.keycode` de Tkinter coincide con el VK de Win32.
VK_NOMBRES = {
    0x08: "BACKSPACE", 0x09: "TAB", 0x0D: "ENTER", 0x10: "SHIFT", 0x11: "CTRL",
    0x12: "ALT", 0x1B: "ESCAPE", 0x20: "SPACE", 0x21: "PAGE UP", 0x22: "PAGE DOWN",
    0x23: "END", 0x24: "HOME", 0x25: "ARROW LEFT", 0x26: "ARROW UP",
    0x27: "ARROW RIGHT", 0x28: "ARROW DOWN", 0x2E: "DELETE", 0x5B: "LWIN",
    0xA0: "LSHIFT", 0xA1: "RSHIFT", 0xA2: "LCTRL", 0xA3: "RCTRL",
    0xA4: "LALT", 0xA5: "RALT",
}


def nombre_vk(code: int) -> str:
    if code in VK_NOMBRES:
        return VK_NOMBRES[code]
    if 0x30 <= code <= 0x39 or 0x41 <= code <= 0x5A:  # 0-9, A-Z
        return chr(code)
    if 0x70 <= code <= 0x87:  # F1..F24
        return f"F{code - 0x6F}"
    if 0x60 <= code <= 0x69:  # teclado numérico 0-9
        return f"NUMPAD {code - 0x60}"
    return f"VK 0x{code:02X}"


def modificadores(state: int) -> str:
    mods = []
    if state & 0x0001:
        mods.append("Shift")
    if state & 0x0004:
        mods.append("Control")
    if state & 0x0008:
        mods.append("Alt")
    if state & 0x0010:
        mods.append("NumLock")
    if state & 0x0080:
        mods.append("CapsLock")
    return "+".join(mods) if mods else "—"


class TecladoVisualizer(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("Visualizador de Teclado — DEMO DE LAB (solo esta ventana)")
        self.geometry("900x560")
        self.minsize(760, 480)
        self.configure(bg="#0d1117")

        self.evento_count = 0
        self.registro = []  # filas para exportar CSV

        self._build_ui()
        # Binding LOCAL a esta ventana: no es un hook global.
        self.bind("<KeyPress>", self._on_keypress)

    # ---------- UI ----------
    def _build_ui(self):
        estilo = {"bg": "#0d1117", "fg": "#e6edf3"}
        titulo = tk.Label(
            self,
            text="🔍 Visualizador de eventos de teclado",
            font=("Segoe UI", 18, "bold"), **estilo,
        )
        titulo.pack(pady=(14, 2))
        sub = tk.Label(
            self,
            text="Solo registra pulsaciones DENTRO de esta ventana · nada se oculta · nada se envía a la red",
            font=("Segoe UI", 9), fg="#8b949e", bg="#0d1117",
        )
        sub.pack(pady=(0, 10))

        # Panel "última tecla"
        panel = tk.Frame(self, bg="#161b22", bd=0, highlightthickness=1,
                         highlightbackground="#30363d")
        panel.pack(fill="x", padx=18, pady=6)

        self.lbl_tecla = tk.Label(panel, text="—", font=("Segoe UI", 56, "bold"),
                                  fg="#58a6ff", bg="#161b22", width=6)
        self.lbl_tecla.pack(side="left", padx=24, pady=10)

        info = tk.Frame(panel, bg="#161b22")
        info.pack(side="left", padx=10, pady=10, fill="x", expand=True)
        self.lbl_detalle = tk.Label(
            info,
            text="Virtual-Key: —\nScan code / keycode: —\nModificadores: —\nCarácter: —",
            font=("Consolas", 11), fg="#c9d1d9", bg="#161b22",
            justify="left", anchor="w",
        )
        self.lbl_detalle.pack(anchor="w")

        # Tabla de eventos
        columnas = ("hora", "tecla", "vk", "mods", "char")
        self.tree = ttk.Treeview(self, columns=columnas, show="headings", height=10)
        for col, texto, ancho in [
            ("hora", "Hora", 130), ("tecla", "Tecla (nombre)", 160),
            ("vk", "VK (hex)", 90), ("mods", "Modificadores", 160), ("char", "Char", 80),
        ]:
            self.tree.heading(col, text=texto)
            self.tree.column(col, width=ancho, anchor="center")
        self.tree.pack(fill="both", expand=True, padx=18, pady=10)

        # Barra de estado + botones
        barra = tk.Frame(self, bg="#0d1117")
        barra.pack(fill="x", padx=18, pady=(0, 12))
        self.lbl_total = tk.Label(barra, text="Eventos: 0", font=("Segoe UI", 10),
                                  **estilo)
        self.lbl_total.pack(side="left")
        tk.Button(barra, text="Exportar CSV…", command=self.exportar_csv,
                  bg="#238636", fg="white", relief="flat", padx=12).pack(side="right", padx=4)
        tk.Button(barra, text="Limpiar", command=self.limpiar,
                  bg="#30363d", fg="#e6edf3", relief="flat", padx=12).pack(side="right", padx=4)

        pista = tk.Label(
            self, text="💡 Escribí en esta ventana y observá cómo se traduce cada pulsación (Shift+A, F5, flechas…)",
            font=("Segoe UI", 9, "italic"), fg="#8b949e", bg="#0d1117",
        )
        pista.pack(pady=(0, 10))

    # ---------- Lógica ----------
    def _on_keypress(self, event: tk.Event):
        self.evento_count += 1
        hora = datetime.datetime.now().strftime("%H:%M:%S.%f")[:-3]
        vk = event.keycode
        nombre = nombre_vk(vk)
        mods = modificadores(event.state)
        char = event.char if event.char and event.char.isprintable() else "—"

        # Panel grande
        self.lbl_tecla.config(text=(char if char != "—" else nombre)[:3])
        self.lbl_detalle.config(
            text=f"Virtual-Key: {nombre} ({vk} / 0x{vk:02X})\n"
                 f"Scan code / keycode reportado: {vk}\n"
                 f"Modificadores (state={event.state}): {mods}\n"
                 f"Carácter generado: {char}"
        )
        self.lbl_total.config(text=f"Eventos: {self.evento_count}")

        # Tabla + registro
        fila = (hora, nombre, f"0x{vk:02X}", mods, char)
        self.tree.insert("", 0, values=fila)
        self.registro.append(fila)

    def limpiar(self):
        self.tree.delete(*self.tree.get_children())
        self.registro.clear()
        self.evento_count = 0
        self.lbl_total.config(text="Eventos: 0")
        self.lbl_tecla.config(text="—")
        self.lbl_detalle.config(text="Virtual-Key: —\nScan code / keycode: —\nModificadores: —\nCarácter: —")

    def exportar_csv(self):
        if not self.registro:
            messagebox.showinfo("Exportar CSV", "No hay eventos registrados todavía.")
            return
        ruta = filedialog.asksaveasfilename(
            defaultextension=".csv",
            filetypes=[("CSV", "*.csv")],
            initialfile="evento_teclado_demo.csv",
            title="Guardar registro de la sesión (local)",
        )
        if not ruta:
            return
        with open(ruta, "w", newline="", encoding="utf-8") as f:
            w = csv.writer(f)
            w.writerow(["hora", "tecla", "vk_hex", "modificadores", "char"])
            w.writerows(self.registro)
        messagebox.showinfo("Exportar CSV", f"Guardado en:\n{ruta}")


if __name__ == "__main__":
    app = TecladoVisualizer()
    app.mainloop()
