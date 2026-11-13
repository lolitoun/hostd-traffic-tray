# =============================================================================
#  hostd daily traffic - two tray icons next to the clock (Windows)
# =============================================================================
#  [EN]
#  Shows today's hostd traffic (since local midnight) as TWO icons in the
#  Windows notification area, next to the clock:
#    - BLUE icon = sent today     (egress: data downloaded by renters)
#    - PINK icon = received today (ingress: data uploaded by renters)
#  Same units as the hostd web UI (decimal GB / TB). Icon text: 3.2 / 38 / 386
#  (GB), then 1.3T (TB) above 1000 GB. Hover an icon for the exact value.
#  Right-click: Refresh / Quit. Refreshes every minute (2 light API calls).
#  Read-only: it only reads hostd's local API (/api/metrics), changes nothing.
#  The hostd UI password is asked at startup and is never saved to disk.
#  If hostd cannot be reached, both icons turn grey with "!".
#
#  Requirements: Windows 10/11, Windows PowerShell 5.1 (built in), hostd running
#  on the same machine with its UI on http://127.0.0.1:9980 (default).
#
#  Start without a console window (adjust the path):
#    conhost.exe --headless powershell.exe -ExecutionPolicy Bypass -File "C:\path\to\hostd-traffic-tray.ps1"
#  or double-click hostd-traffic-tray.bat (same folder).
#  If the icons are hidden: Settings > Personalization > Taskbar >
#  Other system tray icons > turn on "Windows PowerShell".
#
#  [FR]
#  Affiche le trafic hostd du jour (depuis minuit) en DEUX icones dans la zone
#  de notification, pres de l'horloge :
#    - icone BLEUE = envoye aujourd'hui (egress : ce que les clients telechargent)
#    - icone ROSE  = recu aujourd'hui   (ingress : ce que les clients deposent)
#  Memes unites que l'interface hostd (GB / TB decimaux). Texte de l'icone :
#  3.2 / 38 / 386 (GB), puis 1.3T (TB) au-dela de 1000 GB. Passer la souris
#  sur une icone = valeur exacte. Clic droit : Actualiser / Quitter.
#  Mise a jour chaque minute (2 petites requetes a l'API).
#  Lecture seule : lit seulement l'API locale de hostd (/api/metrics).
#  Le mot de passe de l'interface hostd est demande au lancement et n'est
#  jamais enregistre. Si hostd ne repond pas, les icones deviennent grises "!".
#
#  Lancement sans fenetre noire (adapter le chemin) :
#    conhost.exe --headless powershell.exe -ExecutionPolicy Bypass -File "C:\chemin\vers\hostd-traffic-tray.ps1"
#  ou double-cliquer sur hostd-traffic-tray.bat (dans le meme dossier).
#  Si les icones sont masquees : Parametres > Personnalisation > Barre des
#  taches > Autres icones de barre d'etat systeme > activer "Windows PowerShell".
#
#  Interface language: English by default. Set $Langue = 'fr' (French) or 'auto'
#  (follow Windows) below. / Langue : anglais par defaut ; mettre $Langue = 'fr'
#  (francais) ou 'auto' (suivre Windows) plus bas.
#  File intentionally without accents (Windows PowerShell 5.1 misreads UTF-8 without BOM).
# =============================================================================

param([switch]$TestRendu)   # -TestRendu : save sample icons as PNG (check only, no hostd needed)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -Namespace TraficHostd -Name Natif -MemberDefinition '[DllImport("user32.dll")] public static extern bool DestroyIcon(IntPtr h);'

$api        = 'http://127.0.0.1:9980/api'
$intervalle = 60000   # ms = 1 minute
$inv        = [Globalization.CultureInfo]::InvariantCulture   # point decimal, comme hostd

