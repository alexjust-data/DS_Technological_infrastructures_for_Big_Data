<blockquote style="background-color: #e0f2fe; color: black; border-left: 5px solid #2196f3; padding: 10px;">
Sobre OpenNebula (o AWS) desplegar con Ansible un Stack LAMP (Linux Apache
Mysql/MariaDB PHP) con los paquetes necesarios y con una página de prueba que evalúe
funcionalmente la infraestructura desplegada.

El playbook deberá en grandes apartados hacer:

a) conectase al host remoto y ejecutar las tareas
b) Instalar los paquetes necesarios (Apache, Mariadb, php)
c) Habilitar los servicios HTTP y poner el marcha los servidores (Apache, MariaDB).
d) Copiar la página de prueba funcional del php (puede ser local o un ejemplo remoto)

La prueba deberá mostrar todos los pasos y finalmente el acceso y prestaciones de la
página web desplegada.
</blockquote>

```sh
➜  ~ nano lamp_playbook.yml 
➜  ~ cat lamp_playbook.yml 
---
---
- name: Deploy LAMP stack on remote host
  hosts: lamp_servers
  become: yes
  vars_files:
    - vault.yml

  tasks:
    - name: Ensure no other apt processes are running
      shell: |
        pids=$(ps aux | grep -v grep | grep -E 'apt|dpkg' | awk '{print $2}')
        if [ -n "$pids" ]; then
          kill -9 $pids
        fi
      ignore_errors: yes

    - name: Ensure no dpkg locks are present
      file:
        path: /var/lib/dpkg/lock-frontend
        state: absent
      become: yes

    - name: Ensure no dpkg locks are present (2)
      file:
        path: /var/lib/dpkg/lock
        state: absent
      become: yes

    - name: Configure dpkg in case of inconsistencies
      shell: dpkg --configure -a
      become: yes
      ignore_errors: yes

    - name: Update and upgrade apt packages
      apt:
        update_cache: yes
        upgrade: dist
      retries: 5
      delay: 30
      register: update_result
      until: update_result is succeeded

    - name: Preconfigure MariaDB root password
      debconf:
        name: "mariadb-server"
        question: "mysql-server/root_password"
        value: "{{ mysql_root_password }}"
        vtype: "password"

    - name: Preconfigure MariaDB root password again
      debconf:
        name: "mariadb-server"
        question: "mysql-server/root_password_again"
        value: "{{ mysql_root_password }}"
        vtype: "password"

    - name: Install Apache
      apt:
        name: apache2
        state: present

    - name: Install MySQL/MariaDB
      apt:
        name: mariadb-server
        state: present

    - name: Install PHP and modules
      apt:
        name:
          - php
          - php-mysql
          - libapache2-mod-php
        state: present

    - name: Start and enable Apache service
      service:
        name: apache2
        state: started
        enabled: yes

    - name: Start and enable MariaDB service
      service:
        name: mariadb
        state: started
        enabled: yes

    - name: Set root password for MariaDB
      community.mysql.mysql_user:
        name: root
        host: localhost
        password: "{{ mysql_root_password }}"
        login_user: root
        login_password: "{{ mysql_root_password }}"
        state: present
        check_implicit_admin: true

    - name: Remove anonymous users
      mysql_user:
        name: ''
        host_all: true
        state: absent
        login_user: root
        login_password: "{{ mysql_root_password }}"

    - name: Disallow root login remotely
      mysql_user:
        name: root
        host: '%'
        state: absent
        login_user: root
        login_password: "{{ mysql_root_password }}"

    - name: Remove test database
      mysql_db:
        name: test
        state: absent
        login_user: root
        login_password: "{{ mysql_root_password }}"

    - name: Reload privilege tables
      mysql_query:
        query: "FLUSH PRIVILEGES;"
        login_user: root
        login_password: "{{ mysql_root_password }}"

    - name: Create a MySQL database
      community.mysql.mysql_db:
        name: test_db
        state: present
        login_user: root
        login_password: "{{ mysql_root_password }}"

    - name: Create a MySQL user with privileges
      community.mysql.mysql_user:
        name: test_user
        password: "{{ mysql_user_password }}"
        priv: 'test_db.*:ALL'
        state: present
        login_user: root
        login_password: "{{ mysql_root_password }}"

    - name: Copy PHP test page
      copy:
        content: |
          <?php
          phpinfo();
          ?>
        dest: /var/www/html/info.php
        owner: www-data
        group: www-data
        mode: '0644'

    - name: Ensure Apache is running
      service:
        name: apache2
        state: started

    - name: Ensure MariaDB is running
      service:
        name: mariadb
        state: started
```

