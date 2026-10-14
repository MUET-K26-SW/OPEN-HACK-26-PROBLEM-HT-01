# OPEN-HACK-26-PROBLEM-HT-01
MUETSZAB-OPEN-HACK-26
# Team Diamond Medication
A local medication adherence assistant that helps patients track daily doses, review reminders, and store medication data on the device.

## Project overview
This project includes:

- A browser-based medication dashboard in `index.html`
- A local PowerShell backend in `server.ps1`
- Persistent medication state saved in the Windows user profile under `%LOCALAPPDATA%\TeamDiamondMedication`

The app lets users:
- Add medications and scheduled dose times
- Mark doses as taken or missed
- Review daily history and progress
- Upload a prescription image and OCR text review
- Configure browser reminders and local caregiver notifications
- Switch between English, Urdu, and Sindhi interfaces
## Files
- `index.html` — frontend UI and client-side logic
- `server.ps1` — local HTTP server that serves the app and stores medication state
- `README.md` — project documentation
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
If you want a different port:
```powershell
./server.ps1 -Port 8080
```
Then open:
```text
http://127.0.0.1:8080/
```
## Notes

- The app stores state locally in the browser and in the local backend data folder.
- Reminders and notifications are local to the browser/device and do not send SMS or email.
- OCR text is a convenience feature and should always be checked against the actual prescription.

## Important

This is a reminder tool and should not replace a clinician’s instructions or medication plan. Always follow the prescription details provided by your healthcare professional.