# --- Interface language / langue de l'interface ---
# 'en' = English (default), 'fr' = francais, 'auto' = follow Windows / suivre Windows
$Langue = 'en'
$fr = ($Langue -eq 'fr') -or ($Langue -eq 'auto' -and (Get-UICulture).TwoLetterISOLanguageName -eq 'fr')
if ($fr) {
  $T = @{
    Titre    = 'Trafic hostd'
    MotPasse = "Mot de passe de l'interface hostd :"
    Envoye   = 'Envoy' + [char]0xE9 + " aujourd'hui"
    Recu     = 'Re' + [char]0xE7 + "u aujourd'hui"
    Erreur   = 'hostd injoignable'
    Actualiser = 'Actualiser'
    Quitter  = 'Quitter'
  }
} else {
  $T = @{
    Titre    = 'hostd traffic'
    MotPasse = 'hostd UI password:'
    Envoye   = 'Sent today'
    Recu     = 'Received today'
    Erreur   = 'hostd unreachable'
    Actualiser = 'Refresh'
    Quitter  = 'Quit'
  }
}

$bleu = [System.Drawing.Color]::FromArgb(37, 99, 235)    # courbe egress de hostd
$rose = [System.Drawing.Color]::FromArgb(219, 39, 119)   # courbe ingress de hostd
$gris = [System.Drawing.Color]::FromArgb(110, 110, 110)

function New-IconeTexte([string]$texte, [System.Drawing.Color]$fond) {
  $bmp = New-Object System.Drawing.Bitmap 32, 32
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
  $g.Clear($fond)
  $taille = 22
  while ($true) {
    $police = New-Object System.Drawing.Font 'Segoe UI', $taille, ([System.Drawing.FontStyle]::Bold), ([System.Drawing.GraphicsUnit]::Pixel)
    $mesure = $g.MeasureString($texte, $police)
    if ($mesure.Width -le 36 -or $taille -le 9) { break }
    $police.Dispose(); $taille--
  }
  $format = New-Object System.Drawing.StringFormat
  $format.Alignment = [System.Drawing.StringAlignment]::Center
  $format.LineAlignment = [System.Drawing.StringAlignment]::Center
  $zone = New-Object System.Drawing.RectangleF -2, 0, 36, 33
  $g.DrawString($texte, $police, [System.Drawing.Brushes]::White, $zone, $format)
  $g.Dispose(); $police.Dispose(); $format.Dispose()
  if ($TestRendu) { return $bmp }
  $h = $bmp.GetHicon()
  $icone = ([System.Drawing.Icon]::FromHandle($h)).Clone()
  [TraficHostd.Natif]::DestroyIcon($h) | Out-Null
  $bmp.Dispose()
  return $icone
}

# Texte court dans l'icone (GB, puis TB au-dela de 1000 GB)
function Format-Court([double]$octets) {
  $gb = $octets / 1e9
  if ($gb -lt 10)   { return $gb.ToString('0.0', $inv) }
  if ($gb -lt 1000) { return $gb.ToString('0', $inv) }
  return ($gb / 1000).ToString('0.0', $inv) + 'T'
}

# Texte de l'info-bulle, comme l'interface hostd (ex. 140.77 GB, 3.32 TB)
function Format-Long([double]$octets) {
  if ($octets -ge 1e12) { return ($octets / 1e12).ToString('0.00', $inv) + ' TB' }
  if ($octets -ge 1e9)  { return ($octets / 1e9).ToString('0.00', $inv) + ' GB' }
  return ($octets / 1e6).ToString('0.00', $inv) + ' MB'
}

# --- Mode verification : quelques icones en PNG, sans contacter hostd ---
if ($TestRendu) {
  $dossier = Join-Path $PSScriptRoot 'apercu_icones'
  New-Item -ItemType Directory -Force $dossier | Out-Null
  $exemples = @(@((Format-Court 3.2e9), $bleu), @((Format-Court 38.6e9), $bleu), @((Format-Court 386e9), $rose), @((Format-Court 1.34e12), $bleu), @('!', $gris))
  $i = 0
  foreach ($ex in $exemples) {
    $b = New-IconeTexte $ex[0] $ex[1]
    $b.Save((Join-Path $dossier "icone_$i.png")); $b.Dispose(); $i++
  }
  Write-Host "Saved to / enregistre dans : $dossier"
  Write-Host ('Tooltip / info-bulle : ' + $T.Envoye + ' : ' + (Format-Long 140.77e9) + ' | ' + (Format-Long 3.32e12))
  return
}

