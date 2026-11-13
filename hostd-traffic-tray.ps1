# =============================================================================
#  hostd-traffic-tray v1.1.0
#  hostd traffic (sent / received) as two tray icons next to the Windows clock.
#  Read-only: only calls GET /api/metrics on the hostd API. Writes no files,
#  never saves the password.
#  Docs: README.md (English) / README.fr.md (French)
#  https://github.com/lolitoun/hostd-traffic-tray - MIT License
#
#  ASCII only: Windows PowerShell 5.1 misreads UTF-8 files without BOM, so the
#  accented letters of the French UI are built from [char] codes.
# =============================================================================

param(
  [switch]$HideConsole,   # always hide this script's console window (used by the .bat)
  [switch]$TestRender     # save sample icons as PNG and exit (no hostd needed)
)

# --------------------------------- Settings ----------------------------------
# hostd API. Keep 127.0.0.1 if hostd runs on this PC. Another host (e.g. a Docker
# container: 'http://hostd:9980/api') works too, but the password then travels
# over plain HTTP on your local network.
$Api      = 'http://127.0.0.1:9980/api'
$Interval = 60000     # refresh interval in milliseconds (1 minute)
$Period   = 'today'   # at startup: 'today' (00:00 - 23:59), '24h' or '1h'
$Language = 'en'      # 'en', 'fr' or 'auto' (follow Windows)
# -----------------------------------------------------------------------------

