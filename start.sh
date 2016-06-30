$KEYMAP=us
package_install(){
  pacman -S --noconfirm --needed ${PKG}

}
MOUNTPOINT="/mnt/"
loadkeys $KEYMAP
package_install "nano"
#Available countries are
#"Australia" "Austria" "Belarus" "Belgium" "Brazil" "Bulgaria" "Canada"
#"Chile" "China" "Colombia" "Czech Republic" "Denmark" "Estonia" "Finland"
#"France" "Germany" "Greece" "Hungary" "India" "Ireland" "Israel" "Italy"
#"Japan" "Kazakhstan" "Korea" "Latvia" "Luxembourg" "Macedonia" "Netherlands"
#"New Caledonia" "New Zealand" "Norway" "Poland" "Portugal" "Romania" "Russian"
#"Serbia" "Singapore" "Slovakia" "South Africa" "Spain" "Sri Lanka" "Sweden"
#"Switzerland" "Taiwan" "Turkey" "Ukraine" "United Kingdom" "United States" "Uzbekistan" "Viet Nam"

country_code=India
url="https://www.archlinux.org/mirrorlist/?country=${country_code}&use_mirror_status=on"

tmpfile=$(mktemp --suffix=-mirrorlist)

curl -so ${tmpfile} ${url}
sed -i 's/^#Server/Server/g' ${tmpfile}

# Get latest mirror list and save to tmpfile
if [[ -s ${tmpfile} ]]; then
   { echo " Backing up the original mirrorlist..."
     mv -i /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.orig; } &&
   { mv -i ${tmpfile} /etc/pacman.d/mirrorlist; }
  else
    echo " Unable to update, could not download list."
    exit
  fi

curl -so ${tmpfile} ${url}
sed -i 's/^#Server/Server/g' ${tmpfile}
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.tmp
rankmirrors /etc/pacman.d/mirrorlist.tmp > /etc/pacman.d/mirrorlist
rm /etc/pacman.d/mirrorlist.tmp
# allow global read access (required for non-root yaourt execution)
chmod +r /etc/pacman.d/mirrorlist

setup_alt_dns(){
  cat <<- EOF > /etc/resolv.conf.head
# OpenDNS IPv4 nameservers
nameserver 208.67.222.222
nameserver 208.67.220.220
# OpenDNS IPv6 nameservers
nameserver 2620:0:ccc::2
nameserver 2620:0:ccd::2

# Google IPv4 nameservers
nameserver 8.8.8.8
nameserver 8.8.4.4
# Google IPv6 nameservers
nameserver 2001:4860:4860::8888
nameserver 2001:4860:4860::8844

# Comodo nameservers
nameserver 8.26.56.26
nameserver 8.20.247.20

# Basic Yandex.DNS - Quick and reliable DNS
nameserver 77.88.8.8
nameserver 77.88.8.1
# Safe Yandex.DNS - Protection from virus and fraudulent content
nameserver 77.88.8.88
nameserver 77.88.8.2
# Family Yandex.DNS - Without adult content
nameserver 77.88.8.7
nameserver 77.88.8.3

# censurfridns.dk IPv4 nameservers
nameserver 91.239.100.100
nameserver 89.233.43.71
# censurfridns.dk IPv6 nameservers
nameserver 2001:67c:28a4::
nameserver 2002:d596:2a92:1:71:53::
EOF
}
umount_partitions(){
  mounted_partitions=(`lsblk | grep ${MOUNTPOINT} | awk '{print $7}' | sort -r`)
  swapoff -a
  for i in ${mounted_partitions[@]}; do
    umount $i
  done
}
umount_partitions
echo -e "Set up Partition"
cfdisk /dev/sda
clear
umount_partitions
echo -e "Select root partition"
PS3="Select partition"
partitions=(`lsblk -l | grep sda[0-9] | awk '{print $1}'`)
select boot in "${partitions[@]}"; do
  echo $boot
  echo -e "formatting to ext3 filesystem"
  mkfs.ext4 /dev/$boot
  break
done;
mkdir /mnt
mount /dev/$boot /mnt
pacstrap -i /mnt base base-devel parted btrfs-progs f2fs-tools ntp
genfstab -U -p /mnt >> /mnt/etc/fstab
mv /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist
arch-chroot /mnt
nano /etc/locale.gen
echo LANG=en_US.UTF-8 > /etc/locale.conf
export LANG=en_US.UTF-8
ln -s /usr/share/zoneinfo/Asia/Kolkata /etc/localtime
hwclock --systohc --utc
pacman -Sy
pacman -S wireless_tools wpa_supplicant wpa_actiond dialog
passwd
read -p "Username: " username
username=`echo $username | tr '[:upper:]' '[:lower:]'`
useradd -m -g users -G wheel -s /bin/bash ${username}
chfn ${username}
passwd ${username}
while [[ $? -ne 0 ]]; do
  passwd ${username}
