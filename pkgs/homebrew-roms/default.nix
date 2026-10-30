{
  lib,
  fetchurl,
  runCommand,
  unzip,
  writeText,
}:
let
  games = [
    {
      system = "Nintendo - Game Boy Color";
      title = "Tobu Tobu Girl Deluxe";
      romFile = "tobutobugirl-dx.gbc";
      rom = fetchurl {
        name = "tobudx.gb";
        url = "https://raw.githubusercontent.com/gbdev/database/94368e51470f14fe5c495e6e65c994f2c3b6c661/entries/tobutobugirldeluxe/tobudx.gb";
        hash = "sha256-Cg6AGNu8jX+M2Z8F583HtMyeNY7P6Td+v7IpGoTG4xA=";
      };
      snap = fetchurl {
        name = "1.png";
        url = "https://raw.githubusercontent.com/gbdev/database/94368e51470f14fe5c495e6e65c994f2c3b6c661/entries/tobutobugirldeluxe/1.png";
        hash = "sha256-DRLwEfVZ2JPzvyWIaxZyk7vPmu4s8ZYrvcmqxUWPFQk=";
      };
      author = "Tangram Games (Simon Larsen)";
      license = "MIT (code), CC-BY-4.0 (assets)";
      url = "https://raw.githubusercontent.com/gbdev/database/94368e51470f14fe5c495e6e65c994f2c3b6c661/entries/tobutobugirldeluxe/tobudx.gb";
    }
    {
      system = "Nintendo - Game Boy Color";
      title = "uCity";
      romFile = "ucity.gbc";
      rom = fetchurl {
        name = "ucity.gbc";
        url = "https://github.com/AntonioND/ucity/releases/download/v1.3/ucity.gbc";
        hash = "sha256-lCLuLKe36h1GtYsqQp//PzVN/T5zLe4eeuYiDxSM5uA=";
      };
      snap = fetchurl {
        name = "screenshot1.png";
        url = "https://raw.githubusercontent.com/gbdev/database/94368e51470f14fe5c495e6e65c994f2c3b6c661/entries/ucity/screenshot1.png";
        hash = "sha256-8X5iT2U0vgwqiD/OO8nFj4HaxGf9Taxl+5cHVX1x04A=";
      };
      author = "Antonio Niño Díaz (AntonioND)";
      license = "GPL-3.0-or-later";
      url = "https://github.com/AntonioND/ucity/releases/download/v1.3/ucity.gbc";
    }
    {
      system = "Nintendo - Game Boy Advance";
      title = "Skyland";
      romFile = "Skyland.gba";
      rom = fetchurl {
        name = "Skyland.gba";
        url = "https://github.com/evanbowman/skyland-beta/releases/download/2026.10.6.0/Skyland.gba";
        hash = "sha256-USCJqXQmcrsn9t2A6wEhSg5eADL+3swmMBRqN7q+MYw=";
      };
      snap = fetchurl {
        name = "title.png";
        url = "https://raw.githubusercontent.com/evanbowman/skyland-beta/613ee93464ad1349b643d0abb58823d8e3719797/imgs_for_readme/title.png";
        hash = "sha256-G1DghudS2qzPRNmfSq8OOVgdahjA+mjFjau9ybaJpXo=";
      };
      author = "Evan Bowman";
      license = "MPL-2.0";
      url = "https://github.com/evanbowman/skyland-beta/releases/download/2026.10.6.0/Skyland.gba";
    }
    {
      system = "Nintendo - Game Boy Advance";
      title = "Anguna - Warriors of Virtue";
      romFile = "anguna.gba";
      rom = fetchurl {
        name = "anguna.gba";
        url = "https://gitlab.com/recalbox/recalbox/-/raw/64b0fd40b17eec45f8aa42c5a5c5e1bff410b909/package/recalbox-romfs2/systems/gba/init/roms/Anguna%20(Nathan%20Tolbert%20and%20Chris%20Hildenbrand).gba";
        hash = "sha256-zTuWnV7Ws4sgOcEbiU1tsvw/rSCaf9BGvuJBzGYGmFE=";
      };
      snap = fetchurl {
        name = "anguna.png";
        url = "https://gitlab.com/recalbox/recalbox/-/raw/64b0fd40b17eec45f8aa42c5a5c5e1bff410b909/package/recalbox-romfs2/systems/gba/init/roms/media/images/Anguna%20(Nathan%20Tolbert%20and%20Chris%20Hildenbrand).png";
        hash = "sha256-ZVlM3BiUhdGgKyOkCbQfqdalhgfq+BE3BGRilWVvKjg=";
      };
      author = "Nathan Tolbert & Chris Hildenbrand";
      license = "MIT (code), CC-BY-3.0 (assets)";
      url = "https://gitlab.com/recalbox/recalbox/-/raw/64b0fd40b17eec45f8aa42c5a5c5e1bff410b909/package/recalbox-romfs2/systems/gba/init/roms/Anguna%20(Nathan%20Tolbert%20and%20Chris%20Hildenbrand).gba";
    }
    {
      system = "Nintendo - Nintendo Entertainment System";
      title = "Nova the Squirrel";
      romFile = "novathesquirrel.nes";
      rom = fetchurl {
        name = "novathesquirrel.nes";
        url = "https://github.com/NovaSquirrel/NovaTheSquirrel/releases/download/v1.0.6a/nova.nes";
        hash = "sha256-5HgOkLnRWHSJv7eX0so5W+ITceqSYvqfh/mTJOxpYKs=";
      };
      snap = fetchurl {
        name = "novathesquirrel.png";
        url = "https://gitlab.com/recalbox/recalbox/-/raw/64b0fd40b17eec45f8aa42c5a5c5e1bff410b909/package/recalbox-romfs2/systems/nes/init/roms/media/images/Nova%20The%20Squirrel.png";
        hash = "sha256-4XVUfA3QpUb9UuBHihYL6g+X17zxxA+85yu9sCqDAP4=";
      };
      author = "NovaSquirrel";
      license = "GPL-3.0-or-later (code), CC-BY-NC-SA-4.0 (assets)";
      url = "https://github.com/NovaSquirrel/NovaTheSquirrel/releases/download/v1.0.6a/nova.nes";
    }
    {
      system = "Nintendo - Nintendo Entertainment System";
      title = "Blade Buster";
      romFile = "BladeBuster.nes";
      rom = fetchurl {
        name = "BladeBuster.nes";
        url = "https://gitlab.com/recalbox/recalbox/-/raw/64b0fd40b17eec45f8aa42c5a5c5e1bff410b909/package/recalbox-romfs2/systems/nes/init/roms/BladeBuster%20(High%20Level%20Challenge).nes";
        hash = "sha256-7o3xd+76K8Xny8TMPRm5R7rObH960G7aq4Nzi1tzzYc=";
      };
      snap = fetchurl {
        name = "BladeBuster.png";
        url = "https://gitlab.com/recalbox/recalbox/-/raw/64b0fd40b17eec45f8aa42c5a5c5e1bff410b909/package/recalbox-romfs2/systems/nes/init/roms/media/images/BladeBuster%20(High%20Level%20Challenge).png";
        hash = "sha256-jcbjiuDaKUFaPyq+SsFwSWmIVfKCx2IB2Kc/zdR/8gU=";
      };
      author = "High Level Challenge";
      license = "Freeware";
      url = "https://gitlab.com/recalbox/recalbox/-/raw/64b0fd40b17eec45f8aa42c5a5c5e1bff410b909/package/recalbox-romfs2/systems/nes/init/roms/BladeBuster%20(High%20Level%20Challenge).nes";
    }
    {
      system = "Nintendo - Nintendo Entertainment System";
      title = "Super Tilt Bro.";
      romFile = "SuperTiltBro.nes";
      rom = fetchurl {
        name = "SuperTiltBro.nes";
        url = "https://buildbot.libretro.com/assets/cores/Nintendo%20-%20Nintendo%20Entertainment%20System/Super%20Tilt%20Bro%20%28USA%29.nes";
        hash = "sha256-zVqhzTBsB/3yKs4WQHDcenr+csVh40lFwqD17vttHCA=";
      };
      snap = fetchurl {
        name = "SuperTiltBro.png";
        url = "https://raw.githubusercontent.com/libretro-thumbnails/Nintendo_-_Nintendo_Entertainment_System/4d21463bf5d553afc34d99183c9ad5833f773b93/Named_Snaps/Super%20Tilt%20Bro.%20(World)%20(v2.0-beta6)%20(Aftermarket)%20(Unl).png";
        hash = "sha256-EICjBwmHzLc6Mh+Cd1ppQS2H/0JoDlbIFc9v3+Fj4dk=";
      };
      author = "Sylvain Gadrat (RogerBidon)";
      license = "WTFPL";
      url = "https://buildbot.libretro.com/assets/cores/Nintendo%20-%20Nintendo%20Entertainment%20System/Super%20Tilt%20Bro%20%28USA%29.nes";
    }
    {
      system = "Nintendo - Nintendo Entertainment System";
      title = "Twin Dragons";
      romFile = "TwinDragons.nes";
      rom = fetchurl {
        name = "TwinDragons.nes";
        url = "https://gitlab.com/recalbox/recalbox/-/raw/64b0fd40b17eec45f8aa42c5a5c5e1bff410b909/package/recalbox-romfs2/systems/nes/init/roms/Broke%20Studio/Twin%20Dragons/Twin-Dragons-DEMO.nes";
        hash = "sha256-73QPiN9acLQJVN+f8VMHeM6nYOiu/7guUNUwPx9yaco=";
      };
      snap = fetchurl {
        name = "Twin-Dragons-DEMO.png";
        url = "https://gitlab.com/recalbox/recalbox/-/raw/64b0fd40b17eec45f8aa42c5a5c5e1bff410b909/package/recalbox-romfs2/systems/nes/init/roms/Broke%20Studio/media/images/Twin%20Dragons/Twin-Dragons-DEMO.png";
        hash = "sha256-j3WYisdEv3tJ7yVWLsQXaIiOq4XzreXL3/YjEYm5574=";
      };
      author = "Glutock / Broke Studio";
      license = "Zlib / CC-BY / Freeware demo";
      url = "https://gitlab.com/recalbox/recalbox/-/raw/64b0fd40b17eec45f8aa42c5a5c5e1bff410b909/package/recalbox-romfs2/systems/nes/init/roms/Broke%20Studio/Twin%20Dragons/Twin-Dragons-DEMO.nes";
    }
    {
      system = "Nintendo - Nintendo Entertainment System";
      title = "Lan Master";
      romFile = "LanMaster.nes";
      rom = fetchurl {
        name = "LanMaster.nes";
        url = "https://gitlab.com/recalbox/recalbox/-/raw/64b0fd40b17eec45f8aa42c5a5c5e1bff410b909/package/recalbox-romfs2/systems/nes/init/roms/Lan%20Master%20(Shiru).nes";
        hash = "sha256-rf0XL7PXnfDIB2TwafE2tAg8dnhp87nN0AwlvgzzlnE=";
      };
      snap = fetchurl {
        name = "LanMaster.png";
        url = "https://gitlab.com/recalbox/recalbox/-/raw/64b0fd40b17eec45f8aa42c5a5c5e1bff410b909/package/recalbox-romfs2/systems/nes/init/roms/media/images/Lan%20Master%20(Shiru).png";
        hash = "sha256-4Q8zP58sDBgiJKe6XfwEoyZSPicZTDcs7xcT89owKcU=";
      };
      author = "Shiru";
      license = "Public Domain (PD 2011 Shiru)";
      url = "https://gitlab.com/recalbox/recalbox/-/raw/64b0fd40b17eec45f8aa42c5a5c5e1bff410b909/package/recalbox-romfs2/systems/nes/init/roms/Lan%20Master%20(Shiru).nes";
    }
    {
      system = "Nintendo - Nintendo Entertainment System";
      title = "Lawn Mower";
      romFile = "LawnMower.nes";
      rom = fetchurl {
        name = "LawnMower.nes";
        url = "https://gitlab.com/recalbox/recalbox/-/raw/64b0fd40b17eec45f8aa42c5a5c5e1bff410b909/package/recalbox-romfs2/systems/nes/init/roms/Lawn%20Mower%20(Shiru).nes";
        hash = "sha256-GB7z/xdpqFrphzbgKAnmXl11i0U+u0PsS5/mDJOtIkw=";
      };
      snap = fetchurl {
        name = "LawnMower.png";
        url = "https://gitlab.com/recalbox/recalbox/-/raw/64b0fd40b17eec45f8aa42c5a5c5e1bff410b909/package/recalbox-romfs2/systems/nes/init/roms/media/images/Lawn%20Mower%20(Shiru).png";
        hash = "sha256-1Or6xVyOAXJQSn4GYxPv2NSWZOKy0dm8ygsEC8SsRFQ=";
      };
      author = "Shiru";
      license = "Public Domain (PD 2011 Shiru)";
      url = "https://gitlab.com/recalbox/recalbox/-/raw/64b0fd40b17eec45f8aa42c5a5c5e1bff410b909/package/recalbox-romfs2/systems/nes/init/roms/Lawn%20Mower%20(Shiru).nes";
    }
    {
      system = "Nintendo - Super Nintendo Entertainment System";
      title = "Classic Kong Complete";
      romFile = "ClassicKongComplete.smc";
      rom = fetchurl {
        name = "ClassicKongComplete.smc";
        url = "https://raw.githubusercontent.com/nathancassano/classickong/6ee8707fba0f54391794537d9116898d4c9a6721/Classic%20Kong%20Complete%20(U).smc";
        hash = "sha256-Qmu005vftKUf8Q2nIFAUYYhOE/i9rUw5XhetRecfBiU=";
      };
      snap = fetchurl {
        name = "ClassicKongComplete.png";
        url = "https://raw.githubusercontent.com/batocera-linux/batocera.linux/ad4e6535ca730f45b0f391c87b7ca67391e66fc2/package/batocera/emulationstation/batocera-es-system/roms/snes/images/DonkeyKongClassic%20(Shiru)-image.png";
        hash = "sha256-wao8oed7PsvwvM5h/lpcuiBV9qDyZXTY56g24X/lpcM=";
      };
      author = "Bubble Zap Games / Shiru";
      license = "Apache-2.0 / Freeware";
      url = "https://raw.githubusercontent.com/nathancassano/classickong/6ee8707fba0f54391794537d9116898d4c9a6721/Classic%20Kong%20Complete%20(U).smc";
    }
    {
      system = "Sega - Mega Drive - Genesis";
      title = "L'Abbaye des Morts";
      romFile = "AbbayeDesMorts.bin";
      rom = fetchurl {
        name = "AbbayeDesMorts.bin";
        url = "https://gitlab.com/recalbox/recalbox/-/raw/64b0fd40b17eec45f8aa42c5a5c5e1bff410b909/package/recalbox-romfs2/systems/megadrive/init/roms/L'Abbaye%20des%20Morts%20(Mun).bin";
        hash = "sha256-ZobRwMQEG8FK/baC2Y90dn7jSjkQZNggAtGRJ/RJ8wU=";
      };
      snap = fetchurl {
        name = "AbbayeDesMorts.png";
        url = "https://gitlab.com/recalbox/recalbox/-/raw/64b0fd40b17eec45f8aa42c5a5c5e1bff410b909/package/recalbox-romfs2/systems/megadrive/init/roms/media/images/L'Abbaye%20des%20Morts%20(Mun).png";
        hash = "sha256-OKfi0TyjxqEtyEkoAahiDhqVYqmS3Sfv2sG8HNLQjcc=";
      };
      author = "Locomalito, Gryzor87 & Mun";
      license = "GPL-3.0 (code), CC-BY-3.0 (assets)";
      url = "https://gitlab.com/recalbox/recalbox/-/raw/64b0fd40b17eec45f8aa42c5a5c5e1bff410b909/package/recalbox-romfs2/systems/megadrive/init/roms/L'Abbaye%20des%20Morts%20(Mun).bin";
    }
    {
      system = "Sega - Mega Drive - Genesis";
      title = "Old Towers";
      romFile = "OldTowers.bin";
      rom = fetchurl {
        name = "OldTowers.bin";
        url = "https://buildbot.libretro.com/assets/cores/Sega%20-%20Mega%20Drive%20-%20Genesis/ot12.bin";
        hash = "sha256-Oc1lDZIleF6ck9O+uLqVM06xYHerkwy/5fddmZmZFXY=";
      };
      snap = fetchurl {
        name = "OldTowers.png";
        url = "https://gitlab.com/recalbox/recalbox/-/raw/64b0fd40b17eec45f8aa42c5a5c5e1bff410b909/package/recalbox-romfs2/systems/megadrive/init/roms/media/images/Old%20Towers%20(Retrosouls).png";
        hash = "sha256-cS1GoiOQv7n1mBQwLYMhM3HcOBclo6EMIGX1c/d6EKA=";
      };
      author = "Retrosouls (Denis Grachev)";
      license = "CC-BY-NC-SA-4.0 / Libretro freeware";
      url = "https://buildbot.libretro.com/assets/cores/Sega%20-%20Mega%20Drive%20-%20Genesis/ot12.bin";
    }
    {
      system = "Sega - Mega Drive - Genesis";
      title = "Alter Ego";
      romFile = "AlterEgo.bin";
      rom = fetchurl {
        name = "AlterEgo.bin";
        url = "https://buildbot.libretro.com/assets/cores/Sega%20-%20Mega%20Drive%20-%20Genesis/aepd.bin";
        hash = "sha256-K1UOFlMCnplLy0LOLY9zzYAK3m7y/vEopEZld+jznM0=";
      };
      snap = fetchurl {
        name = "AlterEgo.png";
        url = "https://raw.githubusercontent.com/libretro-thumbnails/Sega_-_Mega_Drive_-_Genesis/b81fd421cc18d95a1d3df2c500267e7917ae09a1/Named_Snaps/AlterEgo%20Remastered%20(World)%20(Aftermarket)%20(Unl).png";
        hash = "sha256-JPXymK/Uu1uDYpb3yydERHaGdtOuH94SK5BaYx/vPXo=";
      };
      author = "Retrosouls (Denis Grachev) / Kulor";
      license = "Freeware / Public Domain";
      url = "https://buildbot.libretro.com/assets/cores/Sega%20-%20Mega%20Drive%20-%20Genesis/aepd.bin";
    }
    {
      system = "Nintendo - Nintendo 64";
      title = "Driving Strikers 64";
      romFile = "driving_strikers.z64";
      rom = fetchurl {
        name = "driving_strikers.z64";
        url = "https://github.com/SpookyIluha/Driving-Strikers-64/releases/download/release_103/drivingstrikers64.z64";
        hash = "sha256-sbhHWws9fuD59VTxgYMF00frsOVFORjAgB13iL97EYU=";
      };
      snap = fetchurl {
        name = "driving_strikers.png";
        url = "https://github.com/user-attachments/assets/ecf9522f-bc18-4e72-a50b-384b89b180b2";
        hash = "sha256-p3FwrAmqhRdT5xIKBWLdgPNsPlA+jczoJgHysPExgKE=";
      };
      author = "SpookyIluha";
      license = "Unlicense (code) + Authorised freeware ROM";
      url = "https://github.com/SpookyIluha/Driving-Strikers-64/releases/download/release_103/drivingstrikers64.z64";
    }
    {
      system = "Cave Story";
      title = "Cave Story";
      romFile = "Doukutsu.exe";
      isCaveStoryZip = true;
      rom = fetchurl {
        name = "CaveStory.zip";
        url = "https://buildbot.libretro.com/assets/cores/Cave%20Story/Cave%20Story%20%28En%29.zip";
        hash = "sha256-uOG07WZ6awdYEavFLkaO88U05+JOLvC8RNj/lZmcg/0=";
      };
      snap = fetchurl {
        name = "CaveStory.png";
        url = "https://raw.githubusercontent.com/libretro-thumbnails/Cave_Story/3f1c5fa45a92dddbd6de453c82ca10c2777cc955/Named_Snaps/Cave%20Story%20(En).png";
        hash = "sha256-kobUCng6AR17rPTbL2J0B7x1Q4zF+2MnPZy9QS+oNKE=";
      };
      author = "Studio Pixel / NXEngine";
      license = "GPL-3.0 (nxengine), Studio Pixel Freeware";
      url = "https://buildbot.libretro.com/assets/cores/Cave%20Story/Cave%20Story%20%28En%29.zip";
    }
  ];

  gamesBySystem = builtins.groupBy (g: g.system) games;

  licensesMd = writeText "LICENSES.md" ''
    # Bundled Homebrew Games

    Extra Life includes the following legally redistributable homebrew and freeware games:

    | System | Title | Author | Licence | Upstream URL |
    | --- | --- | --- | --- | --- |
    ${lib.concatMapStringsSep "\n" (
      g: "| ${g.system} | ${g.title} | ${g.author} | ${g.license} | ${g.url} |"
    ) games}
  '';

  playlistFor =
    system: sysGames:
    writeText "${system}.csv" (
      lib.concatMapStrings (
        g: "/storage/Retro/roms/${g.system}/${g.romFile}\t${g.title}\t00000000\n"
      ) sysGames
    );
