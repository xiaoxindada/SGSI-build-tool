<div align="center">
	<span style="font-weight: bold"> English | <a href=README.md> 中文 </a> </span>
</div>

# SGSI-build-tool
**Copyright (C) 2020 Xiaoxindada (2245062854@qq.com)  
No commercial use without my permission**
 
# This tool will be continously updated
## This tool relies on:  
* Erfan GSIs Open source project: https://github.com/erfanoabdi/ErfanGSIs  
* MToolkot: https://github.com/Nightmare-MY
* Translation fixup by @JamieHoSzeYui
* Thanks for the above list  

## Thanks rsyhan https://github.com/rsyhan for help

***For some reasons, the tool is not posted opensource on github. Decompress the .tar on releases tab.***

# Setting up the tool on Android
```
Install the apk
Place SGSI-build-tool.tar in /home/ after ubuntu is installed
Use Linux Deploy and insatll Ubuntu Arm64
```

# After ssh into ubuntu, run the following commands
```
su  
tar -xf SGSI-build-tool.tar  
cd SGSI-build-tool/10  
```

# Install binaries required by the tool(Wakelock recommended)
```
./setup.sh  
```

# Making sGSI:
```
Put the zip package into temp folder (tmp/)
 
* Make A-only:./make.sh A  
* Make AB:./make.sh AB
* You can also run ./SGSI.sh A or ./SGSI.sh AB 
If the original firmware is dynamic (as in super.img format), unzip super.img and place at the tool's directory.   
Then use ./unpacksuper.sh to unpack the super image. Pkace it to the tools subdirectory and then run ./SGSI.sh

* MThis tool supports dynamic parititons flashing (make as super image?)
use ./makesuper.sh 

For dynamic phones, contents of Patch1 and Patch2 needs to be repacked manually if you wanna add it into vendor. Repack system and vendor, use makesuper.sh to generate super image, and then flash the super image and patch3 and format data. It should boot if procedures are correct.
This tool only modifies system, you'll have to modify other partiions yourself.
This tool is a semi-automatic tool, because not all processes are ideal to be automated as they vary. If you're not familiar with their workaround, you can also skip it.
SGSI output is in SGSI Folder. You should make patch1 patch2 and patch3 manually after that.
```

# Unpack and repack scripts used in tool
```
* img Unpack: makeimg2.sh unpackimg.sh(Can be used alone Support any partition to pack and unpack)  
* super.img Unpack: makesuper.sh unpacksuper.sh  
* boot.img Unpack: makeboot.sh unpackboot.sh  
* dat/br unpack / repack: img2sdat.sh simg2sdat.sh  
* extract apex of image: apex.sh (apex flattening)  
* Partial deodex: bin/oat2dex/deodex.sh  
* ozip Decrypt: oppo_ozip  
```

# At least 30GB is recommended for this tool.

**You can run ```rm.sh``` to cleanup tool (Delete staging directories).**

**If you want to donate me please feel free ***

***QQ Group:967161723**
