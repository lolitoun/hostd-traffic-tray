# =============================================================================
#  hostd-traffic-tray v1.1.0 -hostd traffic as two tray icons next to the clock
#  https://github.com/lolitoun/hostd-traffic-tray  (MIT)
# =============================================================================
#  [EN]
#  Shows your hostd traffic as TWO icons in the Windows notification area,
#  next to the clock:
#    - BLUE icon = sent     (egress: data downloaded by renters)
#    - PINK icon = received (ingress: data uploaded by renters)
#  Period: today (default: from 00:00, back to 0 at midnight), last 24 hours or
#  last hour. Change it from the right-click menu, or set $Periode below to
#  choose the one used at startup.
#  Same units as the hostd web UI (decimal GB / TB). Icon text: 3.2 / 38 / 386
#  (GB), then 1.3T (TB) above 1000 GB. Hover an icon for the exact value.
#  Right-click: Refresh / Period / Quit. Refreshes every minute (2 light API calls).
#  Read-only: it only reads hostd's API (/api/metrics), changes nothing, and
#  never writes, deletes or locks any file.
#  The hostd UI password is asked at startup and is never saved to disk.
#  If hostd cannot be reached, both icons turn grey with "!".
#
#  Requirements: Windows 10/11, Windows PowerShell 5.1 (built in), hostd running
#  with its UI on http://127.0.0.1:9980 (default; see $api below).
#
#  Start: double-click hostd-traffic-tray.bat (same folder). It opens PowerShell
#  minimized, then the script hides its own console window (-HideConsole).
#  If the icons are hidden: Settings > Personalization > Taskbar >
#  Other system tray icons > turn on "Windows PowerShell".
#
#  [FR]
#  Affiche le trafic hostd en DEUX icones dans la zone de notification, pres
#  de l'horloge :
#    - icone BLEUE = envoye (egress : ce que les clients telechargent)
#    - icone ROSE  = recu   (ingress : ce que les clients deposent)
#  Periode : aujourd'hui (par defaut : depuis 00:00, remise a 0 a minuit),
#  24 dernieres heures ou derniere heure. A changer par le clic droit, ou avec
#  $Periode plus bas pour le demarrage.
#  Memes unites que l'interface hostd (GB / TB decimaux). Texte de l'icone :
#  3.2 / 38 / 386 (GB), puis 1.3T (TB) au-dela de 1000 GB. Passer la souris
#  sur une icone = valeur exacte. Clic droit : Actualiser / Periode / Quitter.
#  Mise a jour chaque minute (2 petites requetes a l'API).
#  Lecture seule : lit seulement l'API de hostd (/api/metrics), ne modifie rien
#  et n'ecrit, ne supprime ni ne verrouille aucun fichier.
#  Le mot de passe de l'interface hostd est demande au lancement et n'est
#  jamais enregistre. Si hostd ne repond pas, les icones deviennent grises "!".
#
#  Lancement : double-cliquer sur hostd-traffic-tray.bat (meme dossier). Il ouvre
#  PowerShell reduit, puis le script cache sa propre fenetre (-HideConsole).
#  Si les icones sont masquees : Parametres > Personnalisation > Barre des
#  taches > Autres icones de barre d'etat systeme > activer "Windows PowerShell".
#
#  File intentionally without accents (Windows PowerShell 5.1 misreads UTF-8 without BOM).
# =============================================================================

param(
  [switch]$HideConsole,   # hide this script's console window (used by the .bat)
  [switch]$TestRendu      # save sample icons as PNG (check only, no hostd needed)
)

# ----------------------------- Settings / reglages ---------------------------
# hostd API. Keep 127.0.0.1 if hostd runs on this PC. Another host (e.g. a Docker
# container 'http://hostd:9980/api') works too, but the password then travels
# over plain HTTP on your network. / API hostd. Garder 127.0.0.1 si hostd tourne
# sur ce PC. Un autre hote marche aussi, mais le mot de passe circule alors en
# HTTP non chiffre sur le reseau local.
$api        = 'http://127.0.0.1:9980/api'
$intervalle = 60000   # ms = 1 minute

