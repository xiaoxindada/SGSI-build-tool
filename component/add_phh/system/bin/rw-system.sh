#!/system/bin/sh

vndk="$(getprop persist.sys.vndk)"
[ -z "$vndk" ] && vndk="$(getprop ro.vndk.version |grep -oE '^[0-9]+')"

setprop sys.usb.ffs.aio_compat true
setprop persist.adb.nonblocking_ffs false

fixSPL() {
    if [ "$(getprop ro.product.cpu.abi)" = "armeabi-v7a" ]; then
        setprop ro.keymaster.mod 'AOSP on ARM32'
    else
        setprop ro.keymaster.mod 'AOSP on ARM64'
    fi
    img="$(find /dev/block -type l -name kernel"$(getprop ro.boot.slot_suffix)" | grep by-name | head -n 1)"
    [ -z "$img" ] && img="$(find /dev/block -type l -name boot"$(getprop ro.boot.slot_suffix)" | grep by-name | head -n 1)"
    if [ -n "$img" ]; then
        #Rewrite SPL/Android version if needed
        Arelease="$(getSPL "$img" android)"
        setprop ro.keymaster.xxx.release "$Arelease"
        setprop ro.keymaster.xxx.security_patch "$(getSPL "$img" spl)"

        getprop ro.vendor.build.fingerprint | grep -qiE '^samsung/' && return 0
        for f in \
            /vendor/lib64/hw/android.hardware.keymaster@3.0-impl-qti.so /vendor/lib/hw/android.hardware.keymaster@3.0-impl-qti.so \
            /system/lib64/vndk-26/libsoftkeymasterdevice.so /vendor/bin/teed \
            /system/lib64/vndk/libsoftkeymasterdevice.so /system/lib/vndk/libsoftkeymasterdevice.so \
            /system/lib/vndk-26/libsoftkeymasterdevice.so \
            /system/lib/vndk-27/libsoftkeymasterdevice.so /system/lib64/vndk-27/libsoftkeymasterdevice.so \
	    /vendor/lib/libkeymaster3device.so /vendor/lib64/libkeymaster3device.so ; do
            [ ! -f "$f" ] && continue
            # shellcheck disable=SC2010
            ctxt="$(ls -lZ "$f" | grep -oE 'u:object_r:[^:]*:s0')"
            b="$(echo "$f" | tr / _)"

            cp -a "$f" "/mnt/phh/$b"
            sed -i \
                -e 's/ro.build.version.release/ro.keymaster.xxx.release/g' \
                -e 's/ro.build.version.security_patch/ro.keymaster.xxx.security_patch/g' \
                -e 's/ro.product.model/ro.keymaster.mod/g' \
                "/mnt/phh/$b"
            chcon "$ctxt" "/mnt/phh/$b"
            mount -o bind "/mnt/phh/$b" "$f"
        done
        if [ "$(getprop init.svc.keymaster-3-0)" = "running" ]; then
            setprop ctl.restart keymaster-3-0
        fi
        if [ "$(getprop init.svc.teed)" = "running" ]; then
            setprop ctl.restart teed
        fi
    fi
}

mkdir -p /mnt/phh/
mount -t tmpfs -o rw,nodev,relatime,mode=755,gid=0 none /mnt/phh || true
mkdir /mnt/phh/empty_dir
fixSPL

for abi in "" 64;do
    f=/vendor/lib$abi/libstagefright_foundation.so
    if [ -f "$f" ];then
        for vndk in 26 27 28 29 30;do
            mount "$f" /system/lib$abi/vndk-$vndk/libstagefright_foundation.so
        done
    fi
