<#
.SYNOPSIS
    Visualizador de eventos de teclado - DEMO DE LAB (Windows nativo, WinForms).

.DESCRIPTION
    Aplicacion DIDACTICA para Windows 11/10 que muestra COMO Windows reporta las
    pulsaciones: KeyCode (Virtual-Key), KeyValue (VK numerico), modificadores
    (Shift/Ctrl/Alt), auto-repeat y caracter generado.

    LIMITES DELIBERADOS (importantes):
    * SOLO registra pulsaciones MIENTRAS ESTA VENTANA tiene el foco.
    * NO instala hooks globales (no usa WH_KEYBOARD_LL ni SetWindowsHookEx).
    * NO lee otras aplicaciones, NO oculta su presencia, NO persiste, NO exfiltra.
    * NO es un keylogger. El registro de sesion es local, visible y exportable a CSV.

    CONCEPTOS QUE ILUSTRA (ver 02-funcionamiento-interno.md):
    * Windows traduce el scan code del hardware a un Virtual-Key segun el layout.
    * Los modificadores viajan como flags en KeyEventArgs.
    * La repeticion automatica genera eventos repetidos de KeyDown.
    * Un keylogger real hace esto de forma GLOBAL y ENCUBIERTA; este demo lo hace
      LOCAL y VISIBLE, acotado a su ventana - seguro para proyectar en clase.

.USAGE
    En la VM de Windows 11 del lab, abrir PowerShell y ejecutar:
        powershell -ExecutionPolicy Bypass -File .\03-demo-visualizador-windows.ps1
    (o doble clic si la politica de ejecucion ya lo permite)

.NOTES
    Requiere: Windows 10/11 con .NET Framework (incluido) y PowerShell 5.1+.
    Sin dependencias externas. Sin conexion de red.
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ---------- Datos de sesion ----------
$script:registro = New-Object System.Collections.Generic.List[object]
$script:totalEventos = 0
$script:ultimoChar = ""
$script:ultimoItem = $null
$script:ultimoRegistroIdx = -1

# ---------- Formulario principal ----------
$form = New-Object System.Windows.Forms.Form
$form.Text = "Visualizador de Teclado - DEMO DE LAB (solo esta ventana)"
$form.Size = New-Object System.Drawing.Size(920, 620)
$form.MinimumSize = New-Object System.Drawing.Size(760, 500)
$form.BackColor = [System.Drawing.Color]::FromArgb(13, 17, 23)
$form.KeyPreview = $true   # la ventana recibe los eventos de sus controles
$form.StartPosition = "CenterScreen"

$fuente = New-Object System.Drawing.Font("Segoe UI", 9)
$fuenteMono = New-Object System.Drawing.Font("Consolas", 10)
$colorTexto = [System.Drawing.Color]::FromArgb(230, 237, 243)
$colorDim = [System.Drawing.Color]::FromArgb(139, 148, 158)
$colorAzul = [System.Drawing.Color]::FromArgb(88, 166, 255)

# ---------- Titulo y aviso ----------
$lblTitulo = New-Object System.Windows.Forms.Label
$lblTitulo.Text = " Visualizador de eventos de teclado"
$lblTitulo.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$lblTitulo.ForeColor = $colorTexto
$lblTitulo.AutoSize = $true
$lblTitulo.Location = New-Object System.Drawing.Point(18, 12)
$form.Controls.Add($lblTitulo)

$lblAviso = New-Object System.Windows.Forms.Label
$lblAviso.Text = "SOLO registra pulsaciones DENTRO de esta ventana - visible - nada se oculta - nada se envia a la red"
$lblAviso.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$lblAviso.ForeColor = $colorDim
$lblAviso.AutoSize = $true
$lblAviso.Location = New-Object System.Drawing.Point(18, 42)
$form.Controls.Add($lblAviso)

# ---------- Panel "ultima tecla" ----------
$panel = New-Object System.Windows.Forms.Panel
$panel.Location = New-Object System.Drawing.Point(18, 66)
$panel.Size = New-Object System.Drawing.Size(868, 110)
$panel.BackColor = [System.Drawing.Color]::FromArgb(22, 27, 34)
$form.Controls.Add($panel)

