---
marp: true
theme: default
class:
  - invert

---

# Ubuntu Sysadmin Ansible Playbook

Aleksandr Usov
2022

---

# Project Goal

Fully automatic configuration and software installation on my Ubuntu computers.

---

# Plan

 * Easy update to a new Ubuntu version
 * Easy migrate to a new computer
 * Gel full operating new brand environment at any time
 * Synchronization of different computers
 * Quality and Testing

---

# Why Linux/Ubuntu?

Linux range of use - one operating system to rule them all

Do you know at least one technology that is available in macOS, but not in Linux, which will help in Sysadmin/DevOps/SRE work duties?

Reducing cognitive load

---

# Technology

* Python(write and modify Ansible modules)
* pre-commit(yamllint, ansible-lint, shellcheck)
* Ansible and Bash
* pyenv and pyenv-virtualenv(for Ansible and work)
* Configure: bash, bash-it, snap and apt software, Oh My Tmux, vim, sudo, GNOME, GNOME terminal, Docker, VirtualBox, Hashicorp software, Homebrew on Linux, Hardware(modify GNOME JavaScript extension), Python, k8s, Go, WireGuard, Visual Studio Code extensions and configuration, etc ...

---

# pre-commit

```bash
$ pre-commit run --all-files
detect private key.......................................................Passed
fix end of files.........................................................Passed
trim trailing whitespace.................................................Passed
Ansible-lint.............................................................Passed
yamllint.................................................................Passed
Test shell scripts with shellcheck.......................................Passed
```

---

# Bash

Ansible is needed to run Ansible

```bash
set -o errexit -o nounset -o xtrace

sudo true

readonly custom_bashrc="${HOME}/.bashrc_${USER}"
readonly python_major_version="3.10"
readonly venv="ansible"

echo "Installing git"
sudo apt update
sudo apt install -y git

if [[ -d "${HOME}/.pyenv" ]]; then
  cd "${HOME}/.pyenv"
  git pull
  cd
else
  git clone https://github.com/pyenv/pyenv.git "${HOME}/.pyenv"
fi
```

---

# Bash

```bash
if [[ ! -d "${HOME}/.pyenv/versions/${python_version}/envs/ansible" ]]; then
  pyenv virtualenv "${python_version}" "${venv}"
fi

set +o nounset
pyenv deactivate || true
pyenv activate "${venv}"
set -o nounset

pip install --upgrade ansible ansible-lint docker pre-commit psutil yamllint
ansible --version

ANSIBLE_PYTHON_INTERPRETER="$(pyenv root)/versions/${python_version}/envs/ansible/bin/python3"
export ANSIBLE_PYTHON_INTERPRETER

set +o errexit +o nounset +o xtrace
```

---

# Ansible

```yaml
---
- name: Jammy configuration
  hosts: localhost
  connection: local
  roles:
    - role: python
      tags: python
    - role: vpn
      tags: vpn
      when: enable_vpn | d() | bool
      become: true
    - role: pocket3
      tags: pocket3
      when: pocket3
```

---

# Ansible

```yaml
- name: Configure hidden files
  ansible.builtin.blockinfile:
    path: "{{ ansible_env['HOME'] }}/.hidden"
    block: "{{ desktop_block }}"
    create: true
    mode: '0640'
  tags: hidden

- name: Add shortcuts
  ansible.builtin.include_tasks:
    file: add_shortcut.yml
    apply:
      tags: shortcuts
  loop: "{{ desktop_shortcuts }}"
  loop_control:
    loop_var: key
  tags: shortcuts
```

---

# Ansible dconf

```python
    def list_sub_dirs(self, key):
        """
        List the sub-dirs of a dir.
        If an error occurs, a call will be made to AnsibleModule.fail_json.
        :param key: A directory path which the sub-dirs should be return. Should be a full path, starting and ending with '/'.
        :type key: str
        :returns: list -- List the sub-dirs of a dir. If the value does not have sub-dirs, returns None.
        """

        command = [self.dconf_bin, "list", key]

        rc, out, err = self.module.run_command(command)

        if rc != 0:
            self.module.fail_json(msg='dconf failed while reading the value with error: %s' % err)

        if out == '':
            values = None
        else:
            values = out.rstrip('\n').split('\n')
        return values
  ```

---

# Ansible dconf
```
ok: [localhost] => changed=false 
  invocation:
    module_args:
      key: /org/gnome/terminal/legacy/profiles:/
      state: list_sub_dirs
      value: null
  values:
  - :b1dcc9dd-5262-4d8d-a863-c897e6d979b9/
```