**Creando credenciales MySQL, MariaDB**

```sh
➜  ~ nano vault.yml
➜  ~ cat vault.yml

    mysql_root_password: 'root_password_here'
    mysql_user_password: 'user_password_here'
```

**Encriptando**

```sh
➜  ~ ansible-vault encrypt vault.yml

    New Vault password: 
    Confirm New Vault password: 
    Encryption successful
```

**Inventario**

```sh
➜  ~ nano hosts.ini 
➜  ~ cat hosts.ini 

    [lamp_servers]
    master.hadoop.local ansible_host=84.88.58.69 ansible_user=root ansible_ssh_private_key_file=~/.ssh/id_rsa ansible_port=55000
```

**Instalar la colección community.mysql:**

```sh
➜  ~ ansible-galaxy collection install community.mysql

Starting galaxy collection install process
Nothing to do. All requested collections are already installed. If you want to reinstall them, consider using `--force`.
```

**Ejecutando**

```sh
➜  ~ ansible-playbook -i hosts.ini lamp_playbook.yml --ask-vault-pass -vvv

...
...
...

PLAY RECAP *****************************************************************************
master.hadoop.local        : ok=23   changed=9    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```



**http://84.88.58.69/info.php**

![](/img/33.png)


**http://84.88.58.69/test_db.php**


![](/img/34.png)



<blockquote style="background-color: #e0f2fe; color: black; border-left: 5px solid #2196f3; padding: 10px;">
Utilizar Vagrant y como provider Virtualbox (sobre la máquina local o sobre una MV en
OpenNebula) para crear mediante Apache un Sitio-web. Para desplegarlo se utilizará un
playbook (Ansible) que deberá configurar el site para que tenga una página principal
/var/www/html y un directorio privado /var/www/html/secure/ al que se podrá acceder
con usuario y passwd.
</blockquote>


Cómo Funciona Vagrant con VirtualBox?  

Cuando usas Vagrant para crear y gestionar una máquina virtual, Vagrant automatiza muchos de los pasos que normalmente harías manualmente en VirtualBox. Esto incluye:
* Descargar la imagen (box) de Ubuntu especificada en el Vagrantfile.
* Crear y configurar una máquina virtual en VirtualBox.
* Provisionar la máquina virtual con herramientas como Ansible, para configurar software y servicios en la máquina virtual.


**Instalo Vagrant**

```sh
brew tap hashicorp/tap
brew install hashicorp/tap/hashicorp-vagrant
```

**Configurar el Vagrantfile**

```sh
➜  cat Vagrantfile 

    Vagrant.configure("2") do |config|
    config.vm.box = "ubuntu/focal64"  # Especificación de la caja de Ubuntu
    config.vm.network "forwarded_port", guest: 80, host: 8080 # Configuración del reenvío de puertos

    config.vm.provider "virtualbox" do |vb| # Configuración del proveedor VirtualBox en este caso
        vb.name = "Ubuntu-24.04"  
        vb.customize ["modifyvm", :id, "--memory", "2048"]
        vb.customize ["modifyvm", :id, "--cpus", "2"]
    end

    config.vm.provision "ansible_local" do |ansible| # Provisionamiento usando Ansible
        ansible.playbook = "playbook.yml"
    end
    end
```


**Creo Playbook de Ansible para el sitio web**

