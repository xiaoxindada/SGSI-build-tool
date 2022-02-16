
## SGSI flash Guide
### 作者 小新大大 at [xiaoxindada](https://github.com/xiaoxindada)

```
刷机步骤(如果你没做好不开机的准备，请不要刷入)
A-only机型可用 makemesar.zip 来刷AB的包 patch 来自 [Erfan Abdi](https://github.com/erfanoabdi)
刷入你支持pt的底包(最低要求10.0)，比如 PE，RR 等等
删除底包的vendor/overlay
解密你的data分区
解压刷机包, 刷入system.img
挂载vendor依次刷入patch补丁（动态vab分区机型请不要刷入Patch3）
如果你的机型有vbmeta.img 请刷入 Vbmeta_Patch.zip
动态vab分区机型请刷入 vendor_boot_patch.zip
删除/vendor/apex, /vendor/etc/permissions/qti_permissions.xml
刷完后格式化data或者双清
不保证所有机型能开机, 每个机型的bug也会有所不同
部分机型如果刷入patch3失败, 可用gsi的Permissiver_v4/5补丁代替 # Enable kernel permissive
如果重启到fastboot，rec， 黑屏亮灯等 可以尝试替换为底包的selinux 分区: system system_ext product
有些机型会因为缺少一些驱动或其他原因导致不开机， 请自行查看log
最后拒绝打包内置 打包狗全家火葬场
```