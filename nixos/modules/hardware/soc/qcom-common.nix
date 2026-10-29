{
  pkgs,
  ...
}:
{
  hardware.deviceTree.enable = true;

  boot = {
    initrd.availableKernelModules = [
      "mmc_block"
      "sdhci"
      "sdhci_pltfm"
      "sdhci_msm"
      "ufs_qcom"
      "ufshcd_pltfm"
      "phy_qcom_qmp_ufs"
      "phy_qcom_qusb2"
      "phy_qcom_qmp_usb"
      "dwc3"
      "dwc3_qcom"
      "msm"
      "usbhid"
    ];

    kernelModules = [
      "msm"
      "qrtr"
      "qrtr_smd"
      "qrtr_tun"
      "qcom_pil_info"
      "qcom_q6v5"
      "qcom_q6v5_mss"
      "qcom_q6v5_pas"
      "qcom_sysmon"
      "qcom_common"
      "qcom_glink_smem"
      "rpmsg_core"
      "rpmsg_char"
      "fastrpc"
    ];
  };

  environment.pathsToLink = [
    "/share/alsa/ucm2"
  ];

  environment.systemPackages = [
    pkgs.qrtr
    pkgs.rmtfs
    pkgs.tqftpserv
    pkgs.pd-mapper
    pkgs.alsa-ucm-conf
  ];

  systemd.services = {
    qrtr-ns = {
      description = "QIPCRTR Name Service";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.qrtr}/bin/qrtr-ns -f 1";
        Restart = "always";
      };
    };

    rmtfs = {
      description = "Qualcomm remotefs service";
      wantedBy = [ "multi-user.target" ];
      after = [ "qrtr-ns.service" ];
      serviceConfig = {
        ExecStart = "${pkgs.rmtfs}/bin/rmtfs -r -P -s";
        Restart = "always";
        RestartSec = 1;
      };
    };

    tqftpserv = {
      description = "QRTR TFTP service";
      wantedBy = [ "multi-user.target" ];
      after = [ "qrtr-ns.service" ];
      serviceConfig = {
        ExecStart = "${pkgs.tqftpserv}/bin/tqftpserv";
        Restart = "always";
      };
    };

    pd-mapper = {
      description = "Qualcomm PD mapper service";
      wantedBy = [ "multi-user.target" ];
      after = [ "qrtr-ns.service" ];
      serviceConfig = {
        ExecStart = "${pkgs.pd-mapper}/bin/pd-mapper";
        Restart = "always";
      };
    };
  };
}
