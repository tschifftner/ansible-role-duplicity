# Ansible Role: Install and configure duplicity

[![Build Status](https://travis-ci.org/tschifftner/ansible-role-duplicity.svg?branch=master)](https://travis-ci.org/tschifftner/ansible-role-duplicity)

Installs duplicity from source and handles backup tasks on Debian/Ubuntu linux servers.

## Requirements

ansible 2.0+

## Dependencies

None.

## Installation

```
$ ansible-galaxy install tschifftner.duplicity
```

## Example Playbook

Available variables are listed below, along with default values (see `defaults/main.yml`):

```yaml
    - hosts: webservers
      vars:
        # duplictity
        duplicity_known_hosts:
          - host: 'example.org'
            key: 'example.org ssh-rsa AAAAB3NzaC...+PwAK+MPw=='
            state: present
    
        duplicity_config_vars:
          FTP_SERVER: 'sftp://username@example.org/my/folder/'
          FTP_PASSWORD: '*******'
          DEFAULT_PARAMS: '--verbosity info --exclude-device-files --exclude-other-filesystems --exclude-if-present .duplicity-ignore'
    
        duplicity_cronjobs:
          - name: 'Cleanup older than 2 months'
            user: root
            group: root
            source: /etc/duplicity/duplicity.conf
            hour: 4
            minute: 10
            command: >
              duplicity remove-older-than 2M --force --extra-clean $FTP_SERVER;
              duplicity cleanup --force $FTP_SERVER
    
          - name: 'Backup /var/www'
            user: root
            group: root
            hour: 5
            minute: 21
            source: /etc/duplicity/duplicity.conf
            command: duplicity $DEFAULT_PARAMS --include /var/www --full-if-older-than 1M --exclude '**' / $FTP_SERVER

      roles:
             - { role: tschifftner.duplicity }
```

It's recommended to put all vars in an external file.

```yaml
    - hosts: webservers
      vars_files:
        - duplicity-settings.yml
    
      roles:
         - { role: tschifftner.duplicity }
```

## Tips
 - Use `ssh-keyscan -t rsa example.org` to get ssh-key for a server (used in duplicity_known_hosts variable)
 - Its possible to write cronjobs in multiple lines. But this causes failure in idempotence! For example:
 
```
 command: >
   duplicity remove-older-than 2M --force --extra-clean $FTP_SERVER;
   duplicity cleanup --force $FTP_SERVER
```

This will always result in changed!      
      
### Duplicity variables
```yaml
duplicity_config_vars:
  SERVER: 'ftp://username@ftp.example.com/backups/'
  PASSPHRASE: 'YourSecretPassphrase'
  FTP_PASSWORD: '*******'
  PARAMS: '--verbosity info --exclude-device-files --exclude-other-filesystems --exclude-if-present .duplicity-ignore --exclude-filelist /etc/duplicity/exclude.list'
  INCLUDES: '/root /home /var/www /var/backup'
```      
      
## GPG Encryption

### Generate GPG Key-Pair

To generate gpg keys use the following snippet:
      
```
gpg --batch --gen-key <<EOF
%echo Generating a GPG key
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: Duplicity Backup
Name-Comment: Used for backup encryption
Name-Email: duplicity@localhost
Expire-Date: 0
Passphrase: ThisShouldBeYourPersonalUniquePassphrase
%commit
%echo Done
EOF
```      
      
### Export public key
      
```
gpg --output FB37DF3B.public.asc --armor --export FB37DF3B
```      

### Export owner trust
      
```
gpg --export-ownertrust > ownertrust.txt
```      

### Export private key
      
```
gpg --output FB37DF3B.private.asc --armor --export-secret-key FB37DF3B
```      

### Known Hosts

To mark hosts as known hosts
      
```yaml
duplicity_known_hosts:
  - host: 'ftp.example.com'
    key: 'ftp.example.com ssh-rsa AAAAB3NzaC1yc2[...]+MPw=='
    state: 'present'
```

If you are sure that your system supports, it is possible to use ecdsa 
and ed25519 keys.

```
ssh-keyscan -t ecdsa ftp.example.com
ssh-keyscan -t ed25519 ftp.example.com
```

## Duptools

Duptools is a helper script to manage backups. It is installed by 
default but can be disabled by ```duplicity_install_duptools: false```

### Run duptools

Just type ```duptools``` on the command line to get available options:

```
    duptools - manage duplicity backup

    USAGE:

    duptools backup
    duptools list
    duptools status
    duptools restore file [time] dest
    duptools remove [time]

    [time]
    a) now
    b) 2002-01-25T07:00:00+02:00
    c) D=Days, W=Weeks, M=Months, Y=Years, h=hours, m=minutes, s=seconds
```

## Supported OS

 - Debian 9 (Stretch)
 - Debian 8 (Jessie)
 - Ubuntu 18.04 (Bionic Beaver)
 - Ubuntu 16.04 (Xenial Xerus)
 
## Required ansible version

Ansible 2.5+

## License

[MIT License](http://choosealicense.com/licenses/mit/)

## Author Information

 - [Tobias Schifftner](https://twitter.com/tschifftner), [ambimax® GmbH](https://www.ambimax.de)

# TODO

 - Fix reinstall and install another version, now not rewrited file /usr/local/bin/duplicity and not removed pip uninstal duplicity
