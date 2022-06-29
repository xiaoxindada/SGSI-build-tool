# SGSI-build-tool

*Copyright (C) 2021 Xiaoxindada (2245062854@qq.com)*      

## 未经过本人许可 不可进行商用

## 本工具部分依赖来自:

[Erfan GSIs](https://github.com/erfanoabdi/ErfanGSIs)  
[MToolkit](https://github.com/Nightmare-MY)  
[AndroidDump](https://github.com/AndroidDump/dumper)  

## 学分:

[九雨梦舟](https://github.com/pomelohan)  
[Col_or](https://github.com/color597)  
[thka2016](https://github.com/thka2016)  

## 本工具为PC版

## 同步或更新工具:

```
同步源码:
git clone --recurse-submodules https://github.com/xiaoxindada/SGSI-build-tool.git -b 12 SGSI-build-tool-12
cd SGSI-build-tool-12

更新最新源码:
./update.sh
```

# 使用Actions构建SGSI: [SGSI-build-action](https://github.com/xiaoxindada/SGSI-build-action)  

# 安装工具依赖环境(建议挂t):

```
测试环境： Ubuntu 20.04
（Debian系列Linux支持， Arch系列未支持 需要的自行更改脚本安装依赖

./setup.sh  
```

# 制造SGSI:

```
把刷机包放至tmp文件夹内
制造A-only:./make.sh A
制造AB:./make.sh AB
也可单独使用./SGSI.sh A 或 ./SGSI.sh AB 
如果原包是super.img 把super.img放置工具根目录
然后使用./unpacksuper.sh解包然后把解出来的img丢到工具更目录直接执行./SGSI.sh即可
本工具仅仅制作system.img部分Patch部分需要手动
本工具是半自动工具 因为有些处理自动化并不理想 多变 所以手动更好 如果你不清楚这些东西的处理 也可以不处理 直接制造也行
成品输出在SGSI文件夹 然后手动制造Patch1 2 3即可

动态分区：
这些类型的设备需要自己手动修改img把patch的内容按照补丁的规定打包入你自己的img然后刷入即可。
本工具也支持打包和解包super.img
打包: ./makesuper.sh
解包: ./unpacksuper.sh

例子:
su
制造A-only: ./make.sh -a Pixel ./tmp/redfin-ota-spp2.210219.008-3d61e529.zip --fix-bug
制造AB: ./make.sh --ab Pixel ./tmp/redfin-ota-spp2.210219.008-3d61e529.zip --fix-bug
单独使用SGSI.sh: ./SGSI.sh --ab Pixel --fix-bug
```

## 本工具其他打包解包脚本:

```

其他分区img打包解包: makeimg2.sh unpackimg.sh
boot.img/vendor_boot.img 打包解包: makeboot.sh unpackboot.sh  
dat/br生成: img2sdat.sh
解压img的apex: apex.sh (apex扁平化)  
局部deodex: bin/oat2dex/deodex.sh
ozip解密: oppo_ozip
dtbo.img打包解包： makedtbo.sh unpackdtbo.sh
apk签名： bin/tools/signapk/signapk.sh  
LG kdz解包：unpack_kdz.sh
oppo/oneplus ops解包：unpack_ops.sh  

```

# Patch1制作方法

```

Patch样本以上至 Patch_template 文件夹（请自行模仿）

```

## 清理工具环境:

```

./rm.sh
```
