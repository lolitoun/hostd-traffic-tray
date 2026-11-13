# hostd-traffic-tray

**Today's [hostd](https://github.com/SiaFoundation/hostd) traffic, right next to your Windows clock.**

The hostd web UI only shows bandwidth for finished days. This small script shows what your Sia host has
**sent** and **received since midnight**, as two tray icons that refresh every minute.

![The two icons in the Windows taskbar, next to the clock](docs/taskbar.png)

*In the taskbar: 92 GB received (pink) and 42 GB sent (blue) since midnight.*

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

## Known limitations

These are general trade-offs of any tool of this kind, not hidden behavior. Thanks to
**[Mike76](https://github.com/mike76-dev)** (author of [sombrero](https://github.com/mike76-dev/sombrero),
an SMB server for Sia), who reviewed the code and pointed them out.

- **The password stays in memory while the script runs.** To query hostd every minute, the script keeps
  the Basic Auth header in RAM until you quit. It is never written to disk, but a process with
  administrator or debugging rights on the same PC could read it. Such a process could also read hostd's
  own memory (including your wallet seed), so the script adds practically no extra risk.
- **Local traffic is plain HTTP.** hostd's UI is served over `http://`, so the password is sent
  unencrypted, but only over the loopback interface (`127.0.0.1`): it never leaves your PC. Your browser
  does exactly the same when you open the hostd UI.
- **`-ExecutionPolicy Bypass`.** The `.bat` uses it so Windows lets the script run. It applies only to
  that one PowerShell process and does not change your system settings (Microsoft notes the execution
  policy is not a security boundary). The script never updates itself: read any new version before
  replacing the one you have.
- **The script is not code-signed.** A self-signed certificate would only be trusted on the author's PC,
  and a public one costs money every year. The code is short and readable instead: please review it.

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

