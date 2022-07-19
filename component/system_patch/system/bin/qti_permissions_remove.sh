#!/system/bin/sh

mount -o remount,ro /system || true
mount -o remount,ro / || true
mount -o bind /system/etc/permissions/qti_permissions.xml /vendor/etc/permissions/qti_permissions.xml
