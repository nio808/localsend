# LocalSend tray fork

Based on upstream v1.18.2. On Windows, enabling **Settings > Minimize to the System Tray/Menu Bar when closing** now also hides the window when the minimize button is pressed. Opening the tray icon restores a minimized window before focusing it. Right-click the tray icon and choose Exit to stop the app.

For background receiving, enable **Autostart after login**, **Autostart: Start hidden**, and **Quick Save**, then select **Downloads/LocalSend** as the save folder. Quick Save automatically accepts incoming files from reachable devices; use its favorites-only mode if preferred. Text messages and requests requiring approval can still open the window. The app runs while you are signed in, not before Windows login.

Download the Windows release artifact from the **Tray Windows build** workflow on the `tray-background` branch. Extract the entire artifact into one directory, keeping its DLLs and data folder with the executable. Launch `localsend_app.exe --hidden` to start directly in the tray.

Validation: the upstream CI runs formatting, analysis, app and isolate tests, Rust checks, and packaging checks. The Windows workflow also runs the app tests before building. `app/test/widget/tray_background_test.dart` covers minimizing with the setting enabled and disabled, native hide failures, restoration order, and unchanged Linux behavior.

This is a personal fork, not an official LocalSend release. Existing encryption, PIN checks, file validation, and transfer handling are unchanged.
