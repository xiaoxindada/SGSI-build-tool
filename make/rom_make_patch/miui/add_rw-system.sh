
# Fix miui device model
manufacturer=$(getprop ro.product.system.manufacturer)
[ -z "$manufacturer" ] && manufacturer=$(getprop ro.product.odm.manufacturer)
 model=$(getprop ro.product.system.model)
[ -z "$model" ] && model=$(getprop ro.product.odm.model)
brand=$(getprop ro.product.system.brand)
[ -z "$brand" ] && model=$(getprop ro.product.odm.brand)
device=$(getprop ro.product.system.device)
[ -z "$device" ] && model=$(getprop ro.product.odm.device)
name=$(getprop ro.product.system.name)
[ -z "$name" ] && model=$(getprop ro.product.odm.name)
marketname=$(getprop ro.product.system.marketname)
[ -z "$marketname" ] && model=$(getprop ro.product.odm.marketname)
resetprop ro.product.odm.manufacturer "$manufacturer"
resetprop ro.product.odm.brand "$brand"
resetprop ro.product.odm.model "$model"
resetprop ro.product.odm.name "$name"
resetprop ro.product.odm.device "$device"
resetprop ro.product.system.manufacturer "$manufacturer"
resetprop ro.product.system.brand "$brand"
resetprop ro.product.system.model "$model"
resetprop ro.product.system.name "$name"
resetprop ro.product.system.device "$device"
resetprop ro.product.system.marketname "$marketname"
