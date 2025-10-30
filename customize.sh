LATESTARTSERVICE=true

ui_print() {
  echo "$1"
}

ui_print ""
ui_print "🔍 Checking device compatibility..."
ui_print "────────────────────────────────────────────"
CHIPSET=$(getprop ro.board.platform)
HARDWARE=$(getprop ro.hardware)
PRODUCT_BOARD=$(getprop ro.product.board)

ui_print "• Detected Platform: $CHIPSET"
ui_print "• Hardware: $HARDWARE"
ui_print "• Board: $PRODUCT_BOARD"

HELIO_G99_DETECTED=false

# Check platform info for MT6789 (Helio G99)
if echo "$CHIPSET" | grep -qi "mt6789\|g99"; then
    HELIO_G99_DETECTED=true
elif echo "$HARDWARE" | grep -qi "mt6789\|g99"; then
    HELIO_G99_DETECTED=true
elif echo "$PRODUCT_BOARD" | grep -qi "mt6789\|g99"; then
    HELIO_G99_DETECTED=true
fi

# Additional checks if not detected yet
if [ "$HELIO_G99_DETECTED" = false ]; then
    # Check CPU info
    if [ -f /proc/cpuinfo ]; then
        if grep -qi "mt6789\|helio.*g99" /proc/cpuinfo; then
            HELIO_G99_DETECTED=true
        fi
    fi
    
    # Check kernel version
    if [ -f /proc/version ]; then
        if grep -qi "mt6789\|g99" /proc/version; then
            HELIO_G99_DETECTED=true
        fi
    fi
    
    # Check through additional system properties
    SoC=$(getprop ro.soc.model 2>/dev/null)
    if echo "$SoC" | grep -qi "mt6789\|g99"; then
        HELIO_G99_DETECTED=true
    fi
fi

sleep 1

if [ "$HELIO_G99_DETECTED" = true ]; then
    ui_print "✅ Helio G99 chipset detected!"
    ui_print "✅ Device is compatible. Proceeding with installation..."
else
    ui_print "❌ INCOMPATIBLE DEVICE DETECTED!"
    ui_print "❌ This module is designed specifically for Helio G99 chipset"
    ui_print "❌ Your device chipset: $CHIPSET"
    ui_print "❌ Installation aborted for device safety"
    ui_print ""
    ui_print "🚫 Module installation cancelled"
    exit 1
fi

sleep 1

print_border() {
  ui_print "────────────────────────────────────────────"
}

ui_print ""
ui_print "📦 Module Information"
print_border
sleep 0.5
ui_print "• Name         : $MODNAME"
sleep 0.5
ui_print "• Version      : $(grep "^version=" "$MODPATH/module.prop" | cut -d '=' -f2)"
sleep 0.5
ui_print "• Author       : SuperrZiroo"

ui_print ""
ui_print "📱 Device Information"
print_border
sleep 0.5
ui_print "• Chipset       : $(getprop ro.board.platform)"
sleep 0.5
ui_print "• Model         : $(getprop ro.product.model)"
sleep 0.5
ui_print "• Manufacturer  : $(getprop ro.product.manufacturer)"
sleep 0.5
ui_print "• Device        : $(getprop ro.product.device)"
sleep 0.5
ui_print "• Android       : $(getprop ro.build.version.release) (API $(getprop ro.build.version.sdk))"
sleep 0.5
ui_print "• Kernel        : $(uname -r)"
sleep 0.5
ui_print "• SELinux Mode  : $(getenforce 2>/dev/null)"

ui_print ""
ui_print "💾 Memory & Storage"
print_border
sleep 0.5
TOTAL_RAM=$(free -m | awk '/Mem:/ {print $2}')
ui_print "• Total RAM       : ${TOTAL_RAM} MB"
sleep 0.5
STORAGE_INFO=$(df -h /data | awk 'NR==2 {print $2 " total, " $4 " free"}')
ui_print "• Internal Storage: $STORAGE_INFO"

ui_print ""
ui_print "🔓 Root & Security Status"
print_border

ROOT_METHODS=""

if [ -f /sbin/magisk ] || command -v magisk >/dev/null 2>&1; then
  MAGISK_VER=$(magisk -v 2>/dev/null || echo "Magisk Detected")
  ROOT_METHODS="${ROOT_METHODS}Magisk ($MAGISK_VER)\n"
fi

if [ -f /data/adb/ksu/bin/ksud ] || command -v ksud >/dev/null 2>&1; then
  if command -v ksud >/dev/null 2>&1; then
    KSU_VER=$(ksud --version 2>/dev/null | head -n1)
  else
    KSU_VER="Unknown Version"
  fi
  ROOT_METHODS="${ROOT_METHODS}KernelSU ($KSU_VER)\n"
fi

if getprop | grep -q "sukisu" || [ -f /dev/sukisu_enable ] || [ -d /sukisu ] || getprop | grep -qi 'suki.su'; then
  SUKI_VER=$(getprop suki.su.version 2>/dev/null)
  [ -z "$SUKI_VER" ] && SUKI_VER="Detected"
  ROOT_METHODS="${ROOT_METHODS}SukiSU ($SUKI_VER)\n"
fi

if [ -f /data/adb/apatch/.apatch ]; then
  ROOT_METHODS="${ROOT_METHODS}APatch (Detected)\n"
fi

if [ -z "$ROOT_METHODS" ]; then
  if command -v su >/dev/null 2>&1; then
    ROOT_METHODS="${ROOT_METHODS}Root Access Detected (Unknown Method)\n"
  else
    ROOT_METHODS="No Root Access\n"
  fi
fi

sleep 0.5
ui_print "• Root Method(s) :"
echo -e "$ROOT_METHODS" | while read line; do
  [ -n "$line" ] && ui_print "   ✓ $line"
done

ui_print ""
ui_print "⚠️ WARNING: Modify performance at your own risk!"
sleep 0.5
ui_print "⏳ installing performance tweaks..."

ui_print "⚙️ Setting Permissions..."
unzip -o "$ZIPFILE" 'Thermods/*' -d $MODPATH >&2
set_perm_recursive $MODPATH/Thermods 0 0 0755 0644
set_perm_recursive $MODPATH 0 0 0755 0755

find /system/vendor/ -name "*thermal*" -type f -print0 | while IFS= read -r -d '' nama;do if [[ "$nama" == *.conf ]];then mkdir -p "$MODPATH/$nama";rmdir "$MODPATH/$nama";touch "$MODPATH/$nama";fi;done >/dev/null 2>&1

ui_print "✅ $MODNAME Module Installed!"
sleep 0.5
ui_print "🔁 Please reboot to break your phone limits"