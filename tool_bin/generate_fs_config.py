# -*- coding: UTF-8 -*-
import sys
import re
import os
search_path=sys.argv[1]
fs_config=''
find_result=os.popen(f'find {search_path}')
def get_custom_str(pre,length):
    tmp=str(pre)
    while len(tmp)<length:
        tmp= '0'+tmp
    return tmp
for file_path in find_result.read().split('\n'):
    if file_path == '':
        continue
    # fs_config+=file_path.replace(search_path+'/','')
    statinfo = os.stat(file_path,follow_symlinks=False)

    print(file_path.replace(search_path+'/',''),end=' ')
    print(get_custom_str(statinfo.st_uid,3),end=' ')
    print(get_custom_str(statinfo.st_gid,3),end=' ')
    modeinfo=str(oct(statinfo.st_mode))
    print(get_custom_str(modeinfo[-4:],5),end=' ')
    print('')
