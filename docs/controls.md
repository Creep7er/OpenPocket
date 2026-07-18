# Physical Controls

`PixelDpad` and `PixelStick` emit the same digital `UP/DOWN/LEFT/RIGHT` states through `PocketInput`. The virtual stick supports fixed/floating origin, size, deadzone, and left/right placement. It owns one touch index, releases every active direction on exit, and remains independent of A/B/X/Y touch controls for multitouch.

Action buttons use stepped pixel polygons. MENU opens the system overlay. BACK follows Shell/package navigation and requires confirmation before application exit.
