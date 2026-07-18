# PocketInput API

`PocketInput` is the experimental input surface for cartridges in API `0.5.0`.

Buttons:

- `UP`, `DOWN`, `LEFT`, `RIGHT`
- `A`, `B`, `X`, `Y`
- `MENU`, `EXIT`

Methods:

- `pressed(button: String) -> bool`
- `just_pressed(button: String) -> bool`
- `just_released(button: String) -> bool`
- `set_button_state(button: String, is_pressed: bool) -> void`

Packages should not read Shell internals or Android input APIs directly.