done
pacman -S sudo git
git clone https://github.com/helmuthdu/dotfiles
cp dotfiles/.bashrc dotfiles/.dircolors dotfiles/.dircolors_256 dotfiles/.nanorc dotfiles/.yaourtrc ~/
cp dotfiles/.bashrc dotfiles/.dircolors dotfiles/.dircolors_256 dotfiles/.nanorc dotfiles/.yaourtrc /home/${username}/
rm -fr dotfiles
sed -i '/%wheel ALL=(ALL) ALL/s/^#//' /etc/sudoers
echo "" >> /etc/sudoers
echo 'Defaults !requiretty, !tty_tickets, !umask' >> /etc/sudoers
echo 'Defaults visiblepw, path_info, insults, lecture=always' >> /etc/sudoers
echo 'Defaults loglinelen=0, logfile =/var/log/sudo.log, log_year, log_host, syslog=auth' >> /etc/sudoers
echo 'Defaults passwd_tries=3, passwd_timeout=1' >> /etc/sudoers
echo 'Defaults env_reset, always_set_home, set_home, set_logname' >> /etc/sudoers
echo 'Defaults !env_editor, editor="/usr/bin/vim:/usr/bin/vi:/usr/bin/nano"' >> /etc/sudoers
echo 'Defaults timestamp_timeout=15' >> /etc/sudoers
echo 'Defaults passprompt="[sudo] password for %u: "' >> /etc/sudoers
pacman -S base-devel yajl namcap
su - ${username} -c "
  [[ ! -d aui_packages ]] && mkdir aui_packages
  cd aui_packages
  curl -o yaourt.tar.gz https://aur.archlinux.org/cgit/aur.git/snapshot/yaourt.tar.gz
  tar zxvf yaourt.tar.gz
  rm yaourt.tar.gz
  cd yaourt
  makepkg -csi --noconfirm
"
pacman -S bc rsync mlocate bash-completion tlp zramswap pkgstats arch-wiki-lite zip unzip unrar p7zip lzop nfs-utils cpio avahi nss-mdns alsa-utils alsa-plugins lib32-alsa-plugins pulseaudio pulseaudio-alsa lib32-libpulse ntfs-3g dosfstools exfat-utils f2fs-tools fuse fuse-exfat autofs openssh

# configuring ssh
system_ctl enable sshd
[[ ! -f /etc/ssh/sshd_config.aui ]] && cp -v /etc/ssh/sshd_config /etc/ssh/sshd_config.aui;
  sed -i '/Port 22/s/^#//' /etc/ssh/sshd_config
  sed -i '/Protocol 2/s/^#//' /etc/ssh/sshd_config
  sed -i '/HostKey \/etc\/ssh\/ssh_host_rsa_key/s/^#//' /etc/ssh/sshd_config
  sed -i '/HostKey \/etc\/ssh\/ssh_host_dsa_key/s/^#//' /etc/ssh/sshd_config
  sed -i '/HostKey \/etc\/ssh\/ssh_host_ecdsa_key/s/^#//' /etc/ssh/sshd_config
  sed -i '/KeyRegenerationInterval/s/^#//' /etc/ssh/sshd_config
  sed -i '/ServerKeyBits/s/^#//' /etc/ssh/sshd_config
  sed -i '/SyslogFacility/s/^#//' /etc/ssh/sshd_config
  sed -i '/LogLevel/s/^#//' /etc/ssh/sshd_config
  sed -i '/LoginGraceTime/s/^#//' /etc/ssh/sshd_config
  sed -i '/PermitRootLogin/s/^#//' /etc/ssh/sshd_config
  sed -i '/HostbasedAuthentication/s/^#//' /etc/ssh/sshd_config
  sed -i '/StrictModes/s/^#//' /etc/ssh/sshd_config
  sed -i '/RSAAuthentication/s/^#//' /etc/ssh/sshd_config
  sed -i '/PubkeyAuthentication/s/^#//' /etc/ssh/sshd_config
  sed -i '/IgnoreRhosts/s/^#//' /etc/ssh/sshd_config
  sed -i '/PermitEmptyPasswords/s/^#//' /etc/ssh/sshd_config
  sed -i '/AllowTcpForwarding/s/^#//' /etc/ssh/sshd_config
  sed -i '/AllowTcpForwarding no/d' /etc/ssh/sshd_config
  sed -i '/X11Forwarding/s/^#//' /etc/ssh/sshd_config
  sed -i '/X11Forwarding/s/no/yes/' /etc/ssh/sshd_config
  sed -i -e '/\tX11Forwarding yes/d' /etc/ssh/sshd_config
  sed -i '/X11DisplayOffset/s/^#//' /etc/ssh/sshd_config
  sed -i '/X11UseLocalhost/s/^#//' /etc/ssh/sshd_config
  sed -i '/PrintMotd/s/^#//' /etc/ssh/sshd_config
  sed -i '/PrintMotd/s/yes/no/' /etc/ssh/sshd_config
  sed -i '/PrintLastLog/s/^#//' /etc/ssh/sshd_config
  sed -i '/TCPKeepAlive/s/^#//' /etc/ssh/sshd_config
  sed -i '/the setting of/s/^/#/' /etc/ssh/sshd_config
  sed -i '/RhostsRSAAuthentication and HostbasedAuthentication/s/^/#/' /etc/ssh/sshd_config

system_ctl enable rpcbind
system_ctl enable nfs-client.target
system_ctl enable remote-fs.target
system_ctl enable systemd-readahead-collect
system_ctl enable systemd-readahead-replay
system_ctl enable zramswap
system_ctl enable tlp
system_ctl enable tlp-sleep
system_ctl disable systemd-rfkill

# XORG Libraries
pacman -S xorg-server xorg-server-utils xorg-server-xwayland xorg-xinit xorg-xkill xf86-input-synaptics mesa xf86-input-mouse xf86-input-keyboard xf86-input-wacom xf86-input-joystick xf86-input-libinput
modprobe uinput

#FONTS
pacman -S fontconfig-ubuntu
pacman -Rdds freetype2-ubuntu fontconfig-ubuntu cairo-ubuntu

#GRAPHICS
pacman -S dmidecode
pacman -S virtualbox-guest-modules-arch mesa-libgl
