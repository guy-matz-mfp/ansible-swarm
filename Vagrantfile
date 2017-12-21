# -*- mode: ruby -*-
# vi: set ft=ruby :

#############################
##### BEGIN CUSTOMIZATION #####
#############################
VAGRANTFILE_API_VERSION       = "2"
VAGRANT_EXECUTOR              = ENV['USER']
VM_OS                         = "vsphere-dummy"
VM_NAME_DOMAIN                = ".ash1.dev"
# vSphere Parameters
VSPHERE_HOST                  = "tbvc02us2.prod.247media.com"
VSPHERE_COMPUTE_RESOURCE_NAME = "DevOps Testing"
VSPHERE_USER                  = ENV['VSPHERE_USER']
VSPHERE_PASSWORD              = ENV['VSPHERE_PASSWORD']
VSPHERE_TEMPLATE              = "vagrant-templates/centos-7-4-vagrant"
VSPHERE_DATA_STORE            = "test2-data2"
VSPHERE_VM_BASE_PATH          = "vagrant-vms"
# VM Parameters
MGR_COUNT                      = 3
WKR_COUNT                      = 4
VM_CPUS                       = 2
VM_MEMORY                     = 4096
MGR_NAME_PREFIX                = "swarm-manager"
WKR_NAME_PREFIX                = "swarm-worker"
# Ansible Parameters
ANSIBLE_VERSION               = "latest" #(e.g. "2.2.1.0" or "latest" for the newest available version) This only works with pip
ANSIBLE_VERBOSE               = "-v"
ANSIBLE_ROLE_DIRECTORY_NAME   = "../vagrant-templates-toolbox/vsphere-cluster-ansible-node"
ANSIBLE_RAW_ARGUMENTS         = "--private-key=tests/keys/private/private_key"#,"--vault-password-file=tests/.vault_password"
ANSIBLE_GITHUB_REPOS          = "ansible-role-common"
#############################
##### END CUSTOMIZATION #####
#############################


required_plugins = %w( vagrant-hostmanager vagrant-vsphere )
required_plugins.each do |plugin|
  system "vagrant plugin install #{plugin}" unless Vagrant.has_plugin? plugin
end

Vagrant.require_version ">= 2.0.0"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box                   = VM_OS
  config.vm.post_up_message       = "Use \"vagrant ssh #{MGR_NAME_PREFIX}#\" to log into the box. This VM uses #{VM_CPUS} CPUs and #{VM_MEMORY}MB of RAM. #{MGR_COUNT} nodes #{MGR_NAME_PREFIX} cluster is ready."
  config.ssh.forward_agent        = true
  config.hostmanager.enabled      = true
  config.hostmanager.manage_host  = false
  config.hostmanager.manage_guest = true
  config.hostmanager.ignore_private_ip = true
#  config.hostmanager.ip_resolver = proc do |vm|
#      result = ''
#      vm.communicate.execute("ifconfig ens160") do |type, data|
#          result << data if type == :stdout
#      end
#      (ip = /inet (\d+\.\d+\.\d+\.\d+)/.match(result)) && ip[1]
#  end
#  config.hostmanager.ip_resolver = proc do |vm, resolving_vm|
#    if hostname = (vm.ssh_info && vm.ssh_info[:host])
#      `host #{hostname}`.split("\n").last[/(\d+\.\d+\.\d+\.\d+)/, 1]
#    end
#  end
  config.vm.provision :hostmanager
  config.vm.synced_folder ".", "/vagrant",
    disabled: false
  # Vsphere defaults
  config.vm.provider :vsphere do |vsphere, override|
    vsphere.host = VSPHERE_HOST
    vsphere.compute_resource_name = VSPHERE_COMPUTE_RESOURCE_NAME
    vsphere.user = VSPHERE_USER
    vsphere.password = VSPHERE_PASSWORD
    vsphere.template_name = VSPHERE_TEMPLATE
    vsphere.vm_base_path = VSPHERE_VM_BASE_PATH
    vsphere.insecure = true
    override.nfs.functional = false
    vsphere.cpu_count = VM_CPUS
    vsphere.memory_mb = VM_MEMORY
    vsphere.real_nic_ip = true
  end

