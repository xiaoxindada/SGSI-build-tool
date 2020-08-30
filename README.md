# SGSI-build-tool
Copyright (C) 2020 xiaoxindada (GitHub)

未经过本人许可 不可进行商用
本工具将会持续更新
本工具部分依赖来自:
Erfan GSIs 开源项目 https://github.com/erfanoabdi/ErfanGSIs
MToolkot https://github.com/Nightmare-MY
对上述列表表示感谢
感谢 九雨梦舟 https://github.com/rsyhan 的帮助
因为部分原因 开源形式不采用文件夹上传 tar解压就是源码 没封包

# 确保首次使用工具
安装apk
把SGSI-build-tool.tar放置ubuntu安装文件夹的home目录内
使用Linux Deploy安装Ubuntu arm64
使用ssh进入ubuntu以后执行命令
su
tar -xf SGSI-build-tool.tar
cd SGSI-build-tool/10
# 安装工具依赖环境(建议挂t)
./setup.sh

# 制造SGSI:
把刷机包放至tmp文件夹内 然后执行./make.sh即可
也可单独使用./SGSI.sh
如果原包是super.img 把super.img放置工具根目录
然后使用./unpacksuper.sh解包然后把解出来的img丢到工具更目录直接执行./SGSI.sh即可

本工具制造的SGSI也支持动态分区机型刷入 不过要打包成super.img
使用./makesuper.sh打包
Patch1 Patch2的内容需要自行把他打包至vendor.img 把system vendor打包生成super.img然后刷入 然后刷入patch3格式化data即可

本工具仅仅制作system.img部分 Patch部分需要手动
本工具是半自动工具 因为有些处理自动化并不理想 多变 所以手动更好 如果你不清楚这些东西的处理 也可以不处理 直接制造也行
成品输出在SGSI文件夹 然后手动制造Patch1 2 3即可

# 本工具打包接包脚本
img打包解包: makeimg2.sh unpackimg.sh(单独可使用 支持任意分区打包解包)
super.img打包解包: makesuper.sh unpacksuper.sh
boot.img打包解包: makeboot.sh unpackboot.sh
dat/br生成: img2sdat.sh simg2sdat.sh 
解压img的apex: apex.sh (apex扁平化)
局部deodex: bin/oat2dex/deodex.sh

# 本工具推荐所需内存空间大小:30G
 清理工具 执行更目录的rm.sh即可

如果想捐赠我请随意 QQ群:967161723
