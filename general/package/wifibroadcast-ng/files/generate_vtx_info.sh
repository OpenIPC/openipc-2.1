#!/bin/sh

CFG_FILE="/etc/vtx_info.yaml"

### 1. Fetch SoC from fw_printenv
soc=$(fw_printenv soc 2>/dev/null | awk -F= '/soc=/ {print $2}')
[ -z "$soc" ] && soc="ssc338q"

### 2. Determine min/max bitrate based on SoC
case "$soc" in
    "ssc30kq")
        min_bitrate="2800"
        max_bitrate="18000"
        ;;
    "ssc338q")
        min_bitrate="2800"
        max_bitrate="28000"
        ;;
    *)
        # Fallback if an unexpected SoC is found
        min_bitrate="2800"
        max_bitrate="28000"
        ;;
esac

### 3. Fetch sensor from fw_printenv
sensor=$(fw_printenv sensor 2>/dev/null | awk -F= '/sensor=/ {print $2}')
[ -z "$sensor" ] && sensor="imx335"

### 4. Fetch build_option from /etc/os-release
build_option=$(awk -F= '/^BUILD_OPTION=/ {print $2}' /etc/os-release)
[ -z "$build_option" ] && build_option="fpv"

### 5. Detect Wi-Fi card from lsusb, map to known adapter
raw_driver="none"
for card in $(lsusb | awk '{print $6}' | sort | uniq); do
    case "$card" in
        "0bda:8812"|"0bda:881a"|"0b05:17d2"|"2357:0101"|"2604:0012")
            raw_driver="rtl8812au"
            break
            ;;
        "0bda:a81a")
            raw_driver="rtl8812eu"
            break
            ;;
        "0bda:f72b"|"0bda:b733")
            raw_driver="rtl8733bu"
            break
            ;;
    esac
done

### 6. Determine Wi-Fi settings based on adapter
case "$raw_driver" in
    "rtl8812au")
        min_bw="5"
        max_bw="40"
        ldpc="1"
        stbc="1"
        max_mcs="7"
        # MCS0..7 -> stepped down from 63 to 40
        mcs0_max_tx="63"
        mcs1_max_tx="60"
        mcs2_max_tx="57"
        mcs3_max_tx="54"
        mcs4_max_tx="51"
        mcs5_max_tx="48"
        mcs6_max_tx="44"
        mcs7_max_tx="40"
        ;;
    "rtl8812eu")
        min_bw="5"
        max_bw="20"
        ldpc="1"
        stbc="1"
        max_mcs="7"
        # MCS0..7 -> stepped down from 63 to 40
        mcs0_max_tx="63"
        mcs1_max_tx="60"
        mcs2_max_tx="57"
        mcs3_max_tx="54"
        mcs4_max_tx="51"
        mcs5_max_tx="48"
        mcs6_max_tx="44"
        mcs7_max_tx="40"
        ;;
    "rtl8733bu")
        min_bw="20"
        max_bw="40"
        ldpc="0"
        stbc="0"
        max_mcs="7"
        # MCS0..7 -> stepped down from 63 to 40
        mcs0_max_tx="63"
        mcs1_max_tx="60"
        mcs2_max_tx="57"
        mcs3_max_tx="54"
        mcs4_max_tx="51"
        mcs5_max_tx="48"
        mcs6_max_tx="44"
        mcs7_max_tx="40"
        ;;
    *)
        # Default if no known adapter
        raw_driver="none"
        min_bw="20"
        max_bw="20"
        ldpc="0"
        stbc="0"
        max_mcs="7"
        # All MCS min=1, max=30
        mcs0_max_tx="30"
        mcs1_max_tx="30"
        mcs2_max_tx="30"
        mcs3_max_tx="30"
        mcs4_max_tx="30"
        mcs5_max_tx="30"
        mcs6_max_tx="30"
        mcs7_max_tx="30"
        ;;
esac

# For all adapters (recognized or not), mcsN_min_tx=1
mcs0_min_tx="1"
mcs1_min_tx="1"
mcs2_min_tx="1"
mcs3_min_tx="1"
mcs4_min_tx="1"
mcs5_min_tx="1"
mcs6_min_tx="1"
mcs7_min_tx="1"

### 7. If /etc/vtx_info.yaml doesn't exist, create it; else update via yaml-cli
if [ ! -f "$CFG_FILE" ]; then
    cat <<EOF > "$CFG_FILE"
vtx_info:
  vtx_id: ff00
  build_option: $build_option
  soc: $soc
  wifi:
    wifi_adapter: $raw_driver
    min_bw: $min_bw
    max_bw: $max_bw
    ldpc: $ldpc
    stbc: $stbc
    max_mcs: $max_mcs
    tx_power:
      mcs0_min_tx: $mcs0_min_tx
      mcs0_max_tx: $mcs0_max_tx
      mcs1_min_tx: $mcs1_min_tx
      mcs1_max_tx: $mcs1_max_tx
      mcs2_min_tx: $mcs2_min_tx
      mcs2_max_tx: $mcs2_max_tx
      mcs3_min_tx: $mcs3_min_tx
      mcs3_max_tx: $mcs3_max_tx
      mcs4_min_tx: $mcs4_min_tx
      mcs4_max_tx: $mcs4_max_tx
      mcs5_min_tx: $mcs5_min_tx
      mcs5_max_tx: $mcs5_max_tx
      mcs6_min_tx: $mcs6_min_tx
      mcs6_max_tx: $mcs6_max_tx
      mcs7_min_tx: $mcs7_min_tx
      mcs7_max_tx: $mcs7_max_tx
  video:
    sensor: $sensor
    min_bitrate: $min_bitrate
    max_bitrate: $max_bitrate
EOF
    echo "Created $CFG_FILE with default/auto-detected values."
else
    echo "$CFG_FILE found. Updating values with yaml-cli..."

    echo "Updated $CFG_FILE with new auto-detected or default values via yaml-cli."
fi
