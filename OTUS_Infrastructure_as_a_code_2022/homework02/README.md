# homework02 

## Basic Exampe

### OAuth token
```
$ yc config list
token: AQ...
cloud-id: b1...
folder-id: b1...
compute-default-zone: ru-central1-a
```
then run `packer`:
```
$ packer build template.json
...
--> yandex: A disk image was created: ubuntu-2004-lts-nginx-2022-07-28t06-34-03z (id: fd8l2eaeb5jo0mb3cmd5) with family name ubuntu-web-server
```

### Service Account Key
```
$  yc iam service-account create --name packer --folder-id b1...
id: aj...
folder_id: b1...
created_at: "2022-07-28T06:37:27.442009319Z"
name: packer

$  yc resource-manager folder add-access-binding --id b1... --role editor --service-account-id aj...
done (1s)


$ yc iam key create --service-account-id aj... --output key.json
id: aj...
service_account_id: aj...
created_at: "2022-07-28T06:39:04.428227121Z"
key_algorithm: RSA_2048
```
then run `packer`:
```
$ packer build template.json
...
--> yandex: A disk image was created: ubuntu-2004-lts-nginx-2022-07-28t06-40-31z (id: fd8k08kl9t08ob9pg0r7) with family name ubuntu-web-server
```

## Template User Variables
Add `PACKER_VAR_packages` in template.json and run `packer`:
```
$ packer build template.json
...
==> yandex:
==> yandex: WARNING: apt does not have a stable CLI interface. Use with caution in scripts.
==> yandex:
    yandex: Building dependency tree...
    yandex: Reading state information...
    yandex: The following NEW packages will be installed:
    yandex:   htop
    yandex: 0 upgraded, 1 newly installed, 0 to remove and 1 not upgraded.
    yandex: Need to get 80.5 kB of archives.
    yandex: After this operation, 225 kB of additional disk space will be used.
    yandex: Get:1 http://mirror.yandex.ru/ubuntu focal/main amd64 htop amd64 2.2.0-2build1 [80.5 kB]
    yandex: Fetched 80.5 kB in 0s (3,948 kB/s)
==> yandex: debconf: unable to initialize frontend: Dialog
==> yandex: debconf: (Dialog frontend will not work on a dumb terminal, an emacs shell buffer, or without a controlling terminal.)
==> yandex: debconf: falling back to frontend: Readline
    yandex: Selecting previously unselected package htop.
==> yandex: debconf: unable to initialize frontend: Readline
==> yandex: debconf: (This frontend requires a controlling tty.)
==> yandex: debconf: falling back to frontend: Teletype
==> yandex: dpkg-preconfigure: unable to re-open stdin:
    yandex: (Reading database ... 105447 files and directories currently installed.)
    yandex: Preparing to unpack .../htop_2.2.0-2build1_amd64.deb ...
    yandex: Unpacking htop (2.2.0-2build1) ...
    yandex: Setting up htop (2.2.0-2build1) ...
    yandex: Processing triggers for mime-support (3.64ubuntu1) ...
    yandex: Processing triggers for man-db (2.9.1-1) ...
...
--> yandex: A disk image was created: ubuntu-2004-lts-nginx-2022-07-28t06-48-44z (id: fd8481ojves13al8b9sv) with family name ubuntu-web-server
```

## Another Builder
For example Docker, just run `packer` on a host with Docker:
```
$ packer  build docker_template.json
...
--> docker: Imported Docker image: sha256:223bd1704e110fbbdf00f18dfa6a654efa7a50d861696506615d64a58841b4c1
```
