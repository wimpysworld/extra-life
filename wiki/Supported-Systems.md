# Supported Systems

Extra Life ships 33 curated Libretro cores in `/run/current-system/sw/lib/retroarch/cores`. Every `.so` filename matches the `CoreForPlaylist` lookup table in Ludo (`core/core.go`). Games run out of the box without manual core downloads.

## Grouped manufacturer overview

Every core runs on both `x86_64-linux` and `aarch64-linux`, except where the table notes an architecture rule.

| Manufacturer or group | Systems | Libretro cores | Platform notes |
| --- | --- | --- | --- |
| Arcade and engines | FBNeo - Arcade Games, Cave Story, ChaiLove | `fbneo_libretro`, `nxengine_libretro`, `chailove_libretro` | All targets |
| Atari | 2600, 5200, 7800, Jaguar, Lynx, ST | `stella2014_libretro`, `atari800_libretro`, `prosystem_libretro`, `virtualjaguar_libretro`, `handy_libretro`, `hatari_libretro` | All targets |
| Bandai | WonderSwan, WonderSwan Color | `mednafen_wswan_libretro` | All targets |
| Coleco, Microsoft, and Spectravideo | ColecoVision, MSX, MSX2, SVI-318 - SVI-328 | `bluemsx_libretro` | All targets |
| GCE, Magnavox, and Philips | Vectrex, Odyssey2, Videopac+ | `vecx_libretro`, `o2em_libretro` | All targets |
| NEC | PC Engine - TurboGrafx 16, PC Engine CD - TurboGrafx-CD, PC Engine SuperGrafx, PC-FX | `mednafen_pce_libretro`, `mednafen_pcfx_libretro` | All targets |
| Nintendo consoles | Entertainment System, Family Computer Disk System, Super Nintendo, Satellaview, Sufami Turbo, Nintendo 64, GameCube, Virtual Boy | `fceumm_libretro`, `snes9x_libretro`, `mupen64plus_next_libretro`, `dolphin_libretro`, `mednafen_vb_libretro` | `dolphin_libretro` runs on `x86_64-linux` and capable `aarch64-linux` targets |
| Nintendo handhelds | Game Boy, Game Boy Color, Game Boy Advance, Pokemon Mini, Nintendo DS, Nintendo 3DS | `gambatte_libretro`, `mgba_libretro`, `pokemini_libretro`, `melonds_libretro`, `citra_libretro` | `citra_libretro` runs on `x86_64-linux` and capable `aarch64-linux` targets |
| Sega | SG-1000, Master System - Mark III, Mega Drive - Genesis, Mega-CD - Sega CD, 32X, PICO, Game Gear, Saturn, Dreamcast | `genesis_plus_gx_libretro`, `picodrive_libretro`, `mednafen_saturn_libretro`, `flycast_libretro` | All targets |
| SNK | Neo Geo Pocket, Neo Geo Pocket Color | `mednafen_ngp_libretro` | All targets |
| Sony | PlayStation, PlayStation 2, PlayStation Portable | `swanstation_libretro`, `pcsx_rearmed_libretro`, `pcsx2_libretro`, `ppsspp_libretro` | PlayStation uses `swanstation_libretro` on `x86_64-linux` and `pcsx_rearmed_libretro` on `aarch64-linux`. `pcsx2_libretro` runs on `x86_64-linux` only. |

## Full 33-core `CoreForPlaylist` matrix

Extra Life constructs the core directory with `pkgs.symlinkJoin` or `pkgs.runCommand` so that every `.so` file matches `CoreForPlaylist` in Ludo. Sony PlayStation uses `swanstation_libretro` on `x86_64-linux` and `pcsx_rearmed_libretro` on `aarch64-linux`.