$lblTeclaGrande = New-Object System.Windows.Forms.Label
$lblTeclaGrande.Text = "-"
$lblTeclaGrande.Font = New-Object System.Drawing.Font("Segoe UI", 44, [System.Drawing.FontStyle]::Bold)
$lblTeclaGrande.ForeColor = $colorAzul
$lblTeclaGrande.Size = New-Object System.Drawing.Size(180, 90)
$lblTeclaGrande.TextAlign = "MiddleCenter"
$lblTeclaGrande.Location = New-Object System.Drawing.Point(16, 10)
$panel.Controls.Add($lblTeclaGrande)

$lblDetalle = New-Object System.Windows.Forms.Label
$lblDetalle.Text = "Virtual-Key: -`nVK (dec/hex): -`nModificadores: -`nKeyData: -"
$lblDetalle.Font = $fuenteMono
$lblDetalle.ForeColor = [System.Drawing.Color]::FromArgb(201, 209, 217)
$lblDetalle.Size = New-Object System.Drawing.Size(620, 100)
$lblDetalle.Location = New-Object System.Drawing.Point(210, 8)
$panel.Controls.Add($lblDetalle)

# ---------- Lista de eventos ----------
$listView = New-Object System.Windows.Forms.ListView
$listView.View = "Details"
$listView.FullRowSelect = $true
$listView.GridLines = $true
$listView.BackColor = [System.Drawing.Color]::FromArgb(22, 27, 34)
$listView.ForeColor = $colorTexto
$listView.Font = $fuenteMono
$listView.Location = New-Object System.Drawing.Point(18, 186)
$listView.Size = New-Object System.Drawing.Size(868, 300)
[void]$listView.Columns.Add("Hora", 110)
[void]$listView.Columns.Add("Tecla (KeyCode)", 180)
[void]$listView.Columns.Add("VK (hex)", 80)
[void]$listView.Columns.Add("Modificadores", 160)
[void]$listView.Columns.Add("Char", 80)
[void]$listView.Columns.Add("KeyData", 220)
$form.Controls.Add($listView)

# ---------- Barra inferior ----------
$lblTotal = New-Object System.Windows.Forms.Label
$lblTotal.Text = "Eventos: 0"
$lblTotal.ForeColor = $colorTexto
$lblTotal.Font = $fuente
$lblTotal.AutoSize = $true
$lblTotal.Location = New-Object System.Drawing.Point(18, 500)
$form.Controls.Add($lblTotal)

$btnExportar = New-Object System.Windows.Forms.Button
$btnExportar.Text = "Exportar CSV..."
$btnExportar.BackColor = [System.Drawing.Color]::FromArgb(35, 134, 54)
$btnExportar.ForeColor = [System.Drawing.Color]::White
$btnExportar.FlatStyle = "Flat"
$btnExportar.Size = New-Object System.Drawing.Size(130, 32)
$btnExportar.Location = New-Object System.Drawing.Point(672, 494)
$form.Controls.Add($btnExportar)

$btnLimpiar = New-Object System.Windows.Forms.Button
$btnLimpiar.Text = "Limpiar"
$btnLimpiar.BackColor = [System.Drawing.Color]::FromArgb(48, 54, 61)
$btnLimpiar.ForeColor = $colorTexto
$btnLimpiar.FlatStyle = "Flat"
$btnLimpiar.Size = New-Object System.Drawing.Size(90, 32)
$btnLimpiar.Location = New-Object System.Drawing.Point(566, 494)
$form.Controls.Add($btnLimpiar)

$lblPista = New-Object System.Windows.Forms.Label
$lblPista.Text = " Escribi en esta ventana y observa como Windows traduce cada pulsacion (Shift+A, F5, flechas, numpad...)"
$lblPista.ForeColor = $colorDim
$lblPista.Font = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Italic)
$lblPista.AutoSize = $true
$lblPista.Location = New-Object System.Drawing.Point(18, 540)
$form.Controls.Add($lblPista)

