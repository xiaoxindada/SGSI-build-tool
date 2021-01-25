<div align="center">
	<span style="font-weight: bold"> English | <a href=README.md> 中文 </a> </span>
</div>

# SGSI-build-tool
**Copyright (C) 2020 Xiaoxindada (2245062854@qq.com)  
Not for commercial use without my permission**
 
# This tool will continue to be updated  
## This tool partly relies on:  
* Erfan GSIs Open source project: https://github.com/erfanoabdi/ErfanGSIs  
* MToolkot: https://github.com/Nightmare-MY
* This Tool README.md Translated By @Priiiyo   
* Thanks for the above list  

## Thanks Nine Rain Dream Boat https://github.com/rsyhan for help

***For some reasons, the open source format does not use folder upload, tar decompression is the source code, no package***

# Make sure to use the tool for the first time
```
installation apk  
Put SGSI-build-tool.tar place ubuntu Installation folder home In the catalog  
use Linux Deploy installation Ubuntu arm64  
```

# Use ssh enter ubuntu Execute commands later
```
su  
tar -xf SGSI-build-tool.tar  
cd SGSI-build-tool/10  
```

# The installation tool depends on the environment(Suggest hanging t)
```
./setup.sh  
```

# manufacture SGSI:
```
Put the flash package to tmp In folder
 
* manufacture A-only:./make.sh A  
* manufacture AB:./make.sh AB
* Can also be used alone ./SGSI.sh A or ./SGSI.sh AB 
If the original package is super.img Put super.img Place the tool root directory   
Then use ./unpacksuper.sh Unpack and unpack it img Throw it to the tool directory and execute it directly ./SGSI.sh

* Made by this tool SGSI It also supports dynamic partition model flashing super.img
use ./makesuper.sh Bale

Patch1 Patch2 Needs to be packaged to vendor.img Put system vendor Package generation super.img Then swipe in then swipe in patch3 format data Can
This tool only makes system.img section Patch Some need to be manually  
This tool is a semi-automatic tool, because some processing automation is not ideal and changeable, so manual is better. If you don’t know how to deal with these things, you can just not process them and make them directly.  
Finished product output in SGSI Folder and then manually made Patch1 2 3 Can  
```

# This tool packs and unpacks scripts
```
* img Unpack: makeimg2.sh unpackimg.sh(Can be used alone Support any partition to pack and unpack)  
* super.img Unpack: makesuper.sh unpacksuper.sh  
* boot.img Unpack: makeboot.sh unpackboot.sh  
* dat/br Generate: img2sdat.sh simg2sdat.sh  
* Unzip img of apex: apex.sh (apex Flat)  
* Partial deodex: bin/oat2dex/deodex.sh  
* ozip Decrypt: oppo_ozip  
```

# This tool recommends the required memory space:30G

**Cleanup tool to perform more directory rm.sh Can**

**If you want to donate me please feel free QQ Group:967161723**