| Core `.so` name (`CoreForPlaylist`) | Playlist and system names | Architecture notes |
| --- | --- | --- |
| `stella2014_libretro` | `Atari - 2600` | All targets |
| `atari800_libretro` | `Atari - 5200` | All targets |
| `prosystem_libretro` | `Atari - 7800` | All targets |
| `virtualjaguar_libretro` | `Atari - Jaguar` | All targets |
| `handy_libretro` | `Atari - Lynx` | All targets |
| `hatari_libretro` | `Atari - ST` | All targets |
| `mednafen_wswan_libretro` | `Bandai - WonderSwan`, `Bandai - WonderSwan Color` | All targets |
| `nxengine_libretro` | `Cave Story` | All targets |
| `chailove_libretro` | `ChaiLove` | All targets |
| `bluemsx_libretro` | `Coleco - ColecoVision`, `Microsoft - MSX`, `Microsoft - MSX2`, `Spectravideo - SVI-318 - SVI-328` | All targets |
| `fbneo_libretro` | `FBNeo - Arcade Games` | All targets |
| `vecx_libretro` | `GCE - Vectrex` | All targets |
| `o2em_libretro` | `Magnavox - Odyssey2`, `Philips - Videopac+` | All targets |
| `mednafen_pce_libretro` | `NEC - PC Engine - TurboGrafx 16`, `NEC - PC Engine CD - TurboGrafx-CD`, `NEC - PC Engine SuperGrafx` | All targets |
| `mednafen_pcfx_libretro` | `NEC - PC-FX` | All targets |
| `fceumm_libretro` | `Nintendo - Family Computer Disk System`, `Nintendo - Nintendo Entertainment System` | All targets |
| `mgba_libretro` | `Nintendo - Game Boy Advance` | All targets |
| `gambatte_libretro` | `Nintendo - Game Boy`, `Nintendo - Game Boy Color` | All targets |
| `dolphin_libretro` | `Nintendo - GameCube` | `x86_64-linux` and capable `aarch64-linux` targets |
| `citra_libretro` | `Nintendo - Nintendo 3DS` | `x86_64-linux` and capable `aarch64-linux` targets |
| `mupen64plus_next_libretro` | `Nintendo - Nintendo 64` | All targets |
| `melonds_libretro` | `Nintendo - Nintendo DS` | All targets |
| `pokemini_libretro` | `Nintendo - Pokemon Mini` | All targets |
| `snes9x_libretro` | `Nintendo - Satellaview`, `Nintendo - Sufami Turbo`, `Nintendo - Super Nintendo Entertainment System` | All targets |
| `mednafen_vb_libretro` | `Nintendo - Virtual Boy` | All targets |
| `picodrive_libretro` | `Sega - 32X`, `Sega - PICO` | All targets |
| `flycast_libretro` | `Sega - Dreamcast` | All targets |
| `genesis_plus_gx_libretro` | `Sega - Game Gear`, `Sega - Master System - Mark III`, `Sega - Mega Drive - Genesis`, `Sega - Mega-CD - Sega CD`, `Sega - SG-1000` | All targets |
| `mednafen_saturn_libretro` | `Sega - Saturn` | All targets |
| `mednafen_ngp_libretro` | `SNK - Neo Geo Pocket`, `SNK - Neo Geo Pocket Color` | All targets |
| `swanstation_libretro` / `pcsx_rearmed_libretro` | `Sony - PlayStation` | `swanstation_libretro` on `x86_64-linux`, `pcsx_rearmed_libretro` on `aarch64-linux` (ARM) |
| `pcsx2_libretro` | `Sony - PlayStation 2` | `x86_64-linux` only |
| `ppsspp_libretro` | `Sony - PlayStation Portable` | All targets |

## `/storage/Retro` directory structure

System assets, shaders, No-Intro databases, and emulator cores live in the read-only Nix store. All mutable user data lives under `/storage/Retro` on the `STORAGE` (`ext4`) partition. At first boot, `systemd.tmpfiles.rules` creates these directories with ownership set to `ludo:users`.

```text
/storage/Retro/
├── playlists/    # Generated Ludo playlist files (.lpl)
├── roms/         # User read-only memory (ROM) sets organised by system name
├── savefiles/    # In-game battery saves (.srm)
├── savestates/   # Emulator state snapshots (.state)
├── screenshots/  # Captured in-game screenshots (.png)
├── system/       # Basic Input/Output System (BIOS) and firmware files
└── thumbnails/   # Box art, title screens, and gameplay thumbnails
```

| Directory | Config key in `/etc/ludo.toml` | Purpose and usage |
| --- | --- | --- |
| `/storage/Retro/roms` | `roms_dir` | Holds user ROM sets. Create one subfolder per system name (for example `/storage/Retro/roms/Sega - Mega Drive - Genesis/`) before you scan. |
| `/storage/Retro/system` | `system_dir` | Holds BIOS files and system firmware that optical-disc and computer cores require (such as PlayStation, Sega Saturn, Dreamcast, and PC Engine CD). |
| `/storage/Retro/playlists` | `playlists_dir` | Stores playlist files that the Ludo directory scanner generates from your ROM folders. |
| `/storage/Retro/savefiles` | `savefiles_dir` | Stores persistent in-game memory card and cartridge battery saves. |
| `/storage/Retro/savestates` | `savestates_dir` | Stores instant emulator state snapshots that you save or load from the quick menu. |
| `/storage/Retro/screenshots` | `screenshots_dir` | Stores PNG screenshots that you capture during gameplay. |
| `/storage/Retro/thumbnails` | `thumbnails_dir` | Stores box art and thumbnail images matched to playlist entries. |
