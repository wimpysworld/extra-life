{
  lib,
  fetchFromGitHub,
  linux_7_2,
  linuxPackagesFor,
  rocknix-rk3588 ? fetchFromGitHub {
    owner = "ROCKNIX";
    repo = "distribution";
    rev = "2a01f59e3329fd14923ccbe6f703cd84f0367196";
    sparseCheckout = [
      "projects/ROCKNIX/devices/RK3588"
      "projects/ROCKNIX/packages/linux/patches/mainline"
      "projects/ROCKNIX/packages/linux-drivers/generic-dsi"
      "projects/ROCKNIX/packages/audio/alsa-ucm-conf/sources/ucm2"
    ];
    hash = "sha256-EkE55LsnGQifC2j1s9wdejuqKHg2kUyT8gwe+GB9RgM=";
  },
  rocknix-joypad ? fetchFromGitHub {
    owner = "hackbar";
    repo = "rocknix-joypad";
    rev = "005033d1ddd8746c771f2c81f1174f2d892541c9";
    hash = "sha256-uprZYBDSjmSP0+MRK4e0mkRrij84zYg6eb5wtAtYsLo=";
  },
}:
let
  patchesFromDir =
    dir:
    let
      entries = builtins.readDir dir;
      names = builtins.filter (n: lib.hasSuffix ".patch" n) (builtins.attrNames entries);
      sorted = builtins.sort builtins.lessThan names;
    in
    map (n: {
      name = n;
      patch = "${dir}/${n}";
    }) sorted;

  devicePatchDir = "${rocknix-rk3588}/projects/ROCKNIX/devices/RK3588/patches/linux";

  devicePatchNames = [
    "004-battery-name.patch"
    "012-Multiaxis.patch"
  ];

  rocknixPatches =
    patchesFromDir "${rocknix-rk3588}/projects/ROCKNIX/packages/linux/patches/mainline"
    ++ map (n: {
      name = n;
      patch = "${devicePatchDir}/${n}";
    }) devicePatchNames;

  rk3588Dtbs = [
    "rk3588s-retro-lite-cm5.dtb"
    "rk3588-retro-lite-cm5.dtb"
    "rk3588s-retroled-cm5.dtb"
    "rk3588-retroled-cm5.dtb"
  ];

  linux_rk3588 =
    (linux_7_2.override {
      kernelPatches = (linux_7_2.kernelPatches or [ ]) ++ rocknixPatches;
      structuredExtraConfig = with lib.kernel; {
        RUST = lib.mkForce no;
        IIO = yes;
        DRM_PANTHOR = module;
        DRM_ROCKCHIP = module;
        DRM_PANEL_HIMAX_HX8394 = module;
        DRM_PANEL_RAYDIUM_RM67191 = module;
        ROCKCHIP_VOP2 = yes;
        ROCKCHIP_DW_HDMI_QP = yes;
        ROCKCHIP_DW_MIPI_DSI2 = yes;
        ROCKCHIP_DW_DP = yes;
        PHY_ROCKCHIP_SAMSUNG_HDPTX = module;
        PHY_ROCKCHIP_NANENG_COMBOPHY = module;
        PHY_ROCKCHIP_USBDP = module;
        PHY_ROCKCHIP_INNO_USB2 = module;
        MFD_RK8XX_SPI = yes;
        REGULATOR_RK808 = yes;
        PINCTRL_RK806 = yes;
        REGULATOR_RK860X = yes;
        POWER_RESET_GPIO = yes;
        BATTERY_CW2015 = module;
        BATTERY_MAX17042 = module;
        CHARGER_BQ257XX = module;
        CHARGER_GPIO = module;
        TYPEC_FUSB302 = module;
        TI_ADS1015 = module;
        ROCKCHIP_SARADC = module;
        JOYSTICK_ADC = module;
        KEYBOARD_ADC = module;
        KEYBOARD_GPIO = module;
        INPUT_PWM_VIBRA = module;
        PWM_GPIO = module;
        SENSORS_PWM_FAN = module;
        TOUCHSCREEN_GOODIX = module;
        INV_MPU6050_I2C = module;
        RTC_DRV_HYM8563 = module;
        SND_SOC_ROCKCHIP_I2S_TDM = module;
        SND_SOC_ES8328 = module;
        SND_SOC_ES8328_I2C = module;
        SND_SOC_WM8960 = module;
        SND_SOC_SIMPLE_AMPLIFIER = module;
        IWLWIFI = module;
        IWLMVM = module;
        BT_HCIBTUSB = module;
        BT_INTEL = module;
        BT_RTL = module;
      };
      ignoreConfigErrors = true;
      extraMeta = {
        platforms = [ "aarch64-linux" ];
        maintainers = with lib.maintainers; [ flexiondotorg ];
      };
    }).overrideAttrs
      (oldAttrs: {
        postPatch = (oldAttrs.postPatch or "") + ''
          cp -v ${rocknix-rk3588}/projects/ROCKNIX/packages/linux-drivers/generic-dsi/sources/panel-generic-dsi.c drivers/gpu/drm/panel/panel-generic-dsi.c
          if ! grep -q "panel-generic-dsi.o" drivers/gpu/drm/panel/Makefile; then
            echo "obj-y += panel-generic-dsi.o" >> drivers/gpu/drm/panel/Makefile
          fi
          cp -v ${rocknix-joypad}/rocknix-joypad.h ${rocknix-joypad}/rocknix-joypad.c drivers/input/joystick/
          if ! grep -q "rocknix-joypad.o" drivers/input/joystick/Makefile; then
            echo "obj-y += rocknix-joypad.o" >> drivers/input/joystick/Makefile
          fi
          sed -i 's/hid->vendor == 0xcafe && hid->product == 0x5004/hid->vendor == 0xcafe \&\& (hid->product == 0x5004 || hid->product == 0x5005)/' drivers/hid/hid-input.c
          patch -p1 << 'EOF'
          --- a/drivers/power/supply/max17042_battery.c
          +++ b/drivers/power/supply/max17042_battery.c
          @@ -991,6 +991,8 @@
           {
           	struct max17042_chip *chip = container_of(work,
           				struct max17042_chip, work);
          +	struct regmap *map = chip->regmap;
          +	u32 data;
           	int ret;
           
           	/* Initialize registers according to values from config_data */
          @@ -998,8 +1000,57 @@
           		ret = max17042_init_chip(chip);
           		if (ret)
           			return;
          +	} else if (chip->chip_type == MAXIM_DEVICE_TYPE_MAX17055) {
          +		u16 design_cap = 5000 * 2;
          +		u16 d_qacc = design_cap / 32;
          +		u16 d_pacc = ((int)d_qacc) * 44138 / design_cap;
          +		u16 ichgterm = 256 * 160 / 25;
          +		u16 vempty = ((3300 / 10) << 7) | (3880 / 40);
          +		u32 hibcfg;
          +
          +		dev_info(chip->dev,
          +			"New config: %d / %d / %d / %d / %d\n",
          +			(int)design_cap, (int)d_qacc, (int)d_pacc,
          +			(int)ichgterm, (int)vempty);
          +
          +		regmap_read(map, MAX17042_FSTAT, &data);
          +		while (data & 1) {
          +			msleep(10);
          +			regmap_read(map, MAX17042_FSTAT, &data);
          +		}
          +
          +		regmap_read(map, MAX17055_HibCfg, &hibcfg);
          +
          +		regmap_write(map, MAX17042_VFSOC0Enable, 0x90);
          +		regmap_write(map, MAX17055_HibCfg, 0x0);
          +		regmap_write(map, MAX17042_VFSOC0Enable, 0x0);
          +
          +		regmap_write(map, MAX17042_DesignCap, design_cap);
          +		regmap_write(map, MAX17042_dQacc, d_qacc);
          +		regmap_write(map, MAX17042_ICHGTerm, ichgterm);
          +		regmap_write(map, MAX17047_V_empty, vempty);
          +		regmap_write(map, MAX17042_dPacc, d_pacc);
          +
          +		regmap_write(map, MAX17055_ModelCfg, 0x8000);
          +
          +		regmap_read(map, MAX17055_ModelCfg, &data);
          +		while (data & 0x8000) {
          +			msleep(10);
          +			regmap_read(map, MAX17055_ModelCfg, &data);
          +		}
          +
          +		regmap_write(map, MAX17055_HibCfg, hibcfg);
          +
          +		regmap_read(map, MAX17042_STATUS, &data);
          +		regmap_write(map, MAX17042_STATUS, data & (~STATUS_POR_BIT));
           	}
           
          +	regmap_read(map, MAX17042_VCELL, &data);
          +	dev_info(chip->dev, "Voltage: %d mV\n", (data >> 7) * 10);
          +
          +	regmap_read(map, MAX17047_V_empty, &data);
          +	dev_info(chip->dev, "Vempty: %d mV\n", (data >> 7) * 10);
          +
           	chip->init_complete = 1;
           }
           
          @@ -1107,7 +1158,7 @@
           };
           
           static const struct power_supply_desc max17042_psy_desc = {
          -	.name		= "max170xx_battery",
          +	.name		= "battery",
           	.type		= POWER_SUPPLY_TYPE_BATTERY,
           	.get_property	= max17042_get_property,
           	.set_property	= max17042_set_property,
          @@ -1118,7 +1169,7 @@
           };
           
           static const struct power_supply_desc max17042_no_current_sense_psy_desc = {
          -	.name		= "max170xx_battery",
          +	.name		= "battery",
           	.type		= POWER_SUPPLY_TYPE_BATTERY,
           	.get_property	= max17042_get_property,
           	.set_property	= max17042_set_property,
          @@ -1137,6 +1188,7 @@
           	struct max17042_chip *chip;
           	int ret;
           	u32 val;
          +	u32 design_cap;
           	bool use_default_config = false;
           
           	if (!i2c_check_functionality(adapter, I2C_FUNC_SMBUS_WORD_DATA))
          @@ -1243,7 +1295,10 @@
           	chip->irq = irq;
           
           	regmap_read(chip->regmap, MAX17042_STATUS, &val);
          -	if (val & STATUS_POR_BIT) {
          +	regmap_read(chip->regmap, MAX17042_DesignCap, &design_cap);
          +	design_cap /= 2;
          +	if ((val & STATUS_POR_BIT) ||
          +	    (chip->chip_type == MAXIM_DEVICE_TYPE_MAX17055 && design_cap != 5000)) {
           		ret = devm_work_autocancel(dev, &chip->work,
           					   max17042_init_worker);
           		if (ret)
          --- a/drivers/gpu/drm/panel/panel-raydium-rm67191.c
          +++ b/drivers/gpu/drm/panel/panel-raydium-rm67191.c
          @@ -11,6 +11,7 @@
           #include <linux/media-bus-format.h>
           #include <linux/module.h>
           #include <linux/of.h>
          +#include <linux/of_device.h>
           #include <linux/regulator/consumer.h>
           
           #include <video/mipi_display.h>
          @@ -185,6 +186,41 @@
           	{0x51, 0x04},
           };
           
          +static const struct cmd_set_entry mcs_rm67199[] = {
          +	{0xFE, 0xA0}, {0x2B, 0x18}, {0xFE, 0x70}, {0x7D, 0x05},
          +	{0x5D, 0x0A}, {0x5A, 0x79}, {0x5C, 0x00}, {0x52, 0x00},
          +	{0xFE, 0xD0}, {0x40, 0x02}, {0x13, 0x40}, {0xFE, 0x40},
          +	{0x05, 0x08}, {0x06, 0x08}, {0x08, 0x08}, {0x09, 0x08},
          +	{0x0A, 0xCA}, {0x0B, 0x88}, {0x20, 0x93}, {0x21, 0x93},
          +	{0x24, 0x02}, {0x26, 0x02}, {0x28, 0x05}, {0x2A, 0x05},
          +	{0x74, 0x2F}, {0x75, 0x1E}, {0xAD, 0x00}, {0xFE, 0x60},
          +	{0x00, 0xCC}, {0x01, 0x00}, {0x02, 0x04}, {0x03, 0x00},
          +	{0x04, 0x00}, {0x05, 0x07}, {0x06, 0x00}, {0x07, 0x88},
          +	{0x08, 0x00}, {0x09, 0xCC}, {0x0A, 0x00}, {0x0B, 0x04},
          +	{0x0C, 0x00}, {0x0D, 0x00}, {0x0E, 0x05}, {0x0F, 0x00},
          +	{0x10, 0x88}, {0x11, 0x00}, {0x12, 0xCC}, {0x13, 0x0F},
          +	{0x14, 0xFF}, {0x15, 0x04}, {0x16, 0x00}, {0x17, 0x06},
          +	{0x18, 0x00}, {0x19, 0x96}, {0x1A, 0x00}, {0x24, 0xCC},
          +	{0x25, 0x00}, {0x26, 0x02}, {0x27, 0x00}, {0x28, 0x00},
          +	{0x29, 0x06}, {0x2A, 0x06}, {0x2B, 0x82}, {0x2D, 0x00},
          +	{0x2F, 0xCC}, {0x30, 0x00}, {0x31, 0x02}, {0x32, 0x00},
          +	{0x33, 0x00}, {0x34, 0x07}, {0x35, 0x06}, {0x36, 0x82},
          +	{0x37, 0x00}, {0x38, 0xCC}, {0x39, 0x00}, {0x3A, 0x02},
          +	{0x3B, 0x00}, {0x3D, 0x00}, {0x3F, 0x07}, {0x40, 0x00},
          +	{0x41, 0x88}, {0x42, 0x00}, {0x43, 0xCC}, {0x44, 0x00},
          +	{0x45, 0x02}, {0x46, 0x00}, {0x47, 0x00}, {0x48, 0x06},
          +	{0x49, 0x02}, {0x4A, 0x8A}, {0x4B, 0x00}, {0x5F, 0xCA},
          +	{0x60, 0x01}, {0x61, 0xE8}, {0x62, 0x09}, {0x63, 0x00},
          +	{0x64, 0x07}, {0x65, 0x00}, {0x66, 0x30}, {0x67, 0x80},
          +	{0x9B, 0x03}, {0xA9, 0x07}, {0xAA, 0x06}, {0xAB, 0x02},
          +	{0xAC, 0x10}, {0xAD, 0x11}, {0xAE, 0x05}, {0xAF, 0x04},
          +	{0xB0, 0x10}, {0xB1, 0x10}, {0xB2, 0x10}, {0xB3, 0x10},
          +	{0xB4, 0x10}, {0xB5, 0x10}, {0xB6, 0x10}, {0xB7, 0x10},
          +	{0xB8, 0x10}, {0xB9, 0x10}, {0xBA, 0x04}, {0xBB, 0x05},
          +	{0xBC, 0x00}, {0xBD, 0x01}, {0xBE, 0x0A}, {0xBF, 0x10},
          +	{0xC0, 0x11}, {0xFE, 0xA0}, {0x22, 0x00},
          +};
          +
           static const u32 rad_bus_formats[] = {
           	MEDIA_BUS_FMT_RGB888_1X24,
           	MEDIA_BUS_FMT_RGB666_1X18,
          @@ -205,6 +241,7 @@
           	unsigned int num_supplies;
           
           	bool prepared;
          +	bool is_rm67199;
           };
           
           static const struct drm_display_mode default_mode = {
          @@ -223,19 +260,36 @@
           		 DRM_MODE_FLAG_NVSYNC,
           };
           
          +static const struct drm_display_mode rm67199_mode = {
          +	.clock = 133711,
          +	.hdisplay = 1080,
          +	.hsync_start = 1080 + 26,
          +	.hsync_end = 1080 + 26 + 2,
          +	.htotal = 1080 + 26 + 2 + 36,
          +	.vdisplay = 1920,
          +	.vsync_start = 1920 + 8,
          +	.vsync_end = 1920 + 8 + 4,
          +	.vtotal = 1920 + 8 + 4 + 16,
          +	.width_mm = 68,
          +	.height_mm = 121,
          +	.flags = DRM_MODE_FLAG_NHSYNC |
          +		 DRM_MODE_FLAG_NVSYNC,
          +};
          +
           static inline struct rad_panel *to_rad_panel(struct drm_panel *panel)
           {
           	return container_of(panel, struct rad_panel, panel);
           }
           
          -static int rad_panel_push_cmd_list(struct mipi_dsi_device *dsi)
          +static int rad_panel_push_cmd_list(struct mipi_dsi_device *dsi,
          +				   const struct cmd_set_entry *cmd_set,
          +				   size_t count)
           {
           	size_t i;
          -	size_t count = ARRAY_SIZE(manufacturer_cmd_set);
           	int ret = 0;
           
           	for (i = 0; i < count; i++) {
          -		const struct cmd_set_entry *entry = &manufacturer_cmd_set[i];
          +		const struct cmd_set_entry *entry = &cmd_set[i];
           		u8 buffer[2] = { entry->cmd, entry->param };
           
           		ret = mipi_dsi_generic_write(dsi, &buffer, sizeof(buffer));
          @@ -317,7 +371,12 @@
           
           	dsi->mode_flags |= MIPI_DSI_MODE_LPM;
           
          -	ret = rad_panel_push_cmd_list(dsi);
          +	if (rad->is_rm67199)
          +		ret = rad_panel_push_cmd_list(dsi, mcs_rm67199,
          +					      ARRAY_SIZE(mcs_rm67199));
          +	else
          +		ret = rad_panel_push_cmd_list(dsi, manufacturer_cmd_set,
          +					      ARRAY_SIZE(manufacturer_cmd_set));
           	if (ret < 0) {
           		dev_err(dev, "Failed to send MCS (%d)\n", ret);
           		goto fail;
          @@ -328,15 +387,16 @@
           	if (ret < 0)
           		goto fail;
           
          -	/* Software reset */
          -	ret = mipi_dsi_dcs_soft_reset(dsi);
          -	if (ret < 0) {
          -		dev_err(dev, "Failed to do Software Reset (%d)\n", ret);
          -		goto fail;
          +	if (!rad->is_rm67199) {
          +		/* Software reset */
          +		ret = mipi_dsi_dcs_soft_reset(dsi);
          +		if (ret < 0) {
          +			dev_err(dev, "Failed to do Software Reset (%d)\n", ret);
          +			goto fail;
          +		}
          +		usleep_range(15000, 17000);
           	}
           
          -	usleep_range(15000, 17000);
          -
           	/* Set DSI mode */
           	ret = mipi_dsi_generic_write(dsi, (u8[]){ 0xC2, 0x0B }, 2);
           	if (ret < 0) {
          @@ -350,7 +410,7 @@
           		goto fail;
           	}
           	/* Set tear scanline */
          -	ret = mipi_dsi_dcs_set_tear_scanline(dsi, 0x380);
          +	ret = mipi_dsi_dcs_set_tear_scanline(dsi, rad->is_rm67199 ? 0x00 : 0x380);
           	if (ret < 0) {
           		dev_err(dev, "Failed to set tear scanline (%d)\n", ret);
           		goto fail;
          @@ -369,7 +429,10 @@
           		goto fail;
           	}
           
          -	usleep_range(5000, 7000);
          +	if (rad->is_rm67199)
          +		msleep(120);
          +	else
          +		usleep_range(5000, 7000);
           
           	ret = mipi_dsi_dcs_set_display_on(dsi);
           	if (ret < 0) {
          @@ -377,6 +440,9 @@
           		goto fail;
           	}
           
          +	if (rad->is_rm67199)
          +		msleep(100);
          +
           	backlight_enable(rad->backlight);
           
           	return 0;
          @@ -420,13 +486,16 @@
           static int rad_panel_get_modes(struct drm_panel *panel,
           			       struct drm_connector *connector)
           {
          +	struct rad_panel *rad = to_rad_panel(panel);
          +	const struct drm_display_mode *tmpl =
          +		rad->is_rm67199 ? &rm67199_mode : &default_mode;
           	struct drm_display_mode *mode;
           
          -	mode = drm_mode_duplicate(connector->dev, &default_mode);
          +	mode = drm_mode_duplicate(connector->dev, tmpl);
           	if (!mode) {
           		dev_err(panel->dev, "failed to add mode %ux%u@%u\n",
          -			default_mode.hdisplay, default_mode.vdisplay,
          -			drm_mode_vrefresh(&default_mode));
          +			tmpl->hdisplay, tmpl->vdisplay,
          +			drm_mode_vrefresh(tmpl));
           		return -ENOMEM;
           	}
           
          @@ -536,6 +605,7 @@
           	mipi_dsi_set_drvdata(dsi, panel);
           
           	panel->dsi = dsi;
          +	panel->is_rm67199 = of_device_is_compatible(np, "raydium,rm67199");
           
           	dsi->format = MIPI_DSI_FMT_RGB888;
           	dsi->mode_flags =  MIPI_DSI_MODE_VIDEO_HSE | MIPI_DSI_MODE_VIDEO;
          @@ -614,6 +684,7 @@
           
           static const struct of_device_id rad_of_match[] = {
           	{ .compatible = "raydium,rm67191", },
          +	{ .compatible = "raydium,rm67199", },
           	{ /* sentinel */ }
           };
           MODULE_DEVICE_TABLE(of, rad_of_match);
          --- a/drivers/input/touchscreen/goodix.c
          +++ b/drivers/input/touchscreen/goodix.c
          @@ -113,6 +113,7 @@
           	{ .id = "912", .data = &gt967_chip_data },
           	{ .id = "9147", .data = &gt967_chip_data },
           	{ .id = "967", .data = &gt967_chip_data },
          +	{ .id = "9886", .data = &gt1x_chip_data },
           	{ }
           };
           
          @@ -1556,6 +1557,7 @@
           	{ .compatible = "goodix,gt928" },
           	{ .compatible = "goodix,gt9286" },
           	{ .compatible = "goodix,gt967" },
          +	{ .compatible = "goodix,gt9886" },
           	{ }
           };
           MODULE_DEVICE_TABLE(of, goodix_of_match);
          EOF
          cat << 'EOF' > arch/arm64/boot/dts/rockchip/rk3588s-retro-lite-cm5.dtsi
          // SPDX-License-Identifier: (GPL-2.0+ OR MIT)

          #include <dt-bindings/gpio/gpio.h>
          #include <dt-bindings/input/linux-event-codes.h>
          #include <dt-bindings/interrupt-controller/irq.h>
          #include <dt-bindings/pinctrl/rockchip.h>
          #include <dt-bindings/pwm/pwm.h>
          #include <dt-bindings/soc/rockchip,vop2.h>
          #include <dt-bindings/thermal/thermal.h>
          #include "rk3588s-radxa-cm5-io.dts"

          /delete-node/ &fusb302;
          /delete-node/ &vbus5v0_typec;

          / {
          	vcc3v3_sys: regulator-3v3-sys {
          		compatible = "regulator-fixed";
          		regulator-name = "vcc3v3_sys";
          		regulator-always-on;
          		regulator-boot-on;
          		regulator-min-microvolt = <3300000>;
          		regulator-max-microvolt = <3300000>;
          		vin-supply = <&vcc12v_dcin>;
          	};

          	lcd_3v3: regulator-lcd-3v3 {
          		compatible = "regulator-fixed";
          		regulator-name = "lcd_3v3";
          		regulator-always-on;
          		regulator-boot-on;
          		regulator-min-microvolt = <3300000>;
          		regulator-max-microvolt = <3300000>;
          		vin-supply = <&vcc3v3_sys>;
          	};

          	wifi_disable: wifi-disable-gpio-regulator {
          		compatible = "regulator-fixed";
          		regulator-name = "wifi_disable";
          		enable-active-high;
          		gpio = <&gpio0 RK_PD4 GPIO_ACTIVE_HIGH>;
          		regulator-boot-on;
          		regulator-always-on;
          	};

          	bt_wake: bt-wake-gpio-regulator {
          		compatible = "regulator-fixed";
          		regulator-name = "bt_wake";
          		enable-active-high;
          		gpio = <&gpio0 RK_PC6 GPIO_ACTIVE_HIGH>;
          		regulator-boot-on;
          		regulator-always-on;
          	};

          	fan0: pwm-fan {
          		compatible = "pwm-fan";
          		#cooling-cells = <2>;
          		cooling-levels = <0 96 128 164 196 224 255>;
          		pwms = <&pwm11 0 40000 0>;
          	};

          	wm8960_mclk: wm8960-mclk {
          		compatible = "fixed-clock";
          		#clock-cells = <0>;
          		clock-frequency = <24000000>;
          	};

          	wm8960_sound: wm8960-sound {
          		status = "okay";
          		compatible = "simple-audio-card";
          		simple-audio-card,format = "i2s";
          		simple-audio-card,name = "wm8960-soundcard";
          		simple-audio-card,mclk-fs = <256>;
          		simple-audio-card,widgets =
          			"Microphone", "Mic Jack",
          			"Line", "Line In",
          			"Line", "Line Out",
          			"Speaker", "Speaker",
          			"Headphone", "Headphone Jack";
          		simple-audio-card,routing =
          			"Headphone Jack", "HP_L",
          			"Headphone Jack", "HP_R",
          			"Speaker", "SPK_LP",
          			"Speaker", "SPK_LN",
          			"LINPUT1", "Mic Jack",
          			"LINPUT3", "Mic Jack",
          			"RINPUT1", "Mic Jack",
          			"RINPUT2", "Mic Jack";
          		pinctrl-0 = <&hp_det>;
          		pinctrl-names = "default";
          		simple-audio-card,hp-det-gpios = <&gpio1 RK_PB2 GPIO_ACTIVE_LOW>;
          		simple-audio-card,hp-pin-name = "Headphone Jack";
          		sac_cpu: simple-audio-card,cpu {
          			sound-dai = <&i2s1_8ch>;
          		};
          		sac_codec: simple-audio-card,codec {
          			sound-dai = <&wm8960>;
          			clocks = <&wm8960_mclk>;
          			clock-names = "mclk";
          		};
          	};

          	bq24292i_charger: charger {
          		compatible = "gpio-charger";
          		charger-type = "usb-sdp";
          		gpios = <&gpio0 RK_PC7 GPIO_ACTIVE_LOW>;
          		charge-status-gpios = <&gpio1 RK_PA6 GPIO_ACTIVE_LOW>;
          		pinctrl-names = "default";
          		pinctrl-0 = <&bq24292i_gpio>;
          	};

          	gpio_keys: gpio-keys {
          		compatible = "gpio-keys";
          		pinctrl-names = "default";
          		pinctrl-0 = <&key_pins &lid_SW>;

          		key-vol-down {
          			label = "volume down";
          			linux,code = <KEY_VOLUMEDOWN>;
          			gpios = <&gpio4 RK_PA6 GPIO_ACTIVE_LOW>;
          		};

          		key-vol-up {
          			label = "volume up";
          			linux,code = <KEY_VOLUMEUP>;
          			gpios = <&gpio1 RK_PB1 GPIO_ACTIVE_LOW>;
          		};

          		key-power {
          			label = "lid";
          			linux,code = <SW_LID>;
          			linux,input-type = <EV_SW>;
          			gpios = <&gpio1 RK_PC6 GPIO_ACTIVE_LOW>;
          		};
          	};

          	gpio_poweroff: gpio-poweroff {
          		compatible = "gpio-poweroff";
          		pinctrl-names = "default";
          		pinctrl-0 = <&poweroff_gpio>;
          		gpios = <&gpio1 RK_PD5 GPIO_ACTIVE_LOW>;
          		timeout-ms = <3000>;
          		priority = <200>;
          	};
          };

          &i2c6 {
          	status = "okay";
          	pinctrl-names = "default";
          	pinctrl-0 = <&i2c6m3_xfer>;

          	hym8563: hym8563@51 {
          		compatible = "haoyu,hym8563";
          		reg = <0x51>;
          		#clock-cells = <0>;
          		clock-frequency = <32768>;
          		clock-output-names = "hym8563";
          		pinctrl-names = "default";
          		pinctrl-0 = <&rtc_int>;
          		interrupt-parent = <&gpio0>;
          		interrupts = <RK_PB0 IRQ_TYPE_LEVEL_LOW>;
          	};
          };

          &i2c7 {
          	status = "okay";
          	pinctrl-names = "default";
          	pinctrl-0 = <&i2c7m2_xfer>;
          	#address-cells = <1>;
          	#size-cells = <0>;

          	wm8960: wm8960@1a {
          		compatible = "wlf,wm8960";
          		reg = <0x1a>;
          		#sound-dai-cells = <0>;
          		clocks = <&wm8960_mclk>;
          		clock-names = "mclk";
          		AVDD-supply = <&vcc5v0_sys>;
          		DVDD-supply = <&vcc_3v3_s3>;
          	};

          	fuel_gauge: max17055@36 {
          		compatible = "maxim,max17055";
          		reg = <0x36>;
          		interrupt-parent = <&gpio0>;
          		interrupts = <RK_PC4 IRQ_TYPE_LEVEL_LOW>;
          		pinctrl-names = "default";
          		pinctrl-0 = <&fuel_gauge_pins>;
          		power-supplies = <&bq24292i_charger>;
          		maxim,rsns-microohm = <10000>;
          		maxim,over-heat-temp = <700>;
          		maxim,dead-volt = <3100>;
          		maxim,over-volt = <4300>;
          	};
          };

          &i2s1_8ch {
          	status = "okay";
          	rockchip,i2s-tx-route = <1 0 2 3>;
          	rockchip,i2s-rx-route = <0 1 2 3>;
          	#sound-dai-cells = <0>;
          	pinctrl-names = "default";
          	pinctrl-0 = <&i2s1m0_sclk
          		     &i2s1m0_lrck
          		     &i2s1m0_sdi0
          		     &i2s1m0_sdo1>;
          };

          &pwm11 {
          	status = "okay";
          	pinctrl-names = "default";
          	pinctrl-0 = <&pwm11m3_pins>;
          };

          &tsadc {
          	status = "okay";
          };

          &package_thermal {
          	polling-delay = <1000>;
          	polling-delay-passive = <2000>;

          	trips {
          		trip0: trip-point0 {
          			temperature = <55000>;
          			hysteresis = <5000>;
          			type = "active";
          		};
          		trip1: trip-point1 {
          			temperature = <60000>;
          			hysteresis = <5000>;
          			type = "active";
          		};
          		trip2: trip-point2 {
          			temperature = <65000>;
          			hysteresis = <5000>;
          			type = "active";
          		};
          		trip3: trip-point3 {
          			temperature = <70000>;
          			hysteresis = <5000>;
          			type = "active";
          		};
          		trip4: trip-point4 {
          			temperature = <75000>;
          			hysteresis = <5000>;
          			type = "active";
          		};
          		pcritical: trip-point5 {
          			temperature = <80000>;
          			hysteresis = <5000>;
          			type = "active";
          		};
          	};

          	cooling-maps {
          		map0 {
          			trip = <&trip0>;
          			cooling-device = <&fan0 0 1>;
          			contribution = <1024>;
          		};
          		map1 {
          			trip = <&trip1>;
          			cooling-device = <&fan0 1 2>;
          			contribution = <1024>;
          		};
          		map2 {
          			trip = <&trip2>;
          			cooling-device = <&fan0 2 3>;
          			contribution = <1024>;
          		};
          		map3 {
          			trip = <&trip3>;
          			cooling-device = <&fan0 3 4>;
          			contribution = <1024>;
          		};
          		map4 {
          			trip = <&trip4>;
          			cooling-device = <&fan0 4 5>;
          			contribution = <1024>;
          		};
          		map5 {
          			trip = <&pcritical>;
          			cooling-device = <&fan0 5 6>;
          			contribution = <1024>;
          		};
          	};
          };

          &usb_host0_xhci {
          	dr_mode = "host";
          	/delete-property/ usb-role-switch;
          	status = "okay";
          	/delete-node/ port;
          };

          &usbdp_phy0 {
          	/delete-property/ mode-switch;
          	/delete-property/ orientation-switch;
          	rockchip,dp-lane-mux = <0 1 3 2>;
          	status = "okay";
          	/delete-node/ port;
          };

          &mipidcphy1 {
          	status = "okay";
          };

          &vp3 {
          	#address-cells = <1>;
          	#size-cells = <0>;

          	vp3_out_dsi1: endpoint@ROCKCHIP_VOP2_EP_MIPI1 {
          		reg = <ROCKCHIP_VOP2_EP_MIPI1>;
          		remote-endpoint = <&dsi1_in_vp3>;
          	};
          };

          &dsi1_in {
          	dsi1_in_vp3: endpoint {
          		remote-endpoint = <&vp3_out_dsi1>;
          	};
          };

          &dsi1_out {
          	dsi1_out_panel: endpoint {
          		remote-endpoint = <&panel_in_dsi1>;
          	};
          };

          &pinctrl {
          	headphone {
          		hp_det: hp-det {
          			rockchip,pins = <1 RK_PB2 RK_FUNC_GPIO &pcfg_pull_up>;
          		};
          	};

          	hym8563 {
          		rtc_int: rtc-int {
          			rockchip,pins = <0 RK_PB0 RK_FUNC_GPIO &pcfg_pull_up>;
          		};
          	};

          	dsi1-lcd {
          		dsi1_lcd_rst_gpio: dsi1-lcd-rst-gpio {
          			rockchip,pins = <1 RK_PB0 RK_FUNC_GPIO &pcfg_pull_up>;
          		};
          	};

          	touch {
          		touch_gpio: touch-gpio {
          			rockchip,pins =
          				<1 RK_PB4 RK_FUNC_GPIO &pcfg_pull_up>,
          				<1 RK_PB5 RK_FUNC_GPIO &pcfg_pull_none>;
          		};
          	};

          	bq24292i {
          		bq24292i_gpio: bq24292i-gpio {
          			rockchip,pins =
          				<0 RK_PC7 RK_FUNC_GPIO &pcfg_pull_up>,
          				<1 RK_PA6 RK_FUNC_GPIO &pcfg_pull_up>;
          		};
          	};

          	gpio-key {
          		key_pins: key-pins {
          			rockchip,pins =
          				<4 RK_PA6 RK_FUNC_GPIO &pcfg_pull_up>,
          				<1 RK_PB1 RK_FUNC_GPIO &pcfg_pull_up>;
          		};

          		lid_SW: lid-sw {
          			rockchip,pins = <1 RK_PC6 RK_FUNC_GPIO &pcfg_pull_up>;
          		};
          	};

          	poweroff {
          		poweroff_gpio: poweroff-gpio {
          			rockchip,pins = <1 RK_PD5 RK_FUNC_GPIO &pcfg_pull_up>;
          		};
          	};

          	gauge {
          		fuel_gauge_pins: fuel-gauge-pins {
          			rockchip,pins = <0 RK_PC4 RK_FUNC_GPIO &pcfg_pull_none>;
          		};
          	};
          };
          EOF
          cat << 'EOF' > arch/arm64/boot/dts/rockchip/rk3588s-retro-lite-cm5.dts
          // SPDX-License-Identifier: (GPL-2.0+ OR MIT)
          /dts-v1/;

          #include "rk3588s-retro-lite-cm5.dtsi"

          / {
          	model = "Retro Lite CM5";
          	compatible = "retro-lite,cm5", "radxa,cm5", "rockchip,rk3588s", "rockchip,rk3588";

          	dsi1_backlight: dsi1-backlight {
          		status = "okay";
          		compatible = "pwm-backlight";
          		pwms = <&pwm0 0 25000 PWM_POLARITY_INVERTED>;
          		brightness-levels = <
          			0   6   6   6   6   6   6   6
          			6   6   6   6   6   6   6   6
          			6   6   6   6   6   6   6   6
          			6   6   6   6   6   6   6   6
          			6   7   7   7   7   7   7   7
          			7   7   7   7   7   7   7   7
          			7   7   7   8   8   8   8   8
          			8   8   8   8   8   8   8   8
          			8   9   9   9   9   9   9   9
          			9   9   9  10  10  10  10  10
          			10  10  10  11  11  11  11  11
          			11  11  12  12  12  12  12  12
          			12  13  13  13  13  13  14  14
          			14  14  14  15  15  15  15  16
          			16  16  16  17  17  17  17  18
          			18  18  19  19  19  19  20  20
          			20  21  21  22  22  22  23  23
          			23  24  24  25  25  26  26  27
          			27  28  28  29  29  30  30  31
          			31  32  33  33  34  34  35  36
          			36  37  38  39  39  40  41  42
          			42  43  44  45  46  47  48  49
          			50  51  52  53  54  55  56  57
          			58  59  61  62  63  64  66  67
          			68  70  71  73  74  76  77  79
          			80  82  84  86  87  89  91  93
          			95  97  99 101 103 105 107 110
          			112 114 117 119 122 124 127 130
          			132 135 138 141 144 147 150 153
          			156 160 163 167 170 174 177 181
          			185 189 193 197 201 206 210 215
          			219 224 229 234 239 244 249 255
          		>;
          		default-brightness-level = <200>;
          	};
          };

          &pwm0 {
          	status = "okay";
          	pinctrl-names = "default";
          	pinctrl-0 = <&pwm0m1_pins>;
          };

          &i2c8 {
          	status = "okay";
          	pinctrl-names = "default";
          	pinctrl-0 = <&i2c8m2_xfer>;
          	clock-frequency = <400000>;
          	#address-cells = <1>;
          	#size-cells = <0>;

          	gt911: gt911@14 {
          		status = "okay";
          		compatible = "goodix,gt911";
          		reg = <0x14>;
          		pinctrl-names = "default";
          		pinctrl-0 = <&touch_gpio>;
          		interrupt-parent = <&gpio1>;
          		interrupts = <RK_PB5 IRQ_TYPE_EDGE_FALLING>;
          		irq-gpios = <&gpio1 RK_PB5 IRQ_TYPE_EDGE_FALLING>;
          		reset-gpios = <&gpio1 RK_PB4 GPIO_ACTIVE_HIGH>;
          		AVDD28-supply = <&lcd_3v3>;
          		VDDIO-supply = <&lcd_3v3>;
          		touchscreen-size-x = <720>;
          		touchscreen-size-y = <1280>;
          	};
          };

          &dsi1 {
          	status = "okay";
          	#address-cells = <1>;
          	#size-cells = <0>;

          	dsi1_panel: panel@0 {
          		status = "okay";
          		compatible = "rocknix,generic-dsi";
          		reg = <0>;
          		backlight = <&dsi1_backlight>;
          		vdd-supply = <&lcd_3v3>;
          		iovcc-supply = <&lcd_3v3>;
          		reset-gpios = <&gpio1 RK_PB0 GPIO_ACTIVE_LOW>;
          		rotation = <270>;
          		pinctrl-names = "default";
          		pinctrl-0 = <&dsi1_lcd_rst_gpio>;

          		panel_description =
          			"G size=68,121 delays=120,120,120,120,20 format=rgb888 lanes=4 flags=0xe03",
          			"M clock=59603 horizontal=720,20,6,10 vertical=1280,20,4,10 default=1",
          			"I seq=ff988103",
          			"I seq=0100", "I seq=0200", "I seq=0372", "I seq=0400",
          			"I seq=0500", "I seq=0609", "I seq=0700", "I seq=0800",
          			"I seq=0901", "I seq=0a00", "I seq=0b00", "I seq=0c01",
          			"I seq=0d00", "I seq=0e00", "I seq=0f00", "I seq=1000",
          			"I seq=1100", "I seq=1200", "I seq=1300", "I seq=1400",
          			"I seq=1500", "I seq=1600", "I seq=1700", "I seq=1800",
          			"I seq=1900", "I seq=1a00", "I seq=1b00", "I seq=1c00",
          			"I seq=1d00", "I seq=1e40", "I seq=1f80", "I seq=2005",
          			"I seq=2102", "I seq=2200", "I seq=2300", "I seq=2400",
          			"I seq=2500", "I seq=2600", "I seq=2700", "I seq=2833",
          			"I seq=2902", "I seq=2a00", "I seq=2b00", "I seq=2c00",
          			"I seq=2d00", "I seq=2e00", "I seq=2f00", "I seq=3000",
          			"I seq=3100", "I seq=3200", "I seq=3300", "I seq=3404",
          			"I seq=3500", "I seq=3600", "I seq=3700", "I seq=383c",
          			"I seq=3900", "I seq=3a40", "I seq=3b40", "I seq=3c00",
          			"I seq=3d00", "I seq=3e00", "I seq=3f00", "I seq=4000",
          			"I seq=4100", "I seq=4200", "I seq=4300", "I seq=4400",
          			"I seq=5001", "I seq=5123", "I seq=5245", "I seq=5367",
          			"I seq=5489", "I seq=55ab", "I seq=5601", "I seq=5723",
          			"I seq=5845", "I seq=5967", "I seq=5a89", "I seq=5bab",
          			"I seq=5ccd", "I seq=5def", "I seq=5e11", "I seq=5f01",
          			"I seq=6000", "I seq=6115", "I seq=6214", "I seq=630e",
          			"I seq=640f", "I seq=650c", "I seq=660d", "I seq=6706",
          			"I seq=6802", "I seq=6902", "I seq=6a02", "I seq=6b02",
          			"I seq=6c02", "I seq=6d02", "I seq=6e07", "I seq=6f02",
          			"I seq=7002", "I seq=7102", "I seq=7202", "I seq=7302",
          			"I seq=7402", "I seq=7501", "I seq=7600", "I seq=7714",
          			"I seq=7815", "I seq=790e", "I seq=7a0f", "I seq=7b0c",
          			"I seq=7c0d", "I seq=7d06", "I seq=7e02", "I seq=7f07",
          			"I seq=8002", "I seq=8102", "I seq=8202", "I seq=8302",
          			"I seq=8407", "I seq=8502", "I seq=8602", "I seq=8702",
          			"I seq=8802", "I seq=8902", "I seq=8a02",
          			"I seq=ff988104",
          			"I seq=6c15", "I seq=6e2a", "I seq=6f33", "I seq=3a94",
          			"I seq=8d1a", "I seq=87ba", "I seq=2676", "I seq=b2d1",
          			"I seq=b506",
          			"I seq=ff988101",
          			"I seq=220a", "I seq=3100", "I seq=5398", "I seq=5598",
          			"I seq=50ae", "I seq=51ae", "I seq=6028",
          			"I seq=a00f", "I seq=a11b", "I seq=a228", "I seq=a312",
          			"I seq=a415", "I seq=a528", "I seq=a61b", "I seq=a71e",
          			"I seq=a879", "I seq=a91b", "I seq=aa27", "I seq=ab69",
          			"I seq=ac19", "I seq=ad18", "I seq=ae4c", "I seq=af21",
          			"I seq=b028", "I seq=b152", "I seq=b265", "I seq=b33f",
          			"I seq=c004", "I seq=c11b", "I seq=c227", "I seq=c313",
          			"I seq=c415", "I seq=c528", "I seq=c61c", "I seq=c71e",
          			"I seq=c879", "I seq=c91a", "I seq=ca27", "I seq=cb69",
          			"I seq=cc1a", "I seq=cd18", "I seq=ce4c", "I seq=cf21",
          			"I seq=d027", "I seq=d152", "I seq=d265", "I seq=d33f",
          			"I seq=ff988100",
          			"I seq=3500", "I seq=3a70",
          			"I seq=11 wait=78",
          			"I seq=29 wait=14";

          		port {
          			panel_in_dsi1: endpoint {
          				remote-endpoint = <&dsi1_out_panel>;
          			};
          		};
          	};
          };
          EOF
          cp -v arch/arm64/boot/dts/rockchip/rk3588s-retro-lite-cm5.dts arch/arm64/boot/dts/rockchip/rk3588-retro-lite-cm5.dts
          cat << 'EOF' > arch/arm64/boot/dts/rockchip/rk3588s-retroled-cm5.dts
          // SPDX-License-Identifier: (GPL-2.0+ OR MIT)
          /dts-v1/;

          #include "rk3588s-retro-lite-cm5.dtsi"

          / {
          	model = "RetrOLED CM5";
          	compatible = "retroled,cm5", "radxa,cm5", "rockchip,rk3588s", "rockchip,rk3588";
          };

          &i2c8 {
          	status = "okay";
          	pinctrl-names = "default";
          	pinctrl-0 = <&i2c8m2_xfer>;
          	clock-frequency = <400000>;
          	#address-cells = <1>;
          	#size-cells = <0>;

          	gt9886: gt9886@5d {
          		status = "okay";
          		compatible = "goodix,gt9886", "goodix,gt911";
          		reg = <0x5d>;
          		pinctrl-names = "default";
          		pinctrl-0 = <&touch_gpio>;
          		interrupt-parent = <&gpio1>;
          		interrupts = <RK_PB5 IRQ_TYPE_EDGE_FALLING>;
          		irq-gpios = <&gpio1 RK_PB5 IRQ_TYPE_EDGE_FALLING>;
          		reset-gpios = <&gpio1 RK_PB4 GPIO_ACTIVE_HIGH>;
          		AVDD28-supply = <&lcd_3v3>;
          		VDDIO-supply = <&lcd_3v3>;
          		touchscreen-size-x = <1080>;
          		touchscreen-size-y = <1920>;
          	};
          };

          &dsi1 {
          	status = "okay";
          	#address-cells = <1>;
          	#size-cells = <0>;

          	dsi1_panel: panel@0 {
          		status = "okay";
          		compatible = "raydium,rm67199";
          		reg = <0>;
          		v3p3-supply = <&lcd_3v3>;
          		v1p8-supply = <&lcd_3v3>;
          		reset-gpios = <&gpio1 RK_PB0 GPIO_ACTIVE_LOW>;
          		dsi-lanes = <4>;
          		video-mode = <2>;
          		rotation = <270>;
          		pinctrl-names = "default";
          		pinctrl-0 = <&dsi1_lcd_rst_gpio>;

          		port {
          			panel_in_dsi1: endpoint {
          				remote-endpoint = <&dsi1_out_panel>;
          			};
          		};
          	};
          };
          EOF
          cp -v arch/arm64/boot/dts/rockchip/rk3588s-retroled-cm5.dts arch/arm64/boot/dts/rockchip/rk3588-retroled-cm5.dts
          if ! grep -q "rk3588s-retro-lite-cm5.dtb" arch/arm64/boot/dts/rockchip/Makefile; then
            echo "dtb-\$(CONFIG_ARCH_ROCKCHIP) += ${lib.concatStringsSep " " rk3588Dtbs}" >> arch/arm64/boot/dts/rockchip/Makefile
          fi
        '';
      });
in
linuxPackagesFor linux_rk3588