# Loop that will dynamically create as many virtual machines as are stated by the MGR_COUNT variable
  (1..MGR_COUNT).each do |n|
    vm_name = "#{MGR_NAME_PREFIX}%01d#{VM_NAME_DOMAIN}" % n
    config.vm.define "#{vm_name}" do |machine|
      machine.vm.hostname = vm_name
      machine.vm.provider :vsphere do |vsphere|
          vsphere.name = "#{VAGRANT_EXECUTOR}-#{vm_name}"
      machine.vm.provision "deploy_ssh_authorized_keys", type: "shell",
          inline: "cat /vagrant/tests/keys/public/authorized_keys >> /home/vagrant/.ssh/authorized_keys"
      end
    end
  end

# Loop that will dynamically create as many virtual machines as are stated by the WKR_COUNT variable
  (1..WKR_COUNT).each do |n|
    vm_name = "#{WKR_NAME_PREFIX}%01d#{VM_NAME_DOMAIN}" % n
    config.vm.define "#{vm_name}" do |machine|
      machine.vm.hostname = vm_name
      machine.vm.provider :vsphere do |vsphere|
          vsphere.name = "#{VAGRANT_EXECUTOR}-#{vm_name}"
      machine.vm.provision "deploy_ssh_authorized_keys", type: "shell",
          inline: "cat /vagrant/tests/keys/public/authorized_keys >> /home/vagrant/.ssh/authorized_keys"
      end
    end
  end

  config.vm.define 'ansiblebox' do |machine|
    machine.vm.provider :vsphere do |vsphere|
        #vsphere.name = "#{VAGRANT_EXECUTOR}-ansiblebox-#{VM_NAME_PREFIX}"
        vsphere.name = "#{VAGRANT_EXECUTOR}-ansiblebox"
    end
    machine.vm.synced_folder "#{ANSIBLE_ROLE_DIRECTORY_NAME}",
         "/etc/ansible/roles/#{ANSIBLE_ROLE_DIRECTORY_NAME}", disabled: false
    if !ANSIBLE_GITHUB_REPOS.empty?
      machine.vm.provision "pull_github_repos", type: "shell", run: "always" ,inline: <<-SHELL
        chmod 0777 /vagrant/tests/git-bulk-pull.sh
        export REPOLIST="#{ANSIBLE_GITHUB_REPOS}"
        /vagrant/tests/git-bulk-pull.sh
        SHELL
    end
    machine.vm.provision "chmod_files", type: "shell",
      run: "always",
      inline: "chmod 0600 /vagrant/tests/keys/private/private_key
               chmod 0666 /vagrant/tests/.vault_password"

    machine.vm.provision :ansible_local, run: "always" do |ansible|
      ansible.install        = true
      ansible.version        = ANSIBLE_VERSION
      ansible.limit          = "all"
      ansible.verbose        = ANSIBLE_VERBOSE
      ansible.become         = true
      ansible.playbook       = "site.yml"
      ansible.raw_arguments  = [ ANSIBLE_RAW_ARGUMENTS ]
      ansible.extra_vars     = {
        hostgroup: 'docker',
        ansible_ssh_user: 'vagrant'
      }
      ansible.groups = {
        "docker" => [
                    "#{MGR_NAME_PREFIX}[1:#{MGR_COUNT}]#{VM_NAME_DOMAIN}",
                    "#{WKR_NAME_PREFIX}[1:#{WKR_COUNT}]#{VM_NAME_DOMAIN}",
        ],
        "#{MGR_NAME_PREFIX}" => ["#{MGR_NAME_PREFIX}[1:#{MGR_COUNT}]#{VM_NAME_DOMAIN}"],
        "#{WKR_NAME_PREFIX}" => ["#{WKR_NAME_PREFIX}[1:#{WKR_COUNT}]#{VM_NAME_DOMAIN}"],
      }
    end

  end
end
