#!/system/bin/sh

# Function to safely write to sysfs
tweak() {
	if [ -f "$2" ]; then
		chmod 644 "$2" >/dev/null 2>&1
		echo "$1" > "$2" 2>/dev/null
		chmod 444 "$2" >/dev/null 2>&1
	fi
}

# Set trip point temperatures to maximum
tweak 999999999 /sys/class/thermal/thermal_zone0/trip_point_0_temp
tweak 999999999 /sys/class/thermal/thermal_zone9/trip_point_0_temp

# Enable thermal tracing
echo "1" > /sys/kernel/thermal_trace/enable 2>/dev/null
echo "1" > /sys/kernel/thermal_trace/hr_enable 2>/dev/null
echo "1700000" > /sys/kernel/thermal_trace/hr_period 2>/dev/null

# Stop thermal services - First attempt
stop thermal 2>/dev/null
stop thermal_manager 2>/dev/null
stop thermald 2>/dev/null
stop thermalloadalgod 2>/dev/null
stop thermal_core 2>/dev/null
stop vendor.thermal-hal-2-0.mtk 2>/dev/null
stop vendor.mtk_thermal_2_0 2>/dev/null
stop mi_thermald 2>/dev/null

sleep 2

# Stop thermal services - Second attempt using setprop
for service in thermal thermal_manager thermald thermalloadalgod thermal_core vendor.thermal-hal-2-0.mtk vendor.mtk_thermal_2_0 mi_thermald; do
    setprop ctl.stop "$service" 2>/dev/null
done

sleep 2

# Reset thermal-related properties
resetprop -n dalvik.vm.dexopt.thermal-cutoff 0
resetprop -n ro.boottime.thermal 0
resetprop -n ro.boottime.thermal_core 0
resetprop -n ro.boottime.thermald 0
resetprop -n ro.boottime.thermal_manager 0
resetprop -n ro.boottime.thermalloadalgod 0
resetprop -n ro.boottime.vendor.thermal-hal-2-0.mtk 0
resetprop -n ro.dar.thermal_core.support 0
resetprop -n ro.vendor.mtk_thermal_2_0 0
resetprop -n ro.vendor.tran.hbm.thermal.temp.clr 99999
resetprop -n ro.vendor.tran.hbm.thermal.temp.trig 99999
resetprop -n debug.thermal.throttle.support "no"

# Configure Thermal Zone integral_cutoff
for zone in /sys/class/thermal/thermal_zone*/integral_cutoff; do
    tweak 60000 "$zone"
done

# Configure Thermal Zone policy
for zone in /sys/class/thermal/thermal_zone*/policy; do
    tweak "user_space" "$zone"
done

# Configure Thermal Zone k_d parameter
for zone in /sys/class/thermal/thermal_zone*/k_d; do
    tweak 4000 "$zone"
done

# Configure Thermal Zone k_i parameter
for zone in /sys/class/thermal/thermal_zone*/k_i; do
    tweak 4000 "$zone"
done

# Configure Thermal Zone k_po parameter
for zone in /sys/class/thermal/thermal_zone*/k_po; do
    tweak 5000 "$zone"
done

# Configure Thermal Zone k_pu parameter
for zone in /sys/class/thermal/thermal_zone*/k_pu; do
    tweak 4000 "$zone"
done

# Configure Thermal Zone sustainable_power
for zone in /sys/class/thermal/thermal_zone*/sustainable_power; do
    tweak 10000 "$zone"
done

# Enable charger performance mode
echo "1" > /sys/devices/system/cpu/perf/charger_enable 2>/dev/null

# Final cleanup - stop all thermal-related services
for service in $(getprop | grep thermal | cut -f1 -d] | cut -f2 -d[ | grep -F init.svc. | sed 's/init.svc.//'); do
    stop "$service" 2>/dev/null
done

sleep 1

for prop in $(getprop | grep thermal | cut -f1 -d] | cut -f2 -d[ | grep -F init.svc.); do
    setprop "$prop" stopped 2>/dev/null
done

for prop in $(getprop | grep thermal | cut -f1 -d] | cut -f2 -d[ | grep -F init.svc_); do
    setprop "$prop" "" 2>/dev/null
done