```sh
➜  cat playbook.yml

---
- hosts: all
  become: yes

  tasks:
    # Instalación de Apache y otros paquetes necesarios
    - name: Instalar Apache 
      apt:
        name: apache2
        state: present
        update_cache: yes

    - name: Instalar pip y passlib
      apt:
        name: "{{ item }}"
        state: present
      with_items:
        - python3-pip
        - python3-passlib

    # Creación de directorios y páginas HTML
    - name: Crear directorios para el sitio web 
      file:
        path: "{{ item }}"
        state: directory
      with_items:
        - /var/www/html
        - /var/www/html/secure

    - name: Crear página principal
      copy:
        dest: /var/www/html/index.html
        content: "<h1>Bienvenido a la página principal</h1>"

    - name: Crear página privada
      copy:
        dest: /var/www/html/secure/index.html
        content: "<h1>Bienvenido a la página privada</h1>"

    - name: Crear archivo de configuración para el directorio seguro si no existe
      file:
        path: /etc/apache2/conf-available/secure.conf
        state: touch
    
    # Configuración del directorio seguro con autenticación básica
    - name: Configurar autenticación para el directorio privado
      blockinfile:
        path: /etc/apache2/conf-available/secure.conf
        block: |
          <Directory /var/www/html/secure>
              AuthType Basic
              AuthName "Restricted Content"
              AuthUserFile /etc/apache2/.htpasswd
              Require valid-user
          </Directory>

    # Creación de un usuario para autenticación básica
    - name: Crear usuario para autenticación básica
      community.general.htpasswd:
        path: /etc/apache2/.htpasswd
        name: usuario
        password: passwd

    # Habilitación y reinicio de Apache
    - name: Habilitar el sitio seguro
      shell: a2enconf secure

    - name: Reiniciar Apache
      service:
        name: apache2
        state: restarted
```

**Conexión de Vagrant**

* Conectar a la VM: Vagrant se conectará a la máquina virtual que ya está corriendo.  
* Ejecutar el provisionador: Vagrant ejecutará Ansible localmente dentro de la VM para ejecutar el playbook playbook.yml.

Nota :
* Si necesitas reiniciar la VM y volver a aplicar la provisión en un estado limpio, puedes utilizar :
  * `vagrant destroy -f`
  * `vagrant up`

```sh
➜  vagrant provision

    ==> default: Running provisioner: ansible_local...
        default: Running ansible-playbook...

        PLAY [all] *********************************************************************

        TASK [Gathering Facts] *********************************************************
        ok: [default]

        TASK [Instalar Apache] *********************************************************
        ok: [default]

        TASK [Instalar pip y passlib] **************************************************
        changed: [default] => (item=python3-pip)
        changed: [default] => (item=python3-passlib)

        TASK [Crear directorios para el sitio web] *************************************
        ok: [default] => (item=/var/www/html)
        ok: [default] => (item=/var/www/html/secure)

        TASK [Crear página principal] **************************************************
        ok: [default]

        TASK [Crear página privada] ****************************************************
        ok: [default]

        TASK [Crear archivo de configuración para el directorio seguro si no existe] ***
        changed: [default]

        TASK [Configurar autenticación para el directorio privado] *********************
        ok: [default]

        TASK [Crear usuario para autenticación básica] *********************************
        changed: [default]

        TASK [Habilitar el sitio seguro] ***********************************************
        changed: [default]

        TASK [Reiniciar Apache] ********************************************************
        changed: [default]

        PLAY RECAP *********************************************************************
        default  : ok=11   changed=5    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

**COMPROVACIONES**

```sh
➜  vagrant status

    Current machine states:

    default                   running (virtualbox)

    The VM is running. To stop this VM, you can run `vagrant halt` to
    shut it down forcefully, or you can run `vagrant suspend` to simply
    suspend the virtual machine. In either case, to restart it again,
    simply run `vagrant up`.
```


**Acceder a la máquina virtual mediante SSH**

```sh
➜  vagrant ssh            

    Welcome to Ubuntu 20.04.6 LTS (GNU/Linux 5.4.0-182-generic x86_64)

    * Documentation:  https://help.ubuntu.com
    * Management:     https://landscape.canonical.com
    * Support:        https://ubuntu.com/pro

    System information as of Wed Jun 12 10:59:06 UTC 2024

    System load:  0.08              Processes:               127
    Usage of /:   6.2% of 38.70GB   Users logged in:         0
    Memory usage: 19%               IPv4 address for enp0s3: 10.0.2.15
    Swap usage:   0%


    Expanded Security Maintenance for Applications is not enabled.

    8 updates can be applied immediately.
    To see these additional updates run: apt list --upgradable

    1 additional security update can be applied with ESM Apps.
    Learn more about enabling ESM Apps service at https://ubuntu.com/esm

    New release '22.04.3 LTS' available.
    Run 'do-release-upgrade' to upgrade to it.
