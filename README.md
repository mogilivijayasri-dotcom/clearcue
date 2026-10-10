# ClearCue

How to build (Windows):
1. Extract this zip to C:\  (so the folder is C:\clearcue). Do NOT keep it inside OneDrive / Desktop.
2. Open C:\clearcue and double-click build.bat
3. Wait. When it finishes, a folder opens with app-debug.apk
4. Send app-debug.apk to your phone (WhatsApp Web / Google Drive) and install it.

When the new app is installed, the Home screen shows 5 cards:
Document / Notice, Bill Analysis, Medicine Scanner, Medicine Library, Scan History.

Architecture:
  Screens (UI) -> Analyzer (logic) -> Repositories -> SQLite database (clearcue.db)
  Tables: medicines, scans, qa
