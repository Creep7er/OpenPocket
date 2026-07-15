# Lifecycle

The entry scene is instantiated inside the 400x320 virtual screen. Emit `request_system_menu` for the system overlay and `exit_to_library` to leave. Implement `set_paused_by_system(paused)` so updates stop while an overlay is active. MENU and BACK must never call `quit` directly.
