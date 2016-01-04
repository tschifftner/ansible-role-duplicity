# Ansible Role: Install and configure duplicity

[![Build Status](https://travis-ci.org/tschifftner/ansible-role-duplicity.svg)](https://travis-ci.org/tschifftner/ansible-role-duplicity)

Installs duplicity from source and handles backup tasks on Debian/Ubuntu linux servers.

## Requirements

ansible 1.9+

## Dependencies

None.

## Installation

```
$ ansible-galaxy install tschifftner.duplicity
```

## Example Playbook

Available variables are listed below, along with default values (see `defaults/main.yml`):

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

It's recommended to put all vars in an external file.
    
    - hosts: webservers
      vars_files:
        - duplicity-settings.yml
    
      roles:
         - { role: tschifftner.duplicity }

## Tips
 - Use ```ssh-keyscan -t rsa example.org``` to get ssh-key for a server (used in duplicity_known_hosts variable)
 - Its possible to write cronjobs in multiple lines. But this causes failure in idempotence! For example:
 
```
 command: >
   duplicity remove-older-than 2M --force --extra-clean $FTP_SERVER;
   duplicity cleanup --force $FTP_SERVER
```

This will always result in changed!      
      
## License

MIT / BSD

## Author Information

 - Tobias Schifftner, @tschifftner
