# My Framework setup

machine_id := `cat /etc/machine-id`

_help:
    @just -f {{ justfile() }} --choose

remove-old-kernels:
    sudo dnf remove $(dnf rq --installonly --latest-limit=-1)

tpm-luks-unlock:
    @echo "Setting up TPM and unlocking LUKS"
    sudo systemd-cryptenroll --wipe-slot=tpm2 /dev/nvme0n1p3
    sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7+14

# add-negativo-multimedia:
#     sudo dnf config-manager addrepo --from-repofile=https://negativo17.org/repos/fedora-multimedia.repo

install-displaylink:
    # install displaylink from https://github.com/displaylink-rpm/displaylink-rpm/releases
    # now using copr instead
    sudo dnf copr enable crashdummy/Displaylink
    mokutil --sb-state
    [ ! -f /var/lib/dkms/mok.pub ] && sudo dkms generate_mok
    sudo mokutil --import /var/lib/dkms/mok.pub
    sudo dkms autoinstall
    sudo modinfo evdi

    # negativo17 repo for displaylink is not compatible with rpmfusion
    # sudo dnf install -y displaylink
    # Import public key for akmods
    # sudo mokutil --import /etc/pki/akmods/certs/public_key.der
    # sudo akmods --force --rebuild --akmod evdi

install-fzf:
    sudo dnf install -y fzf
    echo -e "\n. <(fzf --bash)" >> ~/.bashrc

omnissa-smartcard:
    # download from https://customerconnect.omnissa.com/downloads/info/slug/desktop_end_user_computing/omnissa_horizon_clients/8
    # make links for smartcard auth in horizon client
    sudo mkdir -p /usr/lib/omnissa/horizon/pkcs11/
    sudo ln -s /usr/lib64/pkcs11/opensc-pkcs11.so /usr/lib/omnissa/horizon/pkcs11/libopenscpkcs11.so

# make libvirt client tools use system libvirt
libvirt-system:
    sudo usermod -aG libvirt $(whoami)
    mkdir -p ~/.config/libvirt
    echo 'uri_default = "qemu:///system"' >> ~/.config/libvirt/libvirt.conf

# Upgrade system using dnf - edit as needed for version
dnf-system-upgrade version:
    sudo dnf upgrade --refresh -y
    sudo dnf install dnf-plugin-system-upgrade
    sudo dnf system-upgrade download --releasever={{ version }}
    sudo dnf offline reboot

    # 41->42 fix missing iptables and resulting docker error
    sudo dnf reinstall iptables-nft -y

upgrade:
    # upgrade stuff
    brew upgrade
    sudo dnf upgrade -y
    sudo flatpak update -y

upgrade-and-poweroff:
    # upgrade stuff and power off
    sudo flatpak update -y
    brew upgrade
    sudo dnf offline-upgrade download -y
    sudo dnf offline-upgrade reboot --poweroff -y
    sudo shutdown -s +1

# switch-to-systemd-boot:
#     # dont do this
#     exit 1
#     # remove grub from protected
#     sudo rm -f /etc/dnf/protected.d/grub*
#     sudo rm -f /etc/dnf/protected.d/shim.conf
#     #uninstall grub
#     sudo dnf remove -y grubby grub2\* memtest86\* && sudo rm -rf /boot/grub2 && sudo rm -rf /boot/loader
#     # install systemd-boot
#     sudo dnf install systemd-boot-unsigned sdubby
#     # Copy your current cmdline options just in case
#     cat /proc/cmdline | cut -d ' ' -f 2- | sudo tee /etc/kernel/cmdline
#     # Install systemd-boot
#     sudo bootctl install
#     # Now, reinstall and regenerate the current kernel entry
#     sudo kernel-install add $(uname -r) /lib/modules/$(uname -r)/vmlinuz
#     # Reinstall the kernel again, just in case we need to trigger some hooks
#     sudo dnf reinstall -y kernel-core

setup-systemd-secure-boot:
    # dont do this
    exit 1
    sudo dnf install sbctl mokutil -y
    # Generate a new key
    sudo sbctl create-keys
    # Enroll the key
    sudo sbctl enroll-keys
    # Sign the kernel
    sudo sbctl sign /boot/vmlinuz-$(uname -r)

enable-luks-discard:
    # LUKS SSD performance enhancements
    # @echo "Edit /etc/default/grub and append rd.luks.options=discard to the GRUB_CMDLINE_LINUX_DEFAULT"
    # @echo "grub2-mkconfig -o /boot/grub2/grub.cfg
    sudo cryptsetup --allow-discards --perf-no_read_workqueue \
      --perf-no_write_workqueue --persistent refresh luks-3b2e35c1-7d2d-4c54-a183-200b70f6af4e

    sudo dmsetup table

enable-custom-kernel-secureboot:
    # Install kernel
    # sudo dnf install sbctl
    # sudo sbctl sign-all
    # sudo openssl x509 -outform DER -in /var/lib/sbctl/keys/db/db.pem -out /root/db.cer
    # sudo mokutil --import /root/db.cer

update-grub:
    sudo grub2-mkconfig -o /boot/grub2/grub.cfg

# show grub entries
show-grub:
    sudo grubby --info=ALL

# generate rescue kernel
generate-rescue-kernel:
    sudo rm -rf /boot/{{ machine_id }}/0-rescue/
    sudo kernel-install add "$(uname -r)" "/lib/modules/$(uname -r)/vmlinuz"
    sbctl sign -s /boot/{{ machine_id }}/0-rescue/linux

# add tailscale repo
tailscale-repo:
    sudo dnf config-manager addrepo --from-repofile=https://pkgs.tailscale.com/stable/fedora/tailscale.repo

# format
format:
    just -f {{ justfile() }} --unstable --format
