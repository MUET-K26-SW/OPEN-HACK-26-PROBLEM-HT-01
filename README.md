# Team Diamond Medication

A local medication adherence assistant that helps patients track daily doses, review reminders, and keep medication data on their own device.

> *Built To Innovate. Designed To Inspire. Powered by Team Diamond.*

## Features

- **Medication management** — add, edit, and remove medications with a prescribed dose, dose times (entered as `8:00 AM` / `8:00 PM` or 24-hour `HH:MM`), and prescriber instructions
- **Daily schedule** — see today's doses in time order and mark each one as taken; doses not marked within one hour of their scheduled time show as missed
- **Progress tracker** — a progress ring and summary showing completed doses for the day
- **Dose history** — a log of the most recent taken and missed doses, kept across days
- **Prescription upload and OCR** — upload a JPG or PNG image, scan it with Tesseract.js, then review and correct the recognized text before adding it as a medication
- **Reminders**
  - Browser notifications at dose time (while the page is open)
  - Optional sound alarm (a short tone) at dose time (while the page is open)
  - Optional caregiver missed-dose notice, shown on this device only
- **Multilingual interface** — English, Urdu (اردو), and Sindhi (سنڌي), with right-to-left layout for Urdu and Sindhi
- **Responsive design** — works on desktop, tablet, and phone screens, with reduced-motion support
- **Backend status indicator** — a dot in the header shows whether data is being saved to the local backend (green) or only to the browser (orange)

## Project structure

| File | Purpose |
| --- | --- |
| `index.html` | Frontend UI, styles, translations, and client-side logic (single file) |
| `server.ps1` | Local PowerShell HTTP server that serves the app and stores medication state |
| `README.md` | Project documentation |

## Requirements

- Windows with PowerShell (the backend uses `System.Net.HttpListener` and `%LOCALAPPDATA%`)
- A modern browser (Chrome, Edge, Firefox, or Safari)
- Internet access is only needed for:
  - Google Fonts (the app falls back to system fonts if offline)
  - Prescription scanning, which loads Tesseract.js from a CDN the first time you scan

## How to run

1. Open PowerShell in the project folder.
2. Run:

```powershell
./server.ps1
```

3. Open the app in your browser at:

```text
http://127.0.0.1:8001/
```

To use a different port:

```powershell
./server.ps1 -Port 8080
```

Then open `http://127.0.0.1:8080/`.

Press `Ctrl+C` in the PowerShell window to stop the server.

> If PowerShell blocks the script, run it with
> `powershell -ExecutionPolicy Bypass -File .\server.ps1`.

## How to use

1. **Add a medication** — click *Add a medication*, then enter the name, dose, times, and instructions exactly as prescribed. The two entries shown on first launch are fictional examples; replace or remove them.
2. **Or scan a prescription** — upload an image, click *Scan prescription image*, correct the recognized text, then click *Review and add medication* and fill in the dose times.
3. **Track doses** — press *Mark taken* when you take a dose. Press it again to undo.
4. **Turn on reminders** — enable browser notifications and/or the sound alarm and keep the page open. Browsers may require you to allow notifications when prompted.
5. **Switch language** — use the language selector in the top bar.

## Data storage

State is saved in two places:

- **Browser `localStorage`** under the key `daywell-mvp` (language preference under `daywell-language`)
- **Local backend file** at `%LOCALAPPDATA%\TeamDiamondMedication\state.json`

On load, the app reads saved state from the backend. If the backend is not running, the app still works using browser storage only.

Stored data includes medications, dose logs, and dose history. Nothing is sent to any external server, except that the image OCR library is downloaded from a CDN when you scan.

## Backend API

The server listens on `127.0.0.1` only (not reachable from other devices).

| Method | Path | Description |
| --- | --- | --- |
| `GET` | `/` or `/index.html` | Serves the app |
| `GET` | `/api/health` | Returns `{ "status": "ok", "storage": "local" }` |
| `GET` | `/api/state` | Returns saved state, or `null` if none exists |
| `PUT` | `/api/state` | Validates and saves state (`meds`, `log`, `history`) |

`PUT /api/state` rejects payloads over 1 MB (`413`) and invalid data (`400`), including medication names over 200 characters, times not in `HH:MM` format, and history entries with an unknown status. State is written to a temporary file and then moved into place so a failed write does not corrupt existing data.

## Limitations

- Reminders and alarms only work while the page is open in the browser; there is no background service.
- Notifications are local to the browser/device. **No SMS, email, or messages are sent**, including caregiver alerts.
- Missed doses are detected only while the app is open, so history may have gaps if the page was closed.
- OCR can make mistakes and only reads English text. Always check the result against the actual prescription.
- The backend is a single-user local tool with no authentication or encryption. Anyone with access to the device user profile can read the stored data.
- Windows only, because of the PowerShell backend.

## Important

This is a reminder tool and should not replace a clinician's instructions or medication plan. Always follow the prescription details provided by your healthcare professional.
