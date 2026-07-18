# OpenPocket Cartridges

An OpenPocket cartridge is a controller-first Godot app or game distributed as one `.pctrg` file. The file contains `cartridge.json`, a real Godot `content.pck`, and optional icon, README, and license metadata.

SDK 0.4.0 is experimental. Cartridge services are `PocketInput`, `PocketStorage`, `CartridgeAudio`, `CartridgeAchievements`, `PocketSystem`, and `PocketTheme`. `PocketAudio` owns Shell UI sound. External GDScript is not sandboxed or signed.
