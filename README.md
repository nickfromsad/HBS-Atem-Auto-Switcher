# HBS // ATEM Auto Switcher

<img src="docs/icon.png" width="128" alt="HBS ATEM Auto Switcher icon" align="right">

Automatic camera switcher for Blackmagic ATEM production switchers. Monitors audio levels from a Dante Virtual
Soundcard and switches the ATEM program input to whichever microphone is loudest: hands-free, in real time.

Part of the HBS toolset by [Hof Broadcast Services](https://hofbroadcast.nl), alongside
[HBS // EasyIP MAC](https://github.com/nickfromsad/HBS-EasyIP-MAC).

---

## What it does

In a multi-camera production each presenter or camera position has its own microphone. This tool listens to the
incoming audio from a Dante Virtual Soundcard, measures the level of each channel, and tells the ATEM switcher which
camera to put on air, automatically, based on who is speaking.

Each audio channel has its own noise gate. The gate filters out background noise so the switcher only reacts to real
speech, not room ambience or handling noise. When a microphone opens (signal exceeds the gate threshold and holds for
the attack time), the software switches the ATEM to the assigned camera. When the speaker stops, the gate waits for
the release time before closing, preventing jumpy cuts during natural pauses.

---

## Features

- **Per-channel gate**: independent threshold, attack and release per microphone
- **dBFS level meter**: real-time audio display from –60 dBFS to 0 dBFS with a gate threshold marker
- **Gate state display**: `CLSD` / `ATCK` / `OPEN` / `REL` per channel
- **Tally indicator**: a strip highlights the channel whose camera is on program
- **Priority per channel**: Low / Normal / High decides who wins when several mics are open
- **ATEM input names**: camera names pulled directly from the ATEM after connecting
- **Program / Preview bus**: PGM and PVW buttons that follow the ATEM, including changes made on the panel
- **Multi M/E support**: choose which M/E bus the auto-switcher controls
- **No-audio camera**: fallback camera when all mics are silent
- **Silence loop**: during silence, keep cutting between the no-audio camera and extra loop cameras,
  holding each for a random time
- **PVW automation camera**: putting one chosen camera on preview turns automation on, any other turns it off
- **Switch holdoff** and **silence delay**: no rapid cutting, natural pauses stay on the speaker
- **Switching presets**: Fast / Medium / Slow with editable attack, release and holdoff
- **Manual test switch**: send a switch command to verify the ATEM connection
- **Stream Deck integration**: control automation from Bitfocus Companion via HTTP
- **Log**: every connection, switch and error, also saved to a file
- **Settings persistence** and **auto-reconnect**

---

## Download

Download `HBS-ATEM-Auto-Switcher.exe` from the [latest release](https://github.com/nickfromsad/HBS-Atem-Auto-Switcher/releases/latest)
and double-click it. No Python install needed.

**First launch.** The exe is not code-signed, so Windows SmartScreen may show *Windows protected your PC*. Click
**More info → Run anyway**.

You also need:

- **Dante Virtual Soundcard**, or any multi-channel audio input
- a **Blackmagic ATEM** switcher on the same network as the computer

On macOS or Linux, run it from source (see [Development](#development)).

---

## Usage

1. Connect your ATEM switcher to the same network as your computer.
2. Open Dante Virtual Soundcard and make sure your audio sources are routed to DVS channels.
3. Start **HBS ATEM Auto Switcher**.
4. Enter the ATEM IP address and click **Connect**.
5. For each channel row, select the DVS device, the audio channel (0 = left, 1 = right), set the gate threshold,
   and choose which ATEM camera input to switch to.
6. Click **▶ Start** to begin audio monitoring.
7. Press **AUTOMATION ON** to enable automatic switching.

Settings are saved on close and restored on the next launch. They live in `Desktop/atem-switcher/`, together with
`atem_log.txt` (the previous session's log is kept as `atem_log.prev.txt`, handy after a crash).

### How the gate works

```
Signal level
    │
    │       ┌─── OPEN (camera on air) ───┐
    │      /                              \
────┼─────/────── threshold ──────────────\────
    │    /  ↑ attack time                  \  ↑ release time
    │   /                                   \ /
    │  ATCK                               REL → CLSD
    │
```

- **CLSD**: signal below threshold, gate closed, camera not selected
- **ATCK**: signal above threshold, waiting for the attack time to confirm it is real speech
- **OPEN**: gate open, this camera is eligible to go on air (loudest open gate wins, weighted by priority)
- **REL**: signal dropped, gate holding open during the release time before closing

### Settings

| Setting | Description |
|---|---|
| M/E | Which M/E bus the switcher controls (M/E 1 = main program output) |
| No-audio camera | Camera to cut to when all microphones are silent |
| Loop every … s | During silence, cycle the no-audio camera and the extra loop cameras, random hold time between the two values |
| Extra loop cameras | Additional cameras for the silence loop, with or without a microphone |
| Switch holdoff | Minimum seconds between two camera switches |
| Silence delay | Seconds of silence before cutting to the no-audio camera |
| PVW automation camera | Preview this camera to turn automation on; preview any other to turn it off |
| Gate threshold | Signal level in dBFS the mic must exceed to open |
| Attack | Seconds the signal must stay above threshold before the gate opens |
| Release | Seconds the gate stays open after the signal drops below threshold |
| Prio | Low (0.5×), Normal or High (2×) weight when several gates are open |

### Stream Deck integration via Bitfocus Companion

The switcher includes a built-in HTTP server that Bitfocus Companion can talk to directly, so you can turn
auto-switching on and off from a Stream Deck button.

In the **Settings** tab, set the port (default `8765`) and click **Enable**. The server starts immediately and the
setting is remembered on next launch.

Add a new connection using the **Generic HTTP** module. Set the base URL to `http://127.0.0.1:8765` (or the IP of the
PC if Companion runs on a different machine). Then on a button, add a **Send HTTP POST request** action and set the
URI to one of the following:

| URI | What it does |
|---|---|
| `/automation/toggle` | Flip automation on or off |
| `/automation/on` | Turn automation on |
| `/automation/off` | Turn automation off |

For a toggle button that also shows whether automation is active, add a **Background Image** feedback to the same
button. Set the URL to `http://127.0.0.1:8765/status/image` with a refresh interval of around 1000 ms. The button shows
green when automation is on and red when it is off.

The `/status` endpoint returns `{"automation_active": true/false}` if you need to read the state from another system.

---

## Development

Requires Python 3.11+.

```bash
pip install PyQt6 sounddevice numpy
python atem_switcher.pyw
```

| Path | |
|---|---|
| `atem_switcher.pyw` | the whole app: ATEM UDP client, audio engine, Companion server and PyQt6 interface |
| `.github/workflows/build-exe.yml` | builds the Windows exe with PyInstaller and publishes it as a release |
| `docs/icon.png` | icon shown in this README (the app icon itself is embedded in the script) |

### Releasing

1. Bump `APP_VERSION` in `atem_switcher.pyw`.
2. Push, then on GitHub open **Actions → Build Windows EXE → Run workflow**.

The workflow builds `HBS-ATEM-Auto-Switcher.exe` with the embedded icon and publishes it as release `v<APP_VERSION>`.

---

## License

MIT. Not affiliated with Blackmagic Design or Audinate. "ATEM" is a trademark of Blackmagic Design,
"Dante" a trademark of Audinate.
