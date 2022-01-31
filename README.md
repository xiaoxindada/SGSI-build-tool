# SGSI-build-tool
**Copyright (C) 2021 Xiaoxindada (2245062854@qq.com)
Not for commercial use without my permission**
 
## This tool partially depends on:
* Erfan GSIs: https://github.com/erfanoabdi/ErfanGSIs
* MToolkit: https://github.com/Nightmare-MY
* AndroidDump: https://github.com/AndroidDump/dumper
* Thanks for the above list

## Thanks to Jiuyu Mengzhou https://github.com/pomelohan for your help
## Thanks to Col_or https://github.com/color597 for help
## Thanks to thka2016 https://github.com/thka2016 for help

# This tool is for PC version

# Make sure to use the tool for the first time
```
tar uses:
Download this tool
Go to the directory where the tool is located and execute the following command:
su
tar -xf SGSI-build-tool-12.tar
cd SGSI-build-tool-12/12

From v12-1.2 and beyond:
su
tar -xf SGSI-build-tool-12.tar
cd SGSI-build-tool-12
```

```
GitHub:
git clone --recurse-submodules https://github.com/xiaoxindada/SGSI-build-tool.git -b 12
cd SGSI-build-tool-12
su
```

# Build SGSI with Actions:
https://github.com/xiaoxindada/SGSI-build-action


# Install tool dependent environment (recommended to hang t)
```
Test environment: Ubuntu 20.04
(Debian series Linux support, Arch series does not support the need to change the script installation dependencies by yourself)
./setup.sh
```

# Make SGSI:
```
Put the flash package in the tmp folder
make A-only: ./make.sh A
make AB: ./make.sh AB
You can also use ./SGSI.sh A or ./SGSI.sh AB alone
If the original package is super.img, put super.img in the tool root directory
Then use ./unpacksuper.sh to unpack and then throw the unpacked img into the tool change directory and execute ./SGSI.sh directly
The SGSI made by this tool also supports dynamic partition model flashing, but it needs to be packaged into super.img
Packaged with ./makesuper.sh
The content of Patch1 Patch2 needs to be packaged to vendor.img by itself, package the system vendor to generate super.img, then flash it, and then flash patch3 to format the data.
This tool only needs to manually make the Patch part of the system.img part
This tool is a semi-automatic tool, because some processing automation is not ideal and changeable, so manual is better. If you don't know the processing of these things, you can do it without processing or directly manufacture it.
The finished product is output in the SGSI folder and then you can manually manufacture Patch1 2 3

v12-1.4 began to build in the form of script passing parameters
su
Make A-only: ./make.sh -a Pixel ./tmp/redfin-ota-spp2.210219.008-3d61e529.zip --fix-bug
Make AB: ./make.sh --ab Pixel ./tmp/redfin-ota-spp2.210219.008-3d61e529.zip --fix-bug
Use SGSI.sh alone: ​​./SGSI.sh --ab Pixel --fix-bug


# Sync update tool:
  
./update.sh
```

# This tool packs and unpacks the script
```
img packing and unpacking: makeimg2.sh unpackimg.sh (can be used alone, supports packing and unpacking in any partition)
pack and unpack super.img: makesuper.sh unpacksuper.sh
Unpack boot.img: makeboot.sh unpackboot.sh
dat/br generation: img2sdat.sh simg2sdat.sh
Unzip img's apex: apex.sh (apex flattened)
Local deodex: bin/oat2dex/deodex.sh
ozip decryption: oppo_ozip
Pack and unpack dtboimg: makedtbo.sh unpackdtbo.sh
apk signing: bin/tools/signapk/signapk.sh
LG kdz unpack: unpack_kdz.sh
oppo/oneplus ops unpack: unpack_ops.sh
```

# Patch1 production method
```
1. Add OEM Vendor Blobs and overlays
2. Make specific modifications according to the log situation
3. Patch sample to upload folder (please imitate yourself)
```

**Cleanup tool Execute rm.sh to change the directory**

**If you want to donate, please feel free to QQ group: 967161723**