$Version = '1.1.0'
$inv = [Globalization.CultureInfo]::InvariantCulture   # decimal point, like hostd

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -Namespace HostdTraffic -Name Native -MemberDefinition @'
[DllImport("user32.dll")] public static extern bool DestroyIcon(IntPtr h);
[DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int cmd);
[DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow();
[DllImport("kernel32.dll")] public static extern uint GetConsoleProcessList(uint[] list, uint count);
'@

# Hide the console window when it was opened just for this script (.bat, or
# right-click > Run with PowerShell): PowerShell was started with arguments to run
# it (no -NoExit), and no other process uses that window. A PowerShell window or
# terminal you opened yourself stays visible.
$console = [HostdTraffic.Native]::GetConsoleWindow()
$consoleUsers = [HostdTraffic.Native]::GetConsoleProcessList((New-Object UInt32[] 8), 8)
$psArgs = @([Environment]::GetCommandLineArgs() | Select-Object -Skip 1)
$startedForScript = ($psArgs.Count -gt 0) -and -not ($psArgs -match '^[-/]noe')
if ($console -ne [IntPtr]::Zero -and ($HideConsole -or ($consoleUsers -eq 1 -and $startedForScript))) {
  [HostdTraffic.Native]::ShowWindow($console, 0) | Out-Null
}

# --- UI strings ---
$french = ($Language -eq 'fr') -or ($Language -eq 'auto' -and (Get-UICulture).TwoLetterISOLanguageName -eq 'fr')
$eAcute = [char]0xE9; $eGrave = [char]0xE8; $cCedil = [char]0xE7
if ($french) {
  $T = @{
    Title     = 'Trafic hostd'
    Password  = "Mot de passe de l'interface hostd :"
    Sent      = "Envoy$eAcute"
    Received  = "Re$($cCedil)u"
    today     = "aujourd'hui"
    '24h'     = "(24 derni$($eGrave)res h)"
    '1h'      = "(derni$($eGrave)re heure)"
    MenuToday = "Aujourd'hui (00:00 - 23:59)"
    Menu24h   = "24 derni$($eGrave)res heures"
    Menu1h    = "Derni$($eGrave)re heure"
    MenuPeriod = "P$($eAcute)riode"
    Error     = 'hostd injoignable'
    Refresh   = 'Actualiser'
    Quit      = 'Quitter'
  }
} else {
  $T = @{
    Title     = 'hostd traffic'
    Password  = 'hostd UI password:'
    Sent      = 'Sent'
    Received  = 'Received'
    today     = 'today'
    '24h'     = '(last 24 h)'
    '1h'      = '(last hour)'
    MenuToday = 'Today (00:00 - 23:59)'
    Menu24h   = 'Last 24 hours'
    Menu1h    = 'Last hour'
    MenuPeriod = 'Period'
    Error     = 'hostd unreachable'
    Refresh   = 'Refresh'
    Quit      = 'Quit'
  }
}
if (@('today', '24h', '1h') -notcontains $Period) { $Period = 'today' }

# --- Icon colors (same as the hostd bandwidth chart) and text size ---
$blue = [System.Drawing.Color]::FromArgb(37, 99, 235)    # egress
$pink = [System.Drawing.Color]::FromArgb(219, 39, 119)   # ingress
$grey = [System.Drawing.Color]::FromArgb(110, 110, 110)  # hostd unreachable
$TextWidth  = 31   # max text size inside the 32 x 32 icon, in pixels
$TextHeight = 22

function New-TextIcon([string]$text, [System.Drawing.Color]$background) {
  $bmp = New-Object System.Drawing.Bitmap 32, 32
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $g.Clear($background)
  # Exact glyph outlines, scaled to fill the icon (largest readable text)
  $path = New-Object System.Drawing.Drawing2D.GraphicsPath
  $family = New-Object System.Drawing.FontFamily 'Segoe UI'
  $path.AddString($text, $family, [int][System.Drawing.FontStyle]::Bold, 100, (New-Object System.Drawing.PointF 0, 0), [System.Drawing.StringFormat]::GenericTypographic)
  $box = $path.GetBounds()
  $scale = [Math]::Min($TextWidth / $box.Width, $TextHeight / $box.Height)
  $m = New-Object System.Drawing.Drawing2D.Matrix
  $m.Translate(16, 16)
  $m.Scale($scale, $scale)
  $m.Translate(-($box.X + $box.Width / 2), -($box.Y + $box.Height / 2))
  $path.Transform($m)
  $g.FillPath([System.Drawing.Brushes]::White, $path)
  $g.Dispose(); $path.Dispose(); $family.Dispose(); $m.Dispose()
  if ($TestRender) { return $bmp }
  $h = $bmp.GetHicon()
  $icon = ([System.Drawing.Icon]::FromHandle($h)).Clone()
  [HostdTraffic.Native]::DestroyIcon($h) | Out-Null
  $bmp.Dispose()
  return $icon
}

# Short text inside the icon: GB, then TB above 1000 GB (3.2 / 39 / 386 / 1.3T)
function Format-Short([double]$bytes) {
  $gb = $bytes / 1e9
  if ($gb -lt 10)   { return $gb.ToString('0.0', $inv) }
  if ($gb -lt 1000) { return $gb.ToString('0', $inv) }
  return ($gb / 1000).ToString('0.0', $inv) + 'T'
}

# Tooltip value, like the hostd UI (e.g. 140.77 GB, 3.32 TB)
function Format-Long([double]$bytes) {
  if ($bytes -ge 1e12) { return ($bytes / 1e12).ToString('0.00', $inv) + ' TB' }
  if ($bytes -ge 1e9)  { return ($bytes / 1e9).ToString('0.00', $inv) + ' GB' }
  return ($bytes / 1e6).ToString('0.00', $inv) + ' MB'
}

# Start of the selected period, in the format expected by /api/metrics?timestamp=
function Get-PeriodStart([string]$period, [datetime]$now) {
  switch ($period) {
    '24h'   { $start = $now.AddHours(-24) }
    '1h'    { $start = $now.AddHours(-1) }
    default { $start = $now.Date }
  }
  return $start.ToString('yyyy-MM-ddTHH:mm:sszzz', $inv)
}

# Tooltip (e.g. "Sent today : 386.42 GB (14:35)"), max 63 characters (Windows limit)
function Get-Tooltip([string]$direction, [double]$bytes, [string]$time) {
  $text = $direction + ' ' + $T[$script:Period] + ' : ' + (Format-Long $bytes) + " ($time)"
  if ($text.Length -gt 63) { $text = $text.Substring(0, 63) }
  return $text
}

# --- Test mode: save sample icons as PNG, without contacting hostd ---
if ($TestRender) {
  $folder = Join-Path $PSScriptRoot 'icon_preview'
  New-Item -ItemType Directory -Force $folder | Out-Null
  $samples = @(@((Format-Short 3.2e9), $blue), @((Format-Short 38.6e9), $blue), @((Format-Short 386e9), $pink), @((Format-Short 1.34e12), $blue), @('!', $grey))
  $i = 0
  foreach ($s in $samples) {
    $b = New-TextIcon $s[0] $s[1]
    $b.Save((Join-Path $folder "icon_$i.png")); $b.Dispose(); $i++
  }
  Write-Host "Saved to: $folder"
  $now = Get-Date
  foreach ($p in 'today', '24h', '1h') {
    $script:Period = $p
    Write-Host ('{0,-5} from {1} | {2} | {3}' -f $p, (Get-PeriodStart $p $now), (Get-Tooltip $T.Sent 386.42e9 '14:35'), (Get-Tooltip $T.Received 1.38642e12 '14:35'))
  }
  return
}

# --- Password prompt (small window, masked characters) ---
$form = New-Object System.Windows.Forms.Form
$form.Text = $T.Title
$form.Size = New-Object System.Drawing.Size 320, 150
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false; $form.MinimizeBox = $false; $form.TopMost = $true
$label = New-Object System.Windows.Forms.Label
$label.Text = $T.Password
$label.Location = New-Object System.Drawing.Point 12, 12
$label.AutoSize = $true
$passwordBox = New-Object System.Windows.Forms.TextBox
$passwordBox.UseSystemPasswordChar = $true
$passwordBox.Location = New-Object System.Drawing.Point 12, 36
$passwordBox.Width = 280
$ok = New-Object System.Windows.Forms.Button
$ok.Text = 'OK'
$ok.Location = New-Object System.Drawing.Point 217, 70
$ok.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $ok
$form.Controls.AddRange(@($label, $passwordBox, $ok))
if ($form.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK -or -not $passwordBox.Text) { return }
$headers = @{ Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(':' + $passwordBox.Text)) }
$form.Dispose()