---

# Ansible vscode

```python
class VSCodePlugins(object):

    def __init__(self, module, check_mode=False):
        self.module = module
        self.check_mode = check_mode
        # Check if vscode binary exists
        self.vscode_bin = self.module.get_bin_path('code-insiders', required=True)

    def install(self, name):
        command = [self.vscode_bin, "--install-extension", name]

        rc, out, err = self.module.run_command(command)

        if rc != 0:
            self.module.fail_json(msg='code-insiders failed while installing extension with error: %s' % err,
                                  out=out,
                                  err=err)
        print(out)
        print(type(out))

        if 'was successfully installed' in out:
            value = out.rstrip('\n')
        else:
            value = None

        return value
```

---

# Ansible vscode

```
TASK [vscode : Install vscode plugins] *******************************************************************************
Понедельник 24 октября 2022  15:29:41 +0300 (0:00:06.543)       0:00:11.646 *** 
ok: [localhost] => (item=golang.go-nightly)
ok: [localhost] => (item=marp-team.marp-vscode)
ok: [localhost] => (item=ms-kubernetes-tools.vscode-kubernetes-tools)
ok: [localhost] => (item=ms-azuretools.vscode-docker)
ok: [localhost] => (item=redhat.ansible)
```

---

# Roles

 * python
 * vpn
 * pocket3
 * common
 * docker
 * virtualbox
 * hashicorp
 * vscode
 * bash
 * desktop
 * linuxbrew

---

# How to run

[GitHub](https://github.com/irqoff/jammy)

Just execute `jammy.sh`:

```bash
./jammy.sh
```

For run without `jammy.sh`, execute `sudo true && export ANSIBLE_PYTHON_INTERPRETER=${PYENV_VIRTUAL_ENV}/bin/python3` and then `ansible-playbook jammy.yml -t foo`

---

# GPD Pocket 3

Some things in Linux are slightly difficult to automate when you use modern or rate software.

Steps:
 * `./jammy.sh`
 * `sudo true && export ANSIBLE_PYTHON_INTERPRETER=${PYENV_VIRTUAL_ENV}/bin/python3`
 * `ansible-playbook jammy.yml -t pocket3 -e pocket3=yes`
 * `reboot`
 * `ansible-playbook jammy.yml -t pocket3 -e pocket3=yes -e pocket3_after_reboot=yes`

---

# GPD Pocket 3

```yaml
- name: Pocket 3 hwdb configure
  ansible.builtin.copy:
    content: |-
      sensor:modalias:acpi:MXC6655*:dmi:*:svnGPD:pnG1621-02:*
       ACCEL_MOUNT_MATRIX=0, -1, 0; -1, 0, 0; 0, 0, 1
    dest: /etc/udev/hwdb.d/61-sensor-local.hwdb
    mode: '0644'
    owner: root
    group: root
  notify: Pocket 3 update hwdb
  become: True

- name: Install screen-autorotate-kosmospredanie.yandex.ru
  ansible.builtin.git:
    repo: https://github.com/irqoff/screen-autorotate-kosmospredanie.yandex.ru.git
    dest: "{{ ansible_env['HOME'] }}/.local/share/gnome-shell/extensions/screen-autorotate@kosmospredanie.yandex.ru"
    version: master
    depth: 1
```

---

# GPD Pocket 3

```yaml
- name: Check GetCurrentState
  ansible.builtin.command: gdbus call -e -d org.gnome.Mutter.DisplayConfig -o /org/gnome/Mutter/DisplayConfig
    -m org.gnome.Mutter.DisplayConfig.GetCurrentState
  register: result
  changed_when: no
  when: pocket3_after_reboot | bool

- name: Change scalling
  ansible.builtin.command: gdbus call -e -d org.gnome.Mutter.DisplayConfig -o /org/gnome/Mutter/DisplayConfig
    -m org.gnome.Mutter.DisplayConfig.ApplyMonitorsConfig 1 2 "{{ pocket3_logical_monitors }}" "[]"
  when: pocket3_after_reboot | bool and "'0, 0, 1.25' not in result.stdout"
```

---

# Result

I got a solution that doesn't annoy me when I need to upgrade my laptop or install a new computer

---

# Plans

 * Move backup(restic) and synchronization(rclone and GitHub) script from file/gitignore(non-public) to a role
 * Move Testinfra scripts from from file/gitignore(non-public) to the main repo
 * Write tests that will test the result, not that the Ansible's modules work

---

# Thank you for your attention!

---