done
for f in /vendor/lib{,64}/hw/com.qti.chi.override.so /vendor/lib{,64}/libVD*;do
    [ ! -f $f ] && continue
    # shellcheck disable=SC2010
    ctxt="$(ls -lZ "$f" | grep -oE 'u:object_r:[^:]*:s0')"
    b="$(echo "$f" | tr / _)"

    cp -a "$f" "/mnt/phh/$b"
    sed -i \
        -e 's/ro.product.manufacturer/sys.phh.xx.manufacturer/g' \
        -e 's/ro.product.brand/sys.phh.xx.brand/g' \
        -e 's/ro.product.model/sys.phh.xx.model/g' \
        "/mnt/phh/$b"
    chcon "$ctxt" "/mnt/phh/$b"
    mount -o bind "/mnt/phh/$b" "$f"

    manufacturer=$(getprop ro.product.vendor.manufacturer)
    [ -z "$manufacturer" ] && manufacturer=$(getprop ro.product.manufacturer)
    model=$(getprop ro.product.vendor.model)
    [ -z "$model" ] && model=$(getprop ro.product.odm.model)
    setprop sys.phh.xx.manufacturer "$manufacturer"
    setprop sys.phh.xx.brand "$(getprop ro.product.vendor.brand)"
    setprop sys.phh.xx.model "$model"
done

if mount -o remount,rw /system; then
    resize2fs "$(grep ' /system ' /proc/mounts | cut -d ' ' -f 1)" || true
else
    remount system
    mount -o remount,rw /
    major="$(stat -c '%D' /.|sed -E 's/^([0-9a-f]+)([0-9a-f]{2})$/\1/g')"
    minor="$(stat -c '%D' /.|sed -E 's/^([0-9a-f]+)([0-9a-f]{2})$/\2/g')"
    mknod /dev/tmp-phh b $((0x$major)) $((0x$minor))
    resize2fs /dev/root || true
    resize2fs /dev/tmp-phh || true
fi
mount -o remount,ro /system || true
mount -o remount,ro / || true

for part in /dev/block/bootdevice/by-name/oppodycnvbk  /dev/block/platform/bootdevice/by-name/nvdata;do
    if [ -b "$part" ];then
        oppoName="$(grep -aohE '(RMX|CPH)[0-9]{4}' "$part" |head -n 1)"
        if [ -n "$oppoName" ];then
            setprop ro.build.overlay.deviceid "$oppoName"
        fi
    fi
done

if getprop ro.hardware | grep -qF qcom && [ -f /sys/class/backlight/panel0-backlight/max_brightness ] &&
    grep -qvE '^255$' /sys/class/backlight/panel0-backlight/max_brightness; then
    setprop persist.sys.qcom-brightness "$(cat /sys/class/backlight/panel0-backlight/max_brightness)"
fi

#Sony don't use Qualcomm HAL, so they don't have their mess
if getprop ro.vendor.build.fingerprint | grep -qE 'Sony/'; then
    setprop persist.sys.qcom-brightness -1
fi

# Xiaomi MiA3 uses OLED display which works best with this setting
if getprop ro.vendor.build.fingerprint | grep -iq \
    -e iaomi/laurel_sprout;then
    setprop persist.sys.qcom-brightness -1
fi

# Lenovo Z5s brightness flickers without this setting
if getprop ro.vendor.build.fingerprint | grep -iq \
    -e Lenovo/jd2019; then
    setprop persist.sys.qcom-brightness -1
fi

if getprop ro.vendor.build.fingerprint | grep -qi oneplus/oneplus6/oneplus6; then
    resize2fs /dev/block/platform/soc/1d84000.ufshc/by-name/userdata
fi

if grep -qF 'mkdir /data/.fps 0770 system fingerp' vendor/etc/init/hw/init.mmi.rc; then
    mkdir -p /data/.fps
    chmod 0770 /data/.fps
    chown system:9015 /data/.fps

    chown system:9015 /sys/devices/soc/soc:fpc_fpc1020/irq
    chown system:9015 /sys/devices/soc/soc:fpc_fpc1020/irq_cnt
fi