in
runCommand "homebrew-roms"
  {
    nativeBuildInputs = [ unzip ];
    meta = {
      description = "Curated legally redistributable homebrew ROMs, playlists, and thumbnails for Extra Life";
      maintainers = with lib.maintainers; [ flexiondotorg ];
      platforms = lib.platforms.all;
    };
  }
  ''
    retro="$out/share/extra-life/retro"
    mkdir -p "$retro/roms" "$retro/playlists" "$retro/thumbnails"
    cp "${licensesMd}" "$retro/roms/LICENSES.md"

    ${lib.concatMapStringsSep "\n" (g: ''
      mkdir -p "$retro/roms/${g.system}" "$retro/thumbnails/${g.system}/Named_Snaps"
      ${
        if g.isCaveStoryZip or false then
          ''
            unzip -q "${g.rom}" -d "$TMPDIR/cavestory"
            cp -r "$TMPDIR/cavestory/Cave Story (en)/." "$retro/roms/${g.system}/"
          ''
        else
          ''
            cp "${g.rom}" "$retro/roms/${g.system}/${g.romFile}"
          ''
      }
      cp "${g.snap}" "$retro/thumbnails/${g.system}/Named_Snaps/${g.title}.png"
    '') games}

    ${lib.concatStringsSep "\n" (
      lib.mapAttrsToList (system: sysGames: ''
        cp "${playlistFor system sysGames}" "$retro/playlists/${system}.csv"
      '') gamesBySystem
    )}
  ''
