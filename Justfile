# My Framework setup

default:
    just --choose

tpm-luks-unlock:
    @echo "Setting up TPM and unlocking LUKS"
    sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7+14


# add-negativo-multimedia:
#     sudo dnf config-manager addrepo --from-repofile=https://negativo17.org/repos/fedora-multimedia.repo

install-displaylink:
    # install displaylink from https://github.com/displaylink-rpm/displaylink-rpm/releases
    mokutil --sb-state
    [ ! -f /var/lib/dkms/mok.pub ] && sudo dkms generate_mok
    sudo mokutil --import /var/lib/dkms/mok.pub
    sudo dkms autoinstall

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

libvirt-system:
    # make libvirt client tools use system libvirt
    sudo usermod -aG libvirt $(whoami)
    mkdir -p ~/.config/libvirt
    echo 'uri_default = "qemu:///system"' >> ~/.config/libvirt/libvirt.conf