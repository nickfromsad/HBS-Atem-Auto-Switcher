# HBS // ATEM Auto Switcher

[English](README.md) · **Nederlands**

<img src="docs/icon.png" width="128" alt="HBS ATEM Auto Switcher icoon" align="right">

Automatische camerawissel voor Blackmagic ATEM-mengtafels. Luistert naar de audioniveaus van een Dante Virtual
Soundcard en zet op de ATEM de camera op program van wie het hardst praat: handsfree, in realtime.

Onderdeel van de HBS-tools van [Hof Broadcast Services](https://hofbroadcast.nl), naast
[HBS // EasyIP MAC](https://github.com/nickfromsad/HBS-EasyIP-MAC).

---

## Wat het doet

In een multicamera-productie heeft elke presentator of camerapositie een eigen microfoon. Deze tool luistert naar de
binnenkomende audio van een Dante Virtual Soundcard, meet het niveau van elk kanaal en vertelt de ATEM welke camera
op program moet, automatisch, op basis van wie er praat.

Elk audiokanaal heeft een eigen noise gate. Die filtert achtergrondgeluid weg, zodat de wissel alleen reageert op
echte spraak en niet op zaalgeluid of gestommel. Gaat een microfoon open (het signaal komt boven de drempel en blijft
daar de attack-tijd lang), dan schakelt de software de ATEM naar de bijbehorende camera. Stopt de spreker, dan wacht
de gate de release-tijd voordat hij sluit, zodat er bij een natuurlijke pauze niet meteen wordt weggesneden.

---

## Functies

- **Gate per kanaal**: eigen drempel, attack en release per microfoon
- **dBFS-niveaumeter**: live audioweergave van –60 dBFS tot 0 dBFS, met een markering voor de drempel
- **Status van de gate**: `CLSD` / `ATCK` / `OPEN` / `REL` per kanaal
- **Tally-indicator**: een balkje markeert het kanaal waarvan de camera op program staat
- **Prioriteit per kanaal**: Low / Normal / High bepaalt wie wint als er meerdere microfoons open staan
- **Namen van ATEM-ingangen**: cameranamen worden na het verbinden uit de ATEM gehaald
- **Program / Preview-bus**: PGM- en PVW-knoppen die de ATEM volgen, ook bij wissels vanaf het panel
- **Meerdere M/E's**: kies welke M/E-bus de automatische wissel bedient
- **No-audio camera**: camera waar naartoe wordt geschakeld als alle microfoons stil zijn
- **Silence loop**: blijf bij stilte wisselen tussen de no-audio camera en extra loop cameras, elk een willekeurige
  tijd lang
- **PVW automation camera**: zet je één gekozen camera op preview, dan gaat de automatisering aan; elke andere zet
  hem uit
- **Switch holdoff** en **silence delay**: geen snelle heen-en-weer-wissels, en bij een pauze blijft de spreker in beeld
- **Presets**: Fast / Medium / Slow, met aanpasbare attack, release en holdoff
- **Handmatige testwissel**: stuur zelf een wissel om de verbinding met de ATEM te controleren
- **Stream Deck-koppeling**: bedien de automatisering vanuit Bitfocus Companion via HTTP
- **Log**: elke verbinding, wissel en fout, ook opgeslagen in een bestand
- **Instellingen worden onthouden**, en de verbinding met de ATEM wordt **automatisch hersteld**
- **Updatemelding**: in de kopbalk staat het als er een nieuwere versie op GitHub staat

---

## Downloaden

Download de [nieuwste release](https://github.com/nickfromsad/HBS-Atem-Auto-Switcher/releases/latest). Python installeren is niet nodig.

**Windows**: download `HBS-ATEM-Auto-Switcher.exe` en dubbelklik erop. De exe is niet digitaal ondertekend, dus
Windows SmartScreen kan *Windows heeft uw pc beveiligd* laten zien. Klik op **Meer informatie → Toch uitvoeren**.

**macOS** (Apple Silicon, macOS 12 of nieuwer): download `HBS-ATEM-Auto-Switcher-x.y.dmg`, open hem en sleep de app
naar de map Programma's. De app is niet door Apple gecontroleerd, dus macOS blokkeert hem de eerste keer: ga naar
**Systeeminstellingen → Privacy en beveiliging**, scrol omlaag en klik op **Open toch**. Sta daarna toe:

- **Microfoon**: nodig om de audioniveaus te lezen, ook van Dante Virtual Soundcard. Zonder die toestemming krijgt
  de app alleen stilte en wordt er niets gewisseld. Later aanpassen kan via *Systeeminstellingen → Privacy en
  beveiliging → Microfoon*.
- **Lokaal netwerk**: nodig om de ATEM te bereiken (en voor Companion).

Verder heb je nodig:

- **Dante Virtual Soundcard**, of een andere audio-ingang met meerdere kanalen
- een **Blackmagic ATEM** op hetzelfde netwerk als de computer

Op Linux start je hem vanuit de broncode (zie [Ontwikkelen](#ontwikkelen)).

---

## Gebruik

1. Sluit de ATEM aan op hetzelfde netwerk als je computer.
2. Open Dante Virtual Soundcard en zorg dat je audiobronnen naar DVS-kanalen gerouteerd zijn.
3. Start **HBS ATEM Auto Switcher**.
4. Vul het IP-adres van de ATEM in en klik op **Connect**.
5. Kies per kanaalrij het DVS-apparaat, het audiokanaal (0 = links, 1 = rechts), stel de drempel van de gate in en
   kies naar welke camera-ingang van de ATEM moet worden geschakeld.
6. Klik op **▶ Start** om het luisteren te starten.
7. Druk op **AUTOMATION ON** om automatisch te laten wisselen.

De instellingen worden bij afsluiten bewaard en bij de volgende start teruggezet. Ze staan in
`Bureaublad/atem-switcher/`, samen met `atem_log.txt` (het log van de vorige sessie blijft bewaard als
`atem_log.prev.txt`, handig na een crash). Mag de app niet op het bureaublad schrijven (macOS vraagt dat), dan
gebruikt hij `~/Library/Application Support/HBS ATEM Auto Switcher` (`~/.atem-switcher` op Windows/Linux).

### Hoe de gate werkt

```
Signaalniveau
    │
    │       ┌─── OPEN (camera op program) ───┐
    │      /                                  \
────┼─────/────── drempel ────────────────────\────
    │    /  ↑ attack-tijd                      \  ↑ release-tijd
    │   /                                       \ /
    │  ATCK                                   REL → CLSD
    │
```

- **CLSD**: signaal onder de drempel, gate dicht, camera niet gekozen
- **ATCK**: signaal boven de drempel, wacht de attack-tijd af om zeker te zijn dat het echte spraak is
- **OPEN**: gate open, deze camera kan op program (de luidste open gate wint, gewogen naar prioriteit)
- **REL**: signaal weggevallen, de gate blijft de release-tijd nog open voordat hij sluit

### Instellingen

| Instelling | Uitleg |
|---|---|
| M/E | Welke M/E-bus de wissel bedient (M/E 1 = de hoofduitgang) |
| No-audio camera | Camera waar naartoe wordt geschakeld als alle microfoons stil zijn |
| Loop every … s | Wissel bij stilte tussen de no-audio camera en de extra loop cameras, met een willekeurige tijd tussen de twee waarden |
| Extra loop cameras | Extra camera's voor de silence loop, met of zonder microfoon |
| Switch holdoff | Minimaal aantal seconden tussen twee wissels |
| Silence delay | Aantal seconden stilte voordat naar de no-audio camera wordt geschakeld |
| PVW automation camera | Zet deze camera op preview om de automatisering aan te zetten; een andere camera op preview zet hem uit |
| Gate threshold | Niveau in dBFS waar het signaal boven moet komen om de gate te openen |
| Attack | Aantal seconden dat het signaal boven de drempel moet blijven voordat de gate opengaat |
| Release | Aantal seconden dat de gate open blijft nadat het signaal onder de drempel zakt |
| Prio | Weging Low (0,5×), Normal of High (2×) als er meerdere gates open staan |

### Stream Deck-koppeling via Bitfocus Companion

De wissel heeft een ingebouwde HTTP-server waar Bitfocus Companion direct mee kan praten, zodat je de automatisering
met een Stream Deck-knop aan en uit zet.

Stel in de tab **Settings** de poort in (standaard `8765`) en klik op **Enable**. De server start meteen en de
instelling wordt bij de volgende start onthouden.

Maak in Companion een nieuwe verbinding met de module **Generic HTTP**. Zet de base URL op `http://127.0.0.1:8765`
(of het IP-adres van de pc als Companion op een andere computer draait). Voeg dan op een knop de actie **Send HTTP
POST request** toe met een van deze URI's:

| URI | Wat het doet |
|---|---|
| `/automation/toggle` | Automatisering aan of uit zetten |
| `/automation/on` | Automatisering aanzetten |
| `/automation/off` | Automatisering uitzetten |

Wil je dat de knop ook laat zien of de automatisering aan staat, voeg dan op dezelfde knop een **Background Image**-
feedback toe. Zet de URL op `http://127.0.0.1:8765/status/image` met een verversing van ongeveer 1000 ms. De knop
wordt groen als de automatisering aan staat en rood als hij uit staat.

Het endpoint `/status` geeft `{"automation_active": true/false}` terug, als je de status vanuit een ander systeem
wilt uitlezen.

---

## Ontwikkelen

Nodig: Python 3.11+.

```bash
pip install PyQt6 sounddevice numpy certifi
python atem_switcher.pyw
```

| Bestand | |
|---|---|
| `atem_switcher.pyw` | de hele app: ATEM-verbinding (UDP), audio-engine, Companion-server en de PyQt6-interface |
| `.github/workflows/build-release.yml` | bouwt de Windows-exe en de Mac-app met PyInstaller en zet ze samen als release online |
| `packaging/macos/` | Mac-build: `build-mac.sh` (app + dmg), het app-icoon en de opmaak van het dmg-venster |
| `docs/icon.png` | het icoon in deze README (het app-icoon zelf zit in het script) |

### Een nieuwe versie uitbrengen

1. Verhoog `APP_VERSION` in `atem_switcher.pyw`.
2. Push, en open dan op GitHub **Actions → Build release → Run workflow**.

De workflow bouwt `HBS-ATEM-Auto-Switcher.exe` en `HBS-ATEM-Auto-Switcher-<versie>.dmg`, allebei met het icoon uit
het script, en zet ze online als release `v<APP_VERSION>`.

De Mac-app lokaal bouwen (nodig: [uv](https://docs.astral.sh/uv/) en de Xcode Command Line Tools):

```bash
uv run --python 3.12 --with pyinstaller --with PyQt6 --with sounddevice --with numpy --with certifi packaging/macos/build-mac.sh
```

---

## Licentie

MIT. Niet verbonden aan Blackmagic Design of Audinate. "ATEM" is een handelsmerk van Blackmagic Design,
"Dante" een handelsmerk van Audinate.