if getprop ro.vendor.build.fingerprint | grep -q -i \
    -e xiaomi/clover -e xiaomi/wayne -e xiaomi/sakura \
    -e xiaomi/nitrogen -e xiaomi/whyred -e xiaomi/platina \
    -e xiaomi/ysl -e nubia/nx60 -e nubia/nx61 -e xiaomi/tulip -e Redmi/begonia\
    -e xiaomi/lavender -e xiaomi/olive -e xiaomi/olivelite -e xiaomi/pine; then
    setprop persist.sys.qcom-brightness "$(cat /sys/class/leds/lcd-backlight/max_brightness)"
fi

if getprop ro.vendor.product.device |grep -iq -e RMX1801 -e RMX1803 -e RMX1807;then
    setprop persist.sys.qcom-brightness "$(cat /sys/class/leds/lcd-backlight/max_brightness)"
fi

if getprop ro.build.overlay.deviceid |grep -q -e CPH1859 -e CPH1861 -e RMX1811;then
    setprop persist.sys.qcom-brightness "$(cat /sys/class/leds/lcd-backlight/max_brightness)"
fi

if getprop ro.vendor.build.fingerprint | grep -q -i -e xiaomi/wayne -e xiaomi/jasmine; then
    setprop persist.imx376_sunny.low.lux 310
    setprop persist.imx376_sunny.light.lux 280
    setprop persist.imx376_ofilm.low.lux 310
    setprop persist.imx376_ofilm.light.lux 280
    echo "none" > /sys/class/leds/led:torch_2/trigger
fi

if getprop ro.hardware | grep -qF exynos; then
    setprop debug.sf.latch_unsignaled 1
fi

if getprop ro.product.model | grep -qF ANE; then
    setprop debug.sf.latch_unsignaled 1
fi

if getprop ro.vendor.product.device | grep -q -e nora -e rhannah; then
    setprop debug.sf.latch_unsignaled 1
fi

if getprop ro.vendor.build.fingerprint | grep -iq -e xiaomi/daisy; then
    setprop debug.sf.latch_unsignaled 1
    setprop debug.sf.enable_hwc_vds 1
fi

# This matches both Razer Phone 1 & 2
if getprop ro.vendor.build.fingerprint |grep -qE razer/cheryl;then
	setprop ro.audio.monitorRotation true
fi

if getprop ro.vendor.build.fingerprint | grep -qE '^xiaomi/wayne/wayne.*'; then
    # Fix camera on DND, ugly workaround but meh
    setprop audio.camerasound.force true
fi

if [ -n "$(getprop ro.boot.product.hardware.sku)" ] && [ -z "$(getprop ro.hw.oemName)" ];then
	setprop ro.hw.oemName "$(getprop ro.boot.product.hardware.sku)"
fi

if getprop ro.vendor.build.fingerprint | grep -qiE '^samsung/' && [ "$vndk" -ge 28 ];then
	setprop persist.sys.phh.samsung_fingerprint 0
	#obviously broken perms
	if [ "$(stat -c '%U' /sys/class/sec/tsp/cmd)" == "root" ] &&
		[ "$(stat -c '%G' /sys/class/sec/tsp/cmd)" == "root" ];then

		chcon u:object_r:sysfs_ss_writable:s0 /sys/class/sec/tsp/ear_detect_enable
		chown system /sys/class/sec/tsp/ear_detect_enable

		chcon u:object_r:sysfs_ss_writable:s0 /sys/class/sec/tsp/cmd{,_list,_result,_status}
		chown system /sys/class/sec/tsp/cmd{,_list,_result,_status}

		chown system /sys/class/power_supply/battery/wc_tx_en
		chcon u:object_r:sysfs_app_writable:s0 /sys/class/power_supply/battery/wc_tx_en
	fi

	if [ "$(stat -c '%U' /sys/class/sec/tsp/input/enabled)" == "root" ] &&
		[ "$(stat -c '%G' /sys/class/sec/tsp/input/enabled)" == "root" ];then
			chown system:system /sys/class/sec/tsp/input/enabled
			chcon u:object_r:sysfs_ss_writable:s0 /sys/class/sec/tsp/input/enabled
			setprop ctl.restart sec-miscpower-1-0
	fi
	if [ "$(stat -c '%U' /sys/class/camera/flash/rear_flash)" == "root" ] &&
		[ "$(stat -c '%G' /sys/class/camera/flash/rear_flash)" == "root" ];then
        chown system:system /sys/class/camera/flash/rear_flash
        chcon u:object_r:sysfs_camera_writable:s0 /sys/class/camera/flash/rear_flash
    fi
