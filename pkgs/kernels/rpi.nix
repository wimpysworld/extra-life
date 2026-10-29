{
  stdenv,
  lib,
  fetchFromGitHub,
  buildLinux,
  linuxPackagesFor,
  ...
}@args:
let
  modDirVersion = "6.12.75";
  hash = "sha256-qrljd20n4tj/7C7gzNnxw7JIyEF2Ppf1PWm2a7vxh1w=";

  linux_rpi =
    (buildLinux (
      args
      // {
        version = "${modDirVersion}-1+rpt1";
        inherit modDirVersion;
        pname = "linux-rpi";

        src = fetchFromGitHub {
          owner = "raspberrypi";
          repo = "linux";
          rev = "89050b1059997d38d55462b323b099a6436dc10d";
          inherit hash;
        };

        defconfig = "bcm2711_defconfig";

        features = {
          efiBootStub = false;
        }
        // (args.features or { });

        structuredExtraConfig = with lib.kernel; {
          ARM64_4K_PAGES = yes;
          ARCH_BCM = yes;
          ARCH_BCM2835 = yes;
          PCIE_BRCMSTB = yes;
          MFD_RP1 = yes;
          PINCTRL_RP1 = yes;
          RP1_PIO = module;
          RESET_RASPBERRYPI = yes;
          DRM_V3D = module;
          DRM_VC4 = module;
          SND_BCM2835 = module;
          I2C_BCM2835 = module;
          PWM_BCM2835 = module;
          KEYBOARD_GPIO = module;
          SENSORS_GPIO_FAN = module;
          USB_SERIAL_CH341 = module;
        };

        isLTS = true;
        ignoreConfigErrors = true;

        extraMeta = {
          platforms = [ "aarch64-linux" ];
          maintainers = with lib.maintainers; [ flexiondotorg ];
        };
      }
      // (args.argsOverride or { })
    )).overrideAttrs
      (oldAttrs: {
        postConfigure = (oldAttrs.postConfigure or "") + ''
          sed -i $buildRoot/.config -e 's/^CONFIG_LOCALVERSION=.*/CONFIG_LOCALVERSION=""/'
          sed -i $buildRoot/include/config/auto.conf -e 's/^CONFIG_LOCALVERSION=.*/CONFIG_LOCALVERSION=""/'
        '';

        postFixup =
          (oldAttrs.postFixup or "")
          + ''
            dtbDir=${if stdenv.hostPlatform.isAarch64 then "$out/dtbs/broadcom" else "$out/dtbs"}
            rm -f $dtbDir/bcm283*.dtb
            copyDTB() {
              if [ -f "$dtbDir/$1" ]; then
                cp -v "$dtbDir/$1" "$dtbDir/$2"
              fi
            }
          ''
          + lib.optionalString stdenv.hostPlatform.isAarch64 ''
            copyDTB bcm2710-rpi-zero-2.dtb bcm2837-rpi-zero-2.dtb
            copyDTB bcm2710-rpi-zero-2-w.dtb bcm2837-rpi-zero-2-w.dtb
            copyDTB bcm2710-rpi-3-b.dtb bcm2837-rpi-3-b.dtb
            copyDTB bcm2710-rpi-3-b-plus.dtb bcm2837-rpi-3-a-plus.dtb
            copyDTB bcm2710-rpi-3-b-plus.dtb bcm2837-rpi-3-b-plus.dtb
            copyDTB bcm2710-rpi-cm3.dtb bcm2837-rpi-cm3.dtb
            copyDTB bcm2711-rpi-4-b.dtb bcm2838-rpi-4-b.dtb
          '';
      });
in
linuxPackagesFor linux_rpi
