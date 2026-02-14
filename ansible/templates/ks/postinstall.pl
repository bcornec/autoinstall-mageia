exec &> >(tee /root/postautoinstall.log)
# Setup sudo for {{ MGAADMININS }}
echo "Defaults:{{ MGAADMININS }} !fqdn" > /etc/sudoers.d/{{ MGAADMININS }}
echo "Defaults:{{ MGAADMININS }} !requiretty" >> /etc/sudoers.d/{{ MGAADMININS }}
echo "{{ MGAADMININS }} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/{{ MGAADMININS }}
# Setup passwd for root
MGAPWD=`head -80 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1`
echo "root:$MGAPWD" | chpasswd
echo "root is $MGAPWD" > /root/drakx/root
# Setup passwd for {{ MGAADMININS }}
MGAPWD=`head -80 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1`
echo "$MGAADMININS:$MGAPWD" | chpasswd
echo "$MGAADMININS is $MGAPWD" > /root/drakx/$MGAADMININS

# Get the systemd conf file for reboot
wget http://{{ MGADPLOYIP }}/ks/autoinstall-mageia.service -O /etc/systemd/system/autoinstall-mageia.service
chmod 644 /etc/systemd/system/autoinstall-mageia.service
# autoinstall-mageia
mkdir -p {{ MGALOCAL }}/autoinstall
wget http://{{ MGADPLOYIP }}/ks/autoinstall-mageia -O {{ MGALOCAL }}/autoinstall/autoinstall-mageia
chmod 755 {{ MGALOCAL }}/autoinstall/autoinstall-mageia
wget http://{{ MGADPLOYIP }}/ks/{{ item.1.name }}_autoinstall-mageia.sh -O {{ MGALOCAL }}/autoinstall/mageia.sh
chmod 755 {{ MGALOCAL }}/autoinstall/mageia.sh
# Generate mageia.yml
{{ MGALOCAL }}/autoinstall/mageia.sh
chown -R {{ MGAADMININS }}:{{ MGAADMININS }} {{ MGALOCAL }}/autoinstall
chmod 755 {{ MGALOCAL }}/autoinstall
# helper scripts
wget http://{{ MGADPLOYIP }}/ks/install-functions.sh -O {{ MGALOCAL }}/autoinstall/install-functions.sh
chmod 755 {{ MGALOCAL }}/autoinstall/install-functions.sh
wget http://{{ MGADPLOYIP }}/ks/install.repo -O {{ MGALOCAL }}/autoinstall/install.repo
chmod 755 {{ MGALOCAL }}/autoinstall/install.repo
wget http://{{ MGADPLOYIP }}/ks/{{ item.1.name }}_postinstall.pl -O {{ MGALOCAL }}/autoinstall/postinstall.pl
chmod 755 {{ MGALOCAL }}/autoinstall/postinstall.pl
wget http://{{ MGADPLOYIP }}/ks/mga-check-network -O {{ MGALOCAL }}/bin/mga-check-network
chmod 755 {{ MGALOCAL }}/bin/mga-check-network
# At first boot finish install - disabled at end of install script
systemctl enable autoinstall-mageia
