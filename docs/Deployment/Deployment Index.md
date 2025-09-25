Exact steps, in order, to go from bare **Debian install** → **bootstrap** → **Ansible automation** → **service deployment**.  
Each section gives a short summary and links to the detailed docs/playbooks.  
From **step 2 onward**, all changes are managed only via **Ansible (no manual edits)**.

# 0\. Static IP assignment

Initial steps before the Debian installation. These are only performed once to prepare for reproducible setup.

**Boot and IP Setup**

- Boot Tresor from the Debian 12 USB stick
- Select **Graphical Install**
- Connect Ethernet when prompted
- Let the installer **auto-configure the network via DHCP**
- Tresor will receive a **temporary IP**
- Pause installation at this step

#### Static IP in Router

- On another device:
    - Open the router’s admin portal
    - Find Tresor in the DHCP client list by MAC address
    - Reserve IP **192.168.0.42** (must be outside DHCP pool)
    - Save changes
    - Reboot Tresor or replug Ethernet to confirm lease is picked up

* * *

# 1\. Debian 12 Graphical install and tresor-vm set-up

Debian 12.11 netinst ISO  
• Prod (Tresor): manual partitioning (SSD /, EFI, /mnt/ssd; HDD /mnt/data), user radu, root login disabled, only SSH server + standard utils installed  
• QA (tresor-vm): 4 vCPU, 8 GB RAM, 100 GB QCOW2 on SSD, DHCP via virbr0, user radu, root login disabled, only SSH + standard utils  
• Result: clean headless systems with SSH enabled, ready for bootstrap with ansible

See [1\. Debian 12 graphical install](../../Tresor/Deployment/1.%20Debian%2012%20Graphical%20install.md)  
See [1.1 VM Debian set-up](../../Tresor/Deployment/1.1%20VM%20Debian%20set-up.md)

* * *

# 2\. Run the initial bootsrap script: init-tresor

Initial bootstrap (init-tresor)  
• Copy init-tresor.sh to /tmp on the target (via scp or USB).  
• Run the script with environment variables:  
• ANSIBLE_PUBKEY → your workstation’s public key  
• SET_HOSTNAME → tresor or tresor-vm  
• ALLOW_USERS → ansible radu (transition, later just ansible)  
• Script actions:  
• Creates ansible user with passwordless sudo  
• Installs minimal deps: sudo, python3, rsync, openssh-server  
• Hardens SSH: disables root login + password auth  
• Verify: log in as ansible with key, run sudo -n true && echo OK, and test ansible -m ping.

See [init-tresor. sh](../../Tresor/Scripts/init-tresor.%20%20sh.md)

* * *

# 3\. Deploy the setup-base.yml playbook. 

To be continued…

* * *