# Period at startup / periode au demarrage : 'today' (00:00 - 23:59, default /
# par defaut), '24h' (last 24 hours / 24 dernieres heures), '1h' (last hour / derniere heure)
$Periode = 'today'

# Interface language / langue : 'en' (default), 'fr', 'auto' (follow Windows / suivre Windows)
$Langue = 'en'
# -----------------------------------------------------------------------------

$Version = '1.1.0'
$inv = [Globalization.CultureInfo]::InvariantCulture   # point decimal, comme hostd

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -Namespace TraficHostd -Name Natif -MemberDefinition @'
[DllImport("user32.dll")] public static extern bool DestroyIcon(IntPtr h);
[DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int cmd);
[DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow();
'@

# Hide our own console only when asked (never hides a terminal you typed in).
# Cacher notre console seulement si demande (jamais un terminal ouvert a la main).
if ($HideConsole) {
  $console = [TraficHostd.Natif]::GetConsoleWindow()
  if ($console -ne [IntPtr]::Zero) { [TraficHostd.Natif]::ShowWindow($console, 0) | Out-Null }
}

$fr = ($Langue -eq 'fr') -or ($Langue -eq 'auto' -and (Get-UICulture).TwoLetterISOLanguageName -eq 'fr')
$e = [char]0xE9; $eg = [char]0xE8   # e aigu / e grave, construits ici pour garder le fichier en ASCII
if ($fr) {
  $T = @{
    Titre       = 'Trafic hostd'
    MotPasse    = "Mot de passe de l'interface hostd :"
    Envoye      = "Envoy$e"
    Recu        = 'Re' + [char]0xE7 + 'u'
    today       = "aujourd'hui"
    '24h'       = "(24 derni$($eg)res h)"
    '1h'        = "(derni$($eg)re heure)"
    MenuToday   = "Aujourd'hui (00:00 - 23:59)"
    Menu24h     = "24 derni$($eg)res heures"
    Menu1h      = "Derni$($eg)re heure"
    MenuPeriode = "P$($e)riode"
    Erreur      = 'hostd injoignable'
    Actualiser  = 'Actualiser'
    Quitter     = 'Quitter'
  }
} else {
  $T = @{
    Titre       = 'hostd traffic'
    MotPasse    = 'hostd UI password:'
    Envoye      = 'Sent'
    Recu        = 'Received'
    today       = 'today'
    '24h'       = '(last 24 h)'
    '1h'        = '(last hour)'
    MenuToday   = 'Today (00:00 - 23:59)'
    Menu24h     = 'Last 24 hours'
    Menu1h      = 'Last hour'
    MenuPeriode = 'Period'
    Erreur      = 'hostd unreachable'
    Actualiser  = 'Refresh'
    Quitter     = 'Quit'
  }
}
if (@('today', '24h', '1h') -notcontains $Periode) { $Periode = 'today' }

$bleu = [System.Drawing.Color]::FromArgb(37, 99, 235)    # courbe egress de hostd
$rose = [System.Drawing.Color]::FromArgb(219, 39, 119)   # courbe ingress de hostd
$gris = [System.Drawing.Color]::FromArgb(110, 110, 110)
# Taille maximale du texte dans l'icone de 32 x 32 pixels (largeur, hauteur)
$LargeurTexte = 31
$HauteurTexte = 22

function New-IconeTexte([string]$texte, [System.Drawing.Color]$fond) {
  $bmp = New-Object System.Drawing.Bitmap 32, 32
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $g.Clear($fond)
  # Contour exact des caracteres, agrandi pour remplir l'icone (texte le plus gros possible)
  $chemin = New-Object System.Drawing.Drawing2D.GraphicsPath
  $famille = New-Object System.Drawing.FontFamily 'Segoe UI'
  $chemin.AddString($texte, $famille, [int][System.Drawing.FontStyle]::Bold, 100, (New-Object System.Drawing.PointF 0, 0), [System.Drawing.StringFormat]::GenericTypographic)
  $cadre = $chemin.GetBounds()
  $echelle = [Math]::Min($LargeurTexte / $cadre.Width, $HauteurTexte / $cadre.Height)
  $m = New-Object System.Drawing.Drawing2D.Matrix
  $m.Translate(16, 16)
  $m.Scale($echelle, $echelle)
  $m.Translate(-($cadre.X + $cadre.Width / 2), -($cadre.Y + $cadre.Height / 2))
  $chemin.Transform($m)
  $g.FillPath([System.Drawing.Brushes]::White, $chemin)
  $g.Dispose(); $chemin.Dispose(); $famille.Dispose(); $m.Dispose()
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

# Debut de la periode choisie, au format attendu par /api/metrics?timestamp=
function Get-DebutPeriode([string]$periode, [datetime]$maintenant) {
  switch ($periode) {
    '24h'   { $debut = $maintenant.AddHours(-24) }
    '1h'    { $debut = $maintenant.AddHours(-1) }
    default { $debut = $maintenant.Date }
  }
  return $debut.ToString('yyyy-MM-ddTHH:mm:sszzz', $inv)
}

# Info-bulle (ex. "Sent today : 386.42 GB (14:35)"), coupee a 63 caracteres (limite Windows)
function Get-InfoBulle([string]$sens, [double]$octets, [string]$heure) {
  $texte = $sens + ' ' + $T[$script:Periode] + ' : ' + (Format-Long $octets) + " ($heure)"
  if ($texte.Length -gt 63) { $texte = $texte.Substring(0, 63) }
  return $texte
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
  $maintenant = Get-Date
  foreach ($p in 'today', '24h', '1h') {
    $script:Periode = $p
    Write-Host ('{0,-5} from {1} | {2} | {3}' -f $p, (Get-DebutPeriode $p $maintenant), (Get-InfoBulle $T.Envoye 386.42e9 '14:35'), (Get-InfoBulle $T.Recu 1.38642e12 '14:35'))
  }
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
$titreMenu = $menu.Items.Add("hostd-traffic-tray v$Version")
$titreMenu.Enabled = $false
$menu.Items.Add('-') | Out-Null
$menu.Items.Add($T.Actualiser).Add_Click({ Mettre-AJour }) | Out-Null

# Sous-menu Periode : un seul choix coche a la fois
$sousMenu = New-Object System.Windows.Forms.ToolStripMenuItem $T.MenuPeriode
$choix = [ordered]@{ 'today' = $T.MenuToday; '24h' = $T.Menu24h; '1h' = $T.Menu1h }
foreach ($cle in $choix.Keys) {
  $item = New-Object System.Windows.Forms.ToolStripMenuItem $choix[$cle]
  $item.Tag = $cle
  $item.Checked = ($cle -eq $Periode)
  $item.Add_Click({
    param($source, $evt)
    $script:Periode = $source.Tag
    foreach ($autre in $sousMenu.DropDownItems) { $autre.Checked = ($autre.Tag -eq $script:Periode) }
    Mettre-AJour
  })
  $sousMenu.DropDownItems.Add($item) | Out-Null
}
$menu.Items.Add($sousMenu) | Out-Null

$menu.Items.Add('-') | Out-Null
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
  $maintenant = Get-Date
  $heure = $maintenant.ToString('HH:mm')
  try {
    $debut = [uri]::EscapeDataString((Get-DebutPeriode $script:Periode $maintenant))
    $now   = Invoke-RestMethod "$api/metrics" -Headers $headers -TimeoutSec 30
    $avant = Invoke-RestMethod "$api/metrics?timestamp=$debut" -Headers $headers -TimeoutSec 30
    $envoye = [double]$now.data.rhp.egress  - [double]$avant.data.rhp.egress
    $recu   = [double]$now.data.rhp.ingress - [double]$avant.data.rhp.ingress
    Set-Icone $icoEnvoye (Format-Court $envoye) $bleu (Get-InfoBulle $T.Envoye $envoye $heure)
    Set-Icone $icoRecu   (Format-Court $recu)   $rose (Get-InfoBulle $T.Recu $recu $heure)
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