# ---------- Helpers ----------
function Get-Modificadores([System.Windows.Forms.KeyEventArgs]$e) {
    $mods = @()
    if ($e.Shift)   { $mods += "Shift" }
    if ($e.Control) { $mods += "Control" }
    if ($e.Alt)     { $mods += "Alt" }
    if ($mods.Count -eq 0) { return "-" }
    return ($mods -join "+")
}

function Actualizar-Registro {
    param([string]$Tecla, [int]$VK, [string]$Mods, [string]$Char, [string]$KeyData)

    $script:totalEventos++
    $hora = (Get-Date).ToString("HH:mm:ss.fff")
    $vkHex = ("0x{0:X2}" -f $VK)
    $filaTexto = @($hora, $Tecla, $vkHex, $Mods, $(if ($Char) { $Char } else { "-" }), $KeyData)

    $item = New-Object System.Windows.Forms.ListViewItem($filaTexto[0])
    for ($i = 1; $i -lt $filaTexto.Count; $i++) { [void]$item.SubItems.Add([string]$filaTexto[$i]) }
    $listView.Items.Insert(0, $item)
    $script:ultimoItem = $item
    $script:ultimoRegistroIdx = $script:registro.Count

    $script:registro.Add([pscustomobject]@{
        hora = $hora; tecla = $Tecla; vk_hex = $vkHex; modificadores = $Mods
        char = $(if ($Char) { $Char } else { "-" }); keydata = $KeyData
    })

    $lblTeclaGrande.Text = if ($Char) { [string]$Char } else { $Tecla.Substring(0, [Math]::Min(3, $Tecla.Length)) }
    $lblDetalle.Text = "Virtual-Key: $Tecla`nVK (dec/hex): $VK / $vkHex`nModificadores: $Mods`nKeyData: $KeyData"
    $lblTotal.Text = "Eventos: $script:totalEventos"
}

# ---------- Eventos ----------
# KeyDown se dispara con el Virtual-Key crudo (lo que un hook veria).
# En WinForms KeyDown va ANTES que KeyPress, asi que registramos la fila aca
# y KeyPress la completa con el caracter traducido por Windows.
$form.Add_KeyDown({
    param($sender, $e)
    $script:ultimoChar = ""
    Actualizar-Registro -Tecla $e.KeyCode.ToString() -VK $e.KeyValue -Mods (Get-Modificadores $e) -Char "" -KeyData $e.KeyData.ToString()
})

# KeyPress se dispara con el caracter ya traducido (respeta layout y Shift).
# Parchea la fila recien creada por KeyDown: columna Char (indice 4) y su copia en $registro.
$form.Add_KeyPress({
    param($sender, $e)
    if ($e.KeyChar -lt 32 -or [char]::IsControl($e.KeyChar)) { return }
    $char = [string]$e.KeyChar
    if ($script:ultimoItem -ne $null -and $script:ultimoRegistroIdx -lt $script:registro.Count) {
        $script:ultimoItem.SubItems[4].Text = $char
        $script:registro[$script:ultimoRegistroIdx].char = $char
        $lblTeclaGrande.Text = $char
    }
})

$btnLimpiar.Add_Click({
    $listView.Items.Clear()
    $script:registro.Clear()
    $script:totalEventos = 0
    $lblTotal.Text = "Eventos: 0"
    $lblTeclaGrande.Text = "-"
    $lblDetalle.Text = "Virtual-Key: -`nVK (dec/hex): -`nModificadores: -`nKeyData: -"
})

$btnExportar.Add_Click({
    if ($script:registro.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("No hay eventos registrados todavia.", "Exportar CSV") | Out-Null
        return
    }
    $dlg = New-Object System.Windows.Forms.SaveFileDialog
    $dlg.Filter = "CSV (*.csv)|*.csv"
    $dlg.FileName = "evento_teclado_demo.csv"
    $dlg.Title = "Guardar registro de la sesion (local)"
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $script:registro | Export-Csv -Path $dlg.FileName -NoTypeInformation -Encoding UTF8
        [System.Windows.Forms.MessageBox]::Show("Guardado en:`n$($dlg.FileName)", "Exportar CSV") | Out-Null
    }
})

# ---------- Run ----------
[void]$form.ShowDialog()
$form.Dispose()
