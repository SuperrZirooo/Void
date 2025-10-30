while [ -z "$(getprop sys.boot_completed)" ]; do
sleep 10
done
sh /data/adb/modules/ThermodsG99/Thermods/Thermods.sh