fi

for abi in "" 64;do
    f=/vendor/lib$abi/libstagefright_foundation.so
    if [ -f "$f" ];then
        for vndk in 26 27 28 29;do
            mount "$f" /system/lib$abi/vndk-$vndk/libstagefright_foundation.so
        done
    fi
done

setprop ro.product.first_api_level "$vndk"

if getprop ro.boot.boot_devices |grep -v , |grep -qE .;then
    ln -s /dev/block/platform/$(getprop ro.boot.boot_devices) /dev/block/bootdevice
fi

if [ -c /dev/dsm ];then
    # /dev/dsm is a magic device on Kirin chipsets that teecd needs to access.
    # Make sure that permissions are right.
    chown system:system /dev/dsm
    chmod 0660 /dev/dsm

    # The presence of /dev/dsm indicates that we have a teecd,
    # which needs /sec_storage and /data/sec_storage_data

    mkdir -p /data/sec_storage_data
    chown system:system /data/sec_storage_data
    chcon -R u:object_r:teecd_data_file:s0 /data/sec_storage_data

    if mount | grep -q " on /sec_storage " ; then
        # /sec_storage is already mounted by the vendor, don't try to create and mount it
        # ourselves. However, some devices have /sec_storage owned by root, which means that
        # the fingerprint daemon (running as system) cannot access it.
        chown -R system:system /sec_storage
        chmod -R 0660 /sec_storage
        chcon -R u:object_r:teecd_data_file:s0 /sec_storage
    else
        # No /sec_storage provided by vendor, mount /data/sec_storage_data to it
        mount /data/sec_storage_data /sec_storage
        chown system:system /sec_storage
        chcon u:object_r:teecd_data_file:s0 /sec_storage
    fi
fi

has_hostapd=false
for i in odm oem vendor product;do
    if grep -qF android.hardware.wifi.hostapd /$i/etc/vintf/manifest.xml;then
        has_hostapd=true
    fi
done

if [ "$has_hostapd" = false ];then
    setprop persist.sys.phh.system_hostapd true
fi

# SPRD GL causes crashes in system_server (not currently observed in other processes)
# Tell the system to avoid using hardware acceleration in system_server.
setprop ro.config.avoid_gfx_accel true

# Fix manual network selection with old modem
# https://github.com/LineageOS/android_hardware_ril/commit/e3d006fa722c02fc26acdfcaa43a3f3a1378eba9
if getprop ro.vendor.build.fingerprint | grep -iq \
    -e xiaomi/polaris -e xiaomi/whyred; then
    setprop persist.sys.phh.radio.use_old_mnc_format true
fi

if getprop ro.build.overlay.deviceid |grep -qE '^RMX';then
    setprop oppo.camera.packname com.oppo.camera
    setprop sys.phh.xx.brand realme
fi

if [ -f /sys/firmware/devicetree/base/oppo,prjversion ];then
    setprop ro.separate.soft $((0x$(od -w4 -j4  -An -tx1 /sys/firmware/devicetree/base/oppo,prjversion |tr -d ' ' |head -n 1)))
fi

if [ -f /proc/oppoVersion/prjVersion ];then
    setprop ro.separate.soft $(cat /proc/oppoVersion/prjVersion)
fi

echo 1 >  /proc/tfa98xx/oppo_tfa98xx_fw_update
echo 1 > /proc/touchpanel/tp_fw_update

