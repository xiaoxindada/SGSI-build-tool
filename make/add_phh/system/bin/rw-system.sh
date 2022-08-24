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

# SPRD GL causes crashes in system_server (not currently observed in other processes)
# Tell the system to avoid using hardware acceleration in system_server.
setprop ro.config.avoid_gfx_accel true

# Fix manual network selection with old modem
# https://github.com/LineageOS/android_hardware_ril/commit/e3d006fa722c02fc26acdfcaa43a3f3a1378eba9
if getprop ro.vendor.build.fingerprint | grep -iq \
    -e xiaomi/polaris -e xiaomi/whyred; then
    setprop persist.sys.phh.radio.use_old_mnc_format true
fi

if [ -f /sys/firmware/devicetree/base/oppo,prjversion ];then
    setprop ro.separate.soft $((0x$(od -w4 -j4  -An -tx1 /sys/firmware/devicetree/base/oppo,prjversion |tr -d ' ' |head -n 1)))
fi

if [ -f /proc/oppoVersion/prjVersion ];then
    setprop ro.separate.soft $(cat /proc/oppoVersion/prjVersion)
fi

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