**Le trafic [hostd](https://github.com/SiaFoundation/hostd) du jour, juste à côté de l'horloge Windows.**

L'interface web de hostd n'affiche la bande passante que pour les journées terminées. Ce petit script
affiche ce que ton hôte Sia a **envoyé** et **reçu depuis minuit**, sous forme de deux icônes près de
l'horloge, mises à jour chaque minute.

![Les deux icônes dans la barre des tâches Windows, près de l'horloge](docs/taskbar.png)

*Dans la barre des tâches : 92 GB reçus (rose) et 42 GB envoyés (bleu) depuis minuit.*

![Aperçu des icônes](docs/icons-preview.png)

| Icône | Signification |
|---|---|
| 🟦 bleue | **Envoyé aujourd'hui** (egress : ce que les clients téléchargent) |
| 🟪 rose | **Reçu aujourd'hui** (ingress : ce que les clients déposent) |

Mêmes unités que l'interface hostd (GB / TB décimaux). L'icône affiche `3.2`, `39`, `386` (GB), puis `1.3T` (TB).
Passer la souris sur une icône donne la valeur exacte (ex. `Envoyé aujourd'hui : 386.42 GB (14:35)`).
Clic droit : **Actualiser** / **Quitter**.
(L'interface est en anglais par défaut : `Sent today`, `Refresh`, `Quit`. Voir *Options* pour le français.)
Si hostd ne répond pas, les deux icônes deviennent grises avec un `!`.

### Est-ce sûr ?

C'est un seul petit fichier PowerShell, lisible en quelques minutes : c'est justement la raison de ce dépôt.

- **Lecture seule.** Il appelle uniquement `GET /api/metrics` sur l'API **locale** de hostd
  (`http://127.0.0.1:9980`). Il ne modifie aucun réglage, ne touche jamais au portefeuille et n'envoie
  rien ailleurs.
- **Aucun accès réseau en dehors de `127.0.0.1`.** Pas de télémétrie, pas de mise à jour automatique,
  pas de téléchargement.
- **Le mot de passe de l'interface hostd** est tapé dans une petite fenêtre masquée au démarrage, gardé
  en mémoire uniquement et **jamais écrit sur le disque**.
- **Aucune installation, aucun droit administrateur**, rien n'est ajouté au démarrage de Windows.
  « Quitter » depuis le menu de l'icône, et il n'en reste rien.
- **Léger pour l'hôte :** 2 petites requêtes à l'API par minute (l'interface hostd en fait bien plus
  quand elle est ouverte).

### Limites connues

Ce sont des compromis généraux, communs à tous les outils de ce type, et pas un comportement caché.
Merci à **[Mike76](https://github.com/mike76-dev)** (auteur de
[sombrero](https://github.com/mike76-dev/sombrero), un serveur SMB pour Sia), qui a relu le code et les a
signalés.

- **Le mot de passe reste en mémoire pendant que le script tourne.** Pour interroger hostd chaque minute,
  le script garde l'en-tête d'authentification en RAM jusqu'à ce qu'on le quitte. Il n'est jamais écrit
  sur le disque, mais un programme ayant les droits administrateur ou de débogage sur le même PC pourrait
  le lire. Un tel programme pourrait aussi lire la mémoire de hostd lui-même (y compris la graine du
  portefeuille) : le script n'ajoute donc pratiquement aucun risque.
- **Le trafic local est en HTTP non chiffré.** L'interface hostd est servie en `http://`, donc le mot de
  passe circule en clair, mais uniquement sur la boucle locale (`127.0.0.1`) : il ne sort jamais du PC.
  Le navigateur fait exactement la même chose quand on ouvre l'interface hostd.
- **`-ExecutionPolicy Bypass`.** Le `.bat` l'utilise pour que Windows accepte de lancer le script. Cette
  option ne s'applique qu'à ce lancement de PowerShell et ne modifie pas les réglages du système
  (Microsoft précise que la stratégie d'exécution n'est pas une barrière de sécurité). Le script ne se
  met jamais à jour tout seul : relire toute nouvelle version avant de remplacer la sienne.
- **Le script n'est pas signé numériquement.** Un certificat « maison » ne serait reconnu que sur le PC
  de l'auteur, et un certificat public coûte de l'argent chaque année. À la place, le code est court et
  lisible : n'hésitez pas à le relire.

### Prérequis

- Windows 10 ou 11 (Windows PowerShell 5.1, déjà intégré)
- hostd qui tourne sur la **même machine**, interface sur `http://127.0.0.1:9980` (valeur par défaut)

### Utilisation

1. Télécharger `hostd-traffic-tray.ps1` et `hostd-traffic-tray.bat` et les mettre **dans le même dossier**.
2. Double-cliquer sur **`hostd-traffic-tray.bat`**.
3. Taper le mot de passe de l'interface hostd. Les deux icônes apparaissent près de l'horloge.

Après un redémarrage : lancer d'abord hostd, puis de nouveau le `.bat`.

**Icônes masquées ?** Paramètres → Personnalisation → Barre des tâches → *Autres icônes de barre d'état
système* → activer **Windows PowerShell**.

**Windows bloque le fichier ?** Clic droit sur le `.ps1` téléchargé → Propriétés → cocher **Débloquer** → OK.

### Options

En haut du script :

- `$Langue = 'en'` : langue de l'interface, `'en'` (anglais, par défaut), `'fr'` (français) ou `'auto'`
  (suit la langue de Windows)
- `$intervalle = 60000` : intervalle de mise à jour, en millisecondes
- `$api = 'http://127.0.0.1:9980/api'` : à changer si l'interface hostd utilise un autre port

### Comment ça marche

Les statistiques de hostd sont des compteurs cumulés. Le script demande à hostd ses statistiques
**maintenant** et **à minuit (heure locale)** (`GET /api/metrics?timestamp=...`), puis affiche la
différence de `data.rhp.egress` et `data.rhp.ingress`.

Sans lien avec la Sia Foundation. Licence MIT.