if getprop ro.build.overlay.deviceid |grep -qE '^RMX';then
    chmod 0660 /sys/devices/platform/soc/soc:fpc_fpc1020/{irq,irq_enable,wakelock_enable}
    if [ "$(stat -c '%U' /sys/devices/platform/soc/soc:fpc_fpc1020/irq)" == "root" ] &&
		[ "$(stat -c '%G' /sys/devices/platform/soc/soc:fpc_fpc1020/irq)" == "root" ];then
            chown system:system /sys/devices/platform/soc/soc:fpc_fpc1020/{irq,irq_enable,wakelock_enable}
            setprop persist.sys.phh.fingerprint.nocleanup true
    fi
fi

if getprop ro.vendor.build.fingerprint |grep -qiE \
        -e Nokia/Plate2 \
        -e razer/cheryl ; then
    setprop media.settings.xml "/vendor/etc/media_profiles_vendor.xml"
fi
resetprop service.adb.root 0

if getprop ro.vendor.build.fingerprint |grep -qiE '^xiaomi/';then
    setprop persist.sys.phh.fod.xiaomi true
fi

if getprop ro.vendor.build.fingerprint |grep -qiE '^oneplus/';then
    setprop persist.sys.phh.fod.bbk true
fi
if getprop ro.build.overlay.deviceid |grep -qiE -e '^RMX' -e '^CPH';then
    setprop persist.sys.phh.fod.bbk true
fi

if getprop ro.build.overlay.deviceid |grep -iq -e RMX1941 -e RMX1945 -e RMX1943 -e RMX1942;then	
    setprop persist.sys.qcom-brightness "$(cat /sys/class/leds/lcd-backlight/max_brightness)"
    setprop persist.sys.phh.mainkeys 0
fi

resetprop ro.bluetooth.library_name libbluetooth.so

if getprop ro.vendor.build.fingerprint |grep -iq xiaomi/cepheus;then
    setprop ro.netflix.bsp_rev Q855-16947-1
fi

if getprop ro.vendor.build.fingerprint |grep -qi redmi/curtana;then
    setprop ro.netflix.bsp_rev Q6250-19132-1
fi

# Set props for Vsmart Live's fod
if getprop ro.vendor.build.fingerprint |grep -q vsmart/V620A_open;then
    setprop persist.sys.fp.fod.location.X_Y 447,1812
    setprop persist.sys.fp.fod.size.width_height 186,186
fi

setprop vendor.display.res_switch_en 1

if getprop ro.bionic.cpu_variant |grep -q kryo300;then
    resetprop ro.bionic.cpu_variant cortex-a75
    setprop dalvik.vm.isa.arm64.variant cortex-a75
    setprop dalvik.vm.isa.arm64.features runtime
fi
setprop ro.control_privapp_permissions disable
resetprop ro.control_privapp_permissions disable

if grep -q /mnt/vendor/persist /vendor/etc/fstab.qcom;then
    mount /mnt/vendor/persist /persist
fi

for f in $(find /sys -name fts_gesture_mode);do
    setprop persist.sys.phh.focaltech_node "$f"
done

# qssi devices audio policy
sku="$(getprop ro.boot.product.vendor.sku)"
if [ -f /vendor/etc/audio_policy_configuration_sec.xml ];then
    mount /vendor/etc/audio_policy_configuration_sec.xml /vendor/etc/audio_policy_configuration.xml
elif [ -f /vendor/etc/audio/sku_${sku}_qssi/audio_policy_configuration.xml ] && [ -f /vendor/etc/audio/sku_$sku/audio_policy_configuration.xml ];then
    mount /vendor/etc/audio/sku_${sku}_qssi/audio_policy_configuration.xml /vendor/etc/audio/sku_$sku/audio_policy_configuration.xml
elif [ -f /vendor/etc/audio/audio_policy_configuration.xml ];then
    mount /vendor/etc/audio/audio_policy_configuration.xml /vendor/etc/audio_policy_configuration.xml
elif [ -f /vendor/etc/audio_policy_configuration_base.xml ];then
    mount /vendor/etc/audio_policy_configuration_base.xml /vendor/etc/audio_policy_configuration.xml
fi

# Disable secondary watchdogs
echo -n V > /dev/watchdog1
