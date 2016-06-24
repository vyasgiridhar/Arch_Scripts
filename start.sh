$KEYMAP=us
package_install(){
  pacman -S --noconfirm --needed ${PKG}

}
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

# Get latest mirror list and save to tmpfile  if [[ -s ${tmpfile} ]]; then
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