```

**Status apache en MV y verifico los servicios en la máquina virtual**

```sh
vagrant@ubuntu-focal:~$ sudo systemctl status apache2
    ● apache2.service - The Apache HTTP Server
        Loaded: loaded (/lib/systemd/system/apache2.service; enabled; vendor preset: enabled)
        Active: active (running) since Wed 2024-06-12 10:52:28 UTC; 6min ago
        Docs: https://httpd.apache.org/docs/2.4/
        Process: 13166 ExecStart=/usr/sbin/apachectl start (code=exited, status=0/SUCCESS)
    Main PID: 13184 (apache2)
        Tasks: 55 (limit: 2324)
        Memory: 5.7M
        CGroup: /system.slice/apache2.service
                ├─13184 /usr/sbin/apache2 -k start
                ├─13185 /usr/sbin/apache2 -k start
                └─13186 /usr/sbin/apache2 -k start

    Jun 12 10:52:28 ubuntu-focal systemd[1]: Starting The Apache HTTP Server...
    Jun 12 10:52:28 ubuntu-focal apachectl[13183]: AH00558: apache2: Could not reliably determine the server's fully qualified domain name, u>
    Jun 12 10:52:28 ubuntu-focal systemd[1]: Started The Apache HTTP Server.
```

**Navegar por el sistema de archivos**

```sh
vagrant@ubuntu-focal:~$ ls /var/www/html
    index.html  secure
```

Desde navegador local

![](/img/35.png)

```sh
vagrant@ubuntu-focal:~$ cat /var/www/html/index.html

    <h1>Bienvenido a la página principal</h1>
```

desde navegador local

![](/img/36.png)

```sh
vagrant@ubuntu-focal:~$ cat /var/www/html/secure/index.html

    <h1>Bienvenido a la página privada</h1>
```

desde navegador local

![](/img/37.png)




<blockquote style="background-color: #e0f2fe; color: black; border-left: 5px solid #2196f3; padding: 10px;">
Utilizando Terraform y como provider Docker, desplegar un reverse proxy. Mostrar
funcionalidad y analizar todos los pasos de aprovisionamiento, funcionalidad y
eliminación del recurso.
</blockquote>


**Instalo Terraform y Docker**

```sh
➜  ~ brew tap hashicorp/tap
➜  ~ brew install hashicorp/tap/terraform
```

**Configuro el Archivo main.tf de Terraform**

```sh
➜  ~ mkdir terraform-reverse-proxy
➜  ~ cd terraform-reverse-proxy
➜  terraform-reverse-proxy nano main.tf
➜  terraform-reverse-proxy cat main.tf

        provider "docker" {
        host = "unix:///var/run/docker.sock"
        }

        resource "docker_image" "nginx" {
        name = "nginx:latest"
        keep_locally = false
        }

        resource "docker_container" "nginx" {
        image = docker_image.nginx.latest
        name  = "nginx_reverse_proxy"
        ports {
            internal = 80
            external = 8080
        }
        volumes {
            host_path      = "${path.module}/nginx.conf"
            container_path = "/etc/nginx/nginx.conf"
        }
        }

        # Nginx Configuration File
        resource "local_file" "nginx_conf" {
        content = <<EOF
        events {
        worker_connections  1024;
        }

        http {
        server {
            listen 80;
            
            location / {
            proxy_pass http://example.com;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            }
        }
        }
        EOF
        filename = "${path.module}/nginx.conf"
        }

```

**Inicializar y Aplicar Terraform**

```sh
➜  terraform-reverse-proxy terraform init

        Initializing the backend...

        Initializing provider plugins...
        - Finding kreuzwerker/docker versions matching "~> 2.15.0"...
        - Finding latest version of hashicorp/local...
        - Installing kreuzwerker/docker v2.15.0...
        - Installed kreuzwerker/docker v2.15.0 (self-signed, key ID BD080C4571C6104C)
        - Installing hashicorp/local v2.5.1...
        - Installed hashicorp/local v2.5.1 (signed by HashiCorp)

        Partner and community providers are signed by their developers.
        If you'd like to know more about provider signing, you can read about it here:
        https://www.terraform.io/docs/cli/plugins/signing.html

        Terraform has created a lock file .terraform.lock.hcl to record the provider
        selections it made above. Include this file in your version control repository
        so that Terraform can guarantee to make the same selections by default when
        you run "terraform init" in the future.

        Terraform has been successfully initialized!

        You may now begin working with Terraform. Try running "terraform plan" to see
        any changes that are required for your infrastructure. All Terraform commands
        should now work.

        If you ever set or change modules or backend configuration for Terraform,
        rerun this command to reinitialize your working directory. If you forget, other
        commands will detect it and remind you to do so if necessary.
```

**Verificar el Despliegue**

