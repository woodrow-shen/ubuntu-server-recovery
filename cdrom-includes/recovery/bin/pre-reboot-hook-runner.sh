#!/bin/bash -x
exec &> >(tee -a "/var/log/recovery/pre-reboot-hook-runner.log")
RECO_MNT="/run/recovery"

# Check the recovery type
for x in $(cat /proc/cmdline); do
    case ${x} in
        recoverytype=*)
            recoverytype=${x#*=}
        ;;
        recoveryos=*)
            recoveryos=${x#*=}
        ;;
     esac
done

hookdir=$(awk -F ": " '/oem-prereboot-hook-dir/{print $2 }' $RECO_MNT/recovery/config.yaml)
if [ ! -z $hookdir ]; then
    OEM_PREREBOOT_HOOK_DIR=$RECO_MNT/recovery/factory/$hookdir
fi

# The prereboot hook not needed in headless_installer
if [ ! -z $recoverytype ] && [ $recoverytype != "headless_installer" ]; then
    if [ -d $OEM_PREREBOOT_HOOK_DIR ]; then
        echo "[Factory Install Prereboot hook] Run scripts in $OEM_PREREBOOT_HOOK_DIR"
        export RECOVERYTYPE=$recoverytype
        export RECOVERYMNT=$RECO_MNT
        find "$OEM_PREREBOOT_HOOK_DIR" -type f | sort | while read -r filename;
        do
            bash "$filename" 2>&1 | tee -a /var/log/recovery/prereboot_hooks.log
            ret=${PIPESTATUS[0]}
            if [ $ret -ne 0 ];then
                echo "Hook return error in $filename , return=$ret" >> /var/log/recovery/prereboot_hooks.err
            fi
            echo "\n" >> /var/log/recovery/prereboot_hooks.log
        done
    fi
fi

# set ring LED
DEB=$RECO_MNT/recovery/factory/OEM_hi_preinst_hook
dpkg -i $DEB/intel-nuc-led-dkms_1.0_all.deb
modprobe nuc_led
cat /proc/acpi/nuc_led
echo 'ring,50,blink_fast,green' | sudo tee /proc/acpi/nuc_led > /dev/null