# --- The two tray icons ---
$iconSent     = New-Object System.Windows.Forms.NotifyIcon
$iconReceived = New-Object System.Windows.Forms.NotifyIcon

$menu = New-Object System.Windows.Forms.ContextMenuStrip
$menuTitle = $menu.Items.Add("hostd-traffic-tray v$Version")
$menuTitle.Enabled = $false
$menu.Items.Add('-') | Out-Null
$menu.Items.Add($T.Refresh).Add_Click({ Update-Traffic }) | Out-Null

# Period submenu: only one choice checked at a time
$periodMenu = New-Object System.Windows.Forms.ToolStripMenuItem $T.MenuPeriod
$choices = [ordered]@{ 'today' = $T.MenuToday; '24h' = $T.Menu24h; '1h' = $T.Menu1h }
foreach ($key in $choices.Keys) {
  $item = New-Object System.Windows.Forms.ToolStripMenuItem $choices[$key]
  $item.Tag = $key
  $item.Checked = ($key -eq $Period)
  $item.Add_Click({
    param($source, $evt)
    $script:Period = $source.Tag
    foreach ($other in $periodMenu.DropDownItems) { $other.Checked = ($other.Tag -eq $script:Period) }
    Update-Traffic
  })
  $periodMenu.DropDownItems.Add($item) | Out-Null
}
$menu.Items.Add($periodMenu) | Out-Null

$menu.Items.Add('-') | Out-Null
$menu.Items.Add($T.Quit).Add_Click({
  $iconSent.Visible = $false; $iconReceived.Visible = $false
  $iconSent.Dispose(); $iconReceived.Dispose()
  [System.Windows.Forms.Application]::Exit()
}) | Out-Null
$iconSent.ContextMenuStrip = $menu
$iconReceived.ContextMenuStrip = $menu

function Set-TrayIcon($notify, [string]$text, $background, [string]$tooltip) {
  $old = $notify.Icon
  $notify.Icon = New-TextIcon $text $background
  if ($tooltip.Length -gt 63) { $tooltip = $tooltip.Substring(0, 63) }
  $notify.Text = $tooltip
  $notify.Visible = $true
  if ($old) { $old.Dispose() }
}

# hostd metrics are cumulative counters: traffic = metrics now - metrics at period start
function Update-Traffic {
  $now = Get-Date
  $time = $now.ToString('HH:mm')
  try {
    $start  = [uri]::EscapeDataString((Get-PeriodStart $script:Period $now))
    $after  = Invoke-RestMethod "$Api/metrics" -Headers $headers -TimeoutSec 30
    $before = Invoke-RestMethod "$Api/metrics?timestamp=$start" -Headers $headers -TimeoutSec 30
    $sent     = [double]$after.data.rhp.egress  - [double]$before.data.rhp.egress
    $received = [double]$after.data.rhp.ingress - [double]$before.data.rhp.ingress
    Set-TrayIcon $iconSent     (Format-Short $sent)     $blue (Get-Tooltip $T.Sent $sent $time)
    Set-TrayIcon $iconReceived (Format-Short $received) $pink (Get-Tooltip $T.Received $received $time)
  } catch {
    $msg = $T.Error + " ($time) : " + $_.Exception.Message
    Set-TrayIcon $iconSent     '!' $grey $msg
    Set-TrayIcon $iconReceived '!' $grey $msg
  }
}

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = $Interval
$timer.Add_Tick({ Update-Traffic })
Update-Traffic
$timer.Start()
[System.Windows.Forms.Application]::Run()