# --- Mot de passe (petite fenetre, caracteres masques) ---
$form = New-Object System.Windows.Forms.Form
$form.Text = $T.Titre
$form.Size = New-Object System.Drawing.Size 320, 150
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false; $form.MinimizeBox = $false; $form.TopMost = $true
$label = New-Object System.Windows.Forms.Label
$label.Text = $T.MotPasse
$label.Location = New-Object System.Drawing.Point 12, 12
$label.AutoSize = $true
$saisie = New-Object System.Windows.Forms.TextBox
$saisie.UseSystemPasswordChar = $true
$saisie.Location = New-Object System.Drawing.Point 12, 36
$saisie.Width = 280
$ok = New-Object System.Windows.Forms.Button
$ok.Text = 'OK'
$ok.Location = New-Object System.Drawing.Point 217, 70
$ok.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $ok
$form.Controls.AddRange(@($label, $saisie, $ok))
if ($form.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK -or -not $saisie.Text) { return }
$headers = @{ Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(':' + $saisie.Text)) }
$form.Dispose()

# --- Les deux icones ---
$icoEnvoye = New-Object System.Windows.Forms.NotifyIcon
$icoRecu   = New-Object System.Windows.Forms.NotifyIcon

$menu = New-Object System.Windows.Forms.ContextMenuStrip
$menu.Items.Add($T.Actualiser).Add_Click({ Mettre-AJour }) | Out-Null
$menu.Items.Add($T.Quitter).Add_Click({
  $icoEnvoye.Visible = $false; $icoRecu.Visible = $false
  $icoEnvoye.Dispose(); $icoRecu.Dispose()
  [System.Windows.Forms.Application]::Exit()
}) | Out-Null
$icoEnvoye.ContextMenuStrip = $menu
$icoRecu.ContextMenuStrip = $menu

function Set-Icone($notify, [string]$texte, $fond, [string]$infobulle) {
  $ancienne = $notify.Icon
  $notify.Icon = New-IconeTexte $texte $fond
  if ($infobulle.Length -gt 63) { $infobulle = $infobulle.Substring(0, 63) }
  $notify.Text = $infobulle
  $notify.Visible = $true
  if ($ancienne) { $ancienne.Dispose() }
}

function Mettre-AJour {
  $heure = Get-Date -Format 'HH:mm'
  try {
    $minuit = [uri]::EscapeDataString((Get-Date).Date.ToString('yyyy-MM-ddTHH:mm:sszzz', $inv))
    $now   = Invoke-RestMethod "$api/metrics" -Headers $headers -TimeoutSec 30
    $debut = Invoke-RestMethod "$api/metrics?timestamp=$minuit" -Headers $headers -TimeoutSec 30
    $envoye = [double]$now.data.rhp.egress  - [double]$debut.data.rhp.egress
    $recu   = [double]$now.data.rhp.ingress - [double]$debut.data.rhp.ingress
    Set-Icone $icoEnvoye (Format-Court $envoye) $bleu ($T.Envoye + ' : ' + (Format-Long $envoye) + " ($heure)")
    Set-Icone $icoRecu   (Format-Court $recu)   $rose ($T.Recu + ' : ' + (Format-Long $recu) + " ($heure)")
  } catch {
    $msg = $T.Erreur + " ($heure) : " + $_.Exception.Message
    Set-Icone $icoEnvoye '!' $gris $msg
    Set-Icone $icoRecu   '!' $gris $msg
  }
}

$minuteur = New-Object System.Windows.Forms.Timer
$minuteur.Interval = $intervalle
$minuteur.Add_Tick({ Mettre-AJour })
Mettre-AJour
$minuteur.Start()
[System.Windows.Forms.Application]::Run()
