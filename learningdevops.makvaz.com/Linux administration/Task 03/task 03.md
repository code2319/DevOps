### [Task 03.](https://learningdevops.makvaz.com/phase1-task3-scripting) Scripting. Automate installation of WordPress.

### 0. Requirements
- VMware or VirtualBox with GUI operating system  
P.S. I'll use Ubuntu Desktop 22.04 LTS and VMWare Workstation

### 1. Installing vagrant 
1. Import an official vagrant signing key so apt could verify the packages authenticity. Fetch the key: `curl https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/vagrant-archive-keyring.gpg >/dev/null`
3. Verify that the downloaded file contains the proper key: `gpg --dry-run --quiet --import --import-options import-show /usr/share/keyrings/vagrant-archive-keyring.gpg`
4. To set up the apt repository for stable vagrant packages, run the following command: ``echo "deb [signed-by=/usr/share/keyrings/vagrant-archive-keyring.gpg] https://apt.releases.hashicorp.com `lsb_release -cs` main" | sudo tee /etc/apt/sources.list.d/vagrant.list``
6. To install vagrant, run the following commands: `sudo apt-get update && sudo apt-get install vagrant`
7. Additionally for VMware you need to install: 
   1. [VMware provider](https://www.vagrantup.com/docs/providers/vmware/installation)
   2. [VMware Utility](https://www.vagrantup.com/docs/providers/vmware/vagrant-vmware-utility)
> Before executing the `vagrant up` command, you must start the VMware itself.

### 2. Installing VMware
1. [Download the VMware installer for linux](https://www.vmware.com/products/workstation-pro/workstation-pro-evaluation.html)
2. `sudo chmod +x ./VMware-Workstation-Full-16.2.3-19376536.x86_64.bundle`
3. `sudo ./VMware-Workstation-Full-16.2.3-19376536.x86_64.bundle`
4. Now you need to install `vmmon` and `vmnet`: [vmmon and vmnet for VMware workstation](https://github.com/mkubecek/vmware-host-modules/tree/tmp/workstation-16.2.3-k5.18)

### 3. Automate deployment
1. Initialize a Project Directory: `mkdir task03 && cd task03`
2. Move and edit the `Vagrantfile` from the task to the created folder
3. Install and Specify a Box: `vagrant add box generic/ubuntu2004`
4. Edit bash script `setup_wordpress.sh` that installs, configures and starts nginx, mysql, WordPress.
5. Bring up a virtual machine: `vagrant up`

### Useful docs
1. [Vagrant getting started](https://learn.hashicorp.com/collections/vagrant/getting-started)
2. [How to set up a self-hosted "vagrant cloud" with versioned, self-packaged vagrant boxes](https://github.com/hollodotme/Helpers/blob/master/Tutorials/vagrant/self-hosted-vagrant-boxes-with-versioning.md)
3. [WP-CLI commands](https://developer.wordpress.org/cli/commands/)
4. [VMX-file parameters](http://sanbarrow.com/vmx.html)
5. [Customizing Vagrant VMware Fusion Virtual Machines with VMX Parameters](https://thornelabs.net/posts/customizing-vagrant-vmware-fusion-virtual-machines-with-vmx-parameters.html)
