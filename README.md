# autoinstall-mageia
Tools to deploy the Mageia infrastructure

First you need to deploy a deployment server. On an existing Mageia 9 machine, do 

cd autoinstall-mageia/install
sudo ./install.sh -n dploy -f dploy.mydomain.org

For that to work you need to adapt the values provided in autoinstall-mageia/ansible/group_vars/all.yml

Once this is done, your machine is a deployment server for a Mageia infra.

You can then deploy a build node by PXE booting the machine, using the build type of install.
