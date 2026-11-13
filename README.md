# hostd-traffic-tray

**Today's [hostd](https://github.com/SiaFoundation/hostd) traffic, right next to your Windows clock.**

The hostd web UI only shows bandwidth for finished days. This small script shows what your Sia host has
**sent** and **received since midnight**, as two tray icons that refresh every minute.

![Tray icons preview](docs/icons-preview.png)

| Icon | Meaning |
|---|---|
| 🟦 blue | **Sent today** (egress: data downloaded by renters) |
| 🟪 pink | **Received today** (ingress: data uploaded by renters) |

Same units as the hostd UI (decimal GB / TB). The icon shows `3.2`, `39`, `386` (GB), then `1.3T` (TB).
Hover an icon for the exact value (e.g. `Sent today : 386.42 GB (14:35)`). Right-click: **Refresh** / **Quit**.
If hostd can't be reached, both icons turn grey with `!`.

## Is it safe?

It's one short PowerShell file you can read in a few minutes, and that's the point of this repository.

- **Read-only.** It only calls `GET /api/metrics` on your **local** hostd API (`http://127.0.0.1:9980`).
  It never changes a setting, never touches your wallet, never sends anything elsewhere.
- **No network access beyond `127.0.0.1`.** No telemetry, no updates, no downloads.
- **Your hostd UI password** is typed in a small masked window at startup, kept in memory only,
  and **never written to disk**.
- **No install, no admin rights**, nothing added to Windows startup. Quit from the icon menu and it's gone.
- **Light on the host:** 2 small API calls per minute (the hostd UI itself does much more when open).

## Requirements

- Windows 10 or 11 (Windows PowerShell 5.1, built in)
- hostd running on the **same machine**, UI on `http://127.0.0.1:9980` (the default)

## Usage

1. Download `hostd-traffic-tray.ps1` and `hostd-traffic-tray.bat` and put them **in the same folder**.
2. Double-click **`hostd-traffic-tray.bat`**.
3. Enter your hostd UI password. The two icons appear next to the clock.

After a reboot, start hostd first, then the `.bat` again.

**Icons hidden?** Settings → Personalization → Taskbar → *Other system tray icons* → turn on **Windows PowerShell**.

**Windows blocks the file?** Right-click the downloaded `.ps1` → Properties → tick **Unblock** → OK.

## Options

At the top of the script:

- `$Langue = 'en'`: interface language, `'en'` (default), `'fr'` (French) or `'auto'` (follow Windows)
- `$intervalle = 60000`: refresh interval in milliseconds
- `$api = 'http://127.0.0.1:9980/api'`: change it if your hostd UI uses another port

## How it works

hostd's metrics are cumulative counters. The script asks hostd for its metrics **now** and **at local
midnight** (`GET /api/metrics?timestamp=...`), and shows the difference of `data.rhp.egress` and
`data.rhp.ingress`.

Not affiliated with the Sia Foundation. MIT licensed.

---

## 🇫🇷 En français

**Le trafic hostd du jour, juste à côté de l'horloge Windows.**

L'interface web de hostd n'affiche la bande passante que pour les journées terminées. Ce petit script
affiche ce que ton hôte Sia a **envoyé** et **reçu depuis minuit**, sous forme de deux icônes près de
l'horloge, mises à jour chaque minute.

- 🟦 **bleue** : envoyé aujourd'hui (egress, ce que les clients téléchargent)
- 🟪 **rose** : reçu aujourd'hui (ingress, ce que les clients déposent)

Mêmes unités que l'interface hostd (GB / TB). Survol = valeur exacte. Clic droit : *Refresh* / *Quit*.

**Sécurité :** lecture seule, uniquement l'API locale de hostd (`127.0.0.1`), aucun envoi ailleurs,
mot de passe gardé en mémoire et jamais enregistré, aucune installation ni droit administrateur.

**Utilisation :** mettre `hostd-traffic-tray.ps1` et `hostd-traffic-tray.bat` dans le même dossier,
double-cliquer sur le `.bat`, taper le mot de passe de l'interface hostd.
Pour l'interface en français : mettre `$Langue = 'fr'` en haut du script.
