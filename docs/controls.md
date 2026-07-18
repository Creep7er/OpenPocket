# Physical Controls

`PixelDpad` and `PixelStick` emit the same digital `UP/DOWN/LEFT/RIGHT` states through `PocketInput`. The virtual stick supports fixed/floating origin, size, deadzone, and left/right placement. It owns one touch index, releases every active direction on exit, and remains independent of A/B/X/Y touch controls for multitouch.

Action buttons use stepped octagonal pixel polygons with clipped corners and short edge highlights. They do not use vector circles or rectangular inner outlines. Their visual faces remain smaller than their touch targets, while center spacing keeps adjacent buttons visually distinct.

VBoy places both control groups in the lower thumb area. VGirl always keeps direction input on the left and XYAB on the right, with the virtual display between them. MENU opens the system overlay. BACK follows Shell/package navigation and requires confirmation before application exit.

The UI audit captures Shell, Snake, Pong, Notes, Breakout, system overlay, and Breakout confirmation states. Selection bars must stay inside their owning screen or modal panel.
