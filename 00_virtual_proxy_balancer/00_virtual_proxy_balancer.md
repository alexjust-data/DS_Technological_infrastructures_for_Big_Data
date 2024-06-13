##  Despliegue de un servicio de proxy balanced sobre un clúster virtualizado.

Se va a crear un clúster virtualizado con el siguiente esquema:

![](img/1.png)

> ---
> **1.** Utilizando Debian11, se crean 4 MV: server con dos IP (pública y privada), y 3 MV con IP privadas solo (en principio se pueden crear con una pública para entrar remotamente, cambiar el passwd de root y después liberarla ya que es un recurso restringido) dado que estas MV se tendrán que conectar y configurar desde el Server.
> 
> ---

![](img/2.png)

Se han creado 1 Server con ip pública y otra privada; además 3 nodos sólo con clave privada.

**Accediendo al Server desde local**

```sh
# clave generada
➜  ~ cat .ssh/id_rsa.pub
            ssh-rsa AAAAB3NzaC ... y+Uq67gM= alex@Alexs-MacBook-Pro.local

#  indicates that the SSH client has detected a change in the host key
➜  ~ ssh -i .ssh/id_rsa root@84.88.58.69 -p 55000 
            @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
            @    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
            @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
            IT IS POSSIBLE THAT SOMEONE IS DOING SOMETHING NASTY!
            Someone could be eavesdropping on you right now (man-in-the-middle attack)!
            It is also possible that a host key has just been changed.
            The fingerprint for the ED25519 key sent by the remote host is
            SHA256:dTv/QOusd5ae5qlJySt1S/rjWFCzJX03KAvpo4em58Y.
            Please contact your system administrator.
            Add correct host key in /Users/alex/.ssh/known_hosts to get rid of this message.
            Offending ECDSA key in /Users/alex/.ssh/known_hosts:25
            Host key for [84.88.58.69]:55000 has changed and you have requested strict checking.
            Host key verification failed.

# edit the known_hosts file manually with a text editor
➜  ~ ssh-keygen -R "[84.88.58.69]:55000"
            # Host [84.88.58.69]:55000 found: line 24
            # Host [84.88.58.69]:55000 found: line 25
            /Users/alex/.ssh/known_hosts updated.
            Original contents retained as /Users/alex/.ssh/known_hosts.old

# accediendo al Sever de ON
➜  ~ ssh -i .ssh/id_rsa root@84.88.58.69 -p 55000          
            The authenticity of host '[84.88.58.69]:55000 ([84.88.58.69]:55000)' can't be established.
            ED25519 key fingerprint is SHA256:dTv/QOusd5ae5qlJySt1S/rjWFCzJX03KAvpo4em58Y.
            This key is not known by any other names.
            Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
            Warning: Permanently added '[84.88.58.69]:55000' (ED25519) to the list of known hosts.
            Linux localhost.localdomain 5.10.0-9-amd64 #1 SMP Debian 5.10.70-1 (2021-09-30) x86_64

            The programs included with the Debian GNU/Linux system are free software;
            the exact distribution terms for each program are described in the
            individual files in /usr/share/doc/*/copyright.

            Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
            permitted by applicab
root@localhost:~# 
```

La única razón por la que tendrías que copiar la clave privada a una máquina sería para utilizar esa máquina como un "salto" para conectarte a otras máquinas más adelante en la cadena de conexión. Esto se hace a veces en entornos donde tienes que pasar por una máquina intermedia para acceder a otras máquinas que no son accesibles directamente desde tu local. Aún así, esto debería hacerse con precaución y solo cuando no haya alternativas más seguras disponibles.

Consideraciones de seguridad adicionales:

* Antes de transferir tu clave privada, asegúrate de que realmente quieres hacerlo y comprende los riesgos. Como se mencionó antes, esta no es una práctica recomendada. Por lo general, solo deberías transferir tu clave pública a otros sistemas.
* Una vez que hayas terminado de usar la clave privada en el servidor de salto para la sesión actual, es aconsejable eliminarla del servidor de salto para mantener la seguridad, a menos que tengas una razón sólida para mantenerla allí y las políticas de seguridad de tu entorno lo permitan.
* Asegúrate de que el servidor de salto esté configurado con las medidas de seguridad apropiadas, ya que tener una clave privada en este servidor presenta un riesgo significativo si el servidor se ve comprometido.

**Tranfiriendo Clave privada al servidor de salto (Server con IP pública)**

```sh
# transfiriendo clave privada al Server de salto
➜  ~ scp -P 55000 .ssh/id_rsa root@84.88.58.69:/root/.ssh     
id_rsa   

# accedo al Server de salto
➜  ~ ssh -i .ssh/id_rsa root@84.88.58.69 -p 55000 

root@localhost:~# ls -la /root/.ssh
        total 20
        drwx------ 2 root root 4096 Mar 21 10:15 .
        drwx------ 3 root root 4096 Mar 21 10:10 ..
        -rw------- 1 root root  582 Mar 21 09:27 authorized_keys
        -rw------- 1 root root 2622 Mar 21 10:47 id_rsa
        -rw-r--r-- 1 root root  222 Mar 21 10:15 known_hosts
```

* **authorized_keys**: Este archivo contiene las claves públicas SSH que están autorizadas para acceder a este servidor. Cualquier persona que posea la clave privada correspondiente a una clave pública en este archivo podrá conectarse al servidor.
* **id_rsa**: Este es tu archivo de clave privada SSH. Este archivo debería mantenerse seguro y no debería ser copiado a otros servidores o compartido con otras personas.
* **known_hosts**: Este archivo contiene las huellas digitales de los hosts a los cuales te has conectado previamente mediante SSH. Esto es utilizado por el cliente SSH para verificar que no está ocurriendo un ataque de intermediario (man-in-the-middle).

```sh
# accedo a nodo 1 dende Server
root@localhost:~# ssh -i /root/.ssh/id_rsa root@192.168.0.14 -p 55000

    The authenticity of host '[192.168.0.14]:55000 ([192.168.0.14]:55000)' can't be established.
    ECDSA key fingerprint is SHA256:bDtM+S1Q7UZ961TtfrYkpj6WFmtZER6LKKTeZlnum3Q.
    Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
    Warning: Permanently added '[192.168.0.14]:55000' (ECDSA) to the list of known hosts.

    Linux localhost.localdomain 5.10.0-9-amd64 #1 SMP Debian 5.10.70-1 (2021-09-30) x86_64

    The programs included with the Debian GNU/Linux system are free software;
    the exact distribution terms for each program are described in the
    individual files in /usr/share/doc/*/copyright.
    Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
    permitted by applicable law.

# estoy en nodo1 lo confirma mi ip 192.168.0.14
root@localhost:~# ip addr

        1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
            link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
            inet 127.0.0.1/8 scope host lo
            valid_lft forever preferred_lft forever
            inet6 ::1/128 scope host 
            valid_lft forever preferred_lft forever
        2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
            link/ether 02:00:c0:a8:00:0f brd ff:ff:ff:ff:ff:ff
            altname enp0s5
            altname ens5
            inet 192.168.0.14/24 brd 192.168.0.255 scope global eth0
            valid_lft forever preferred_lft forever
            inet6 fe80::c0ff:fea8:f/64 scope link 
            valid_lft forever preferred_lft forever

# el cambio el nombre
root@localhost:~#  hostnamectl set-hostname nodo1
root@localhost:~# hostname
        nodo1

root@localhost:~# sudo reboot
    sudo: unable to resolve host nodo1: Temporary failure in name resolution
    
root@localhost:~# ssh -i /root/.ssh/id_rsa root@192.168.0.14 -p 55000
        Linux nodo1 5.10.0-9-amd64 
        The programs included with the Debian GNU/Linux system are free software;
        the exact distribution terms for each program are described in the
        individual files in /usr/share/doc/*/copyright.

        Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
        permitted by applicable law.
        Last login: Thu Mar 21 11:20:15 2024 from 192.168.0.11

# estoy dentro de nodo 1
root@nodo1:~# 
```
Repite lo mismo para los otros nodos 2

```sh
root@localhost:~# ssh -i /root/.ssh/id_rsa root@192.168.0.15 -p 55000
root@localhost:~# ip addr
root@localhost:~#  hostnamectl set-hostname nodo2
root@localhost:~# hostname
        nodo2
root@localhost:~# sudo reboot
root@nodo2:~# 
```

Repite lo mismo para los otros nodos 3

```sh
root@localhost:~# ssh -i /root/.ssh/id_rsa root@192.168.0.16 -p 55000
root@localhost:~# ip addr
root@localhost:~# hostnamectl set-hostname nodo3
root@localhost:~# hostname
        nodo3
root@localhost:~# sudo reboot
root@nodo3:~# 
```

> ___
> **2.** Configurar Server con ip_forward y NAT para que Node1-3 tengan conexión a Internet a través de server.
> ___

**Habilitar IP Forwarding**

```bash
# # Habilitar IP Forwarding:
# root@localhost:~#  echo 1 > /proc/sys/net/ipv4/ip_forward

# Habilita IP forwarding en el servidor
root@localhost:~# nano /etc/sysctl.conf

        # Uncomment the next line to enable packet forwarding for IPv4
        net.ipv4.ip_forward=1

# Aplicando cambios
root@localhost:~# sysctl -p
net.ipv4.ip_forward = 1
```

**Configurar NAT**

```sh
# identificar el nombre de mi interfaz (en este caso es eth0)
root@localhost:~# ip addr
        1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
            link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
            inet 127.0.0.1/8 scope host lo
            valid_lft forever preferred_lft forever
            inet6 ::1/128 scope host 
            valid_lft forever preferred_lft forever
        2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
            link/ether 02:00:c0:a8:00:0b brd ff:ff:ff:ff:ff:ff
            altname enp0s3
            altname ens3
            inet 192.168.0.11/24 brd 192.168.0.255 scope global eth0
            valid_lft forever preferred_lft forever
            inet6 fe80::c0ff:fea8:b/64 scope link 
            valid_lft forever preferred_lft forever
        3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
            link/ether 02:00:54:58:3a:45 brd ff:ff:ff:ff:ff:ff
            altname enp0s4
            altname ens4
            inet 84.88.58.69/26 brd 84.88.58.127 scope global eth1
            valid_lft forever preferred_lft forever
            inet6 fe80::54ff:fe58:3a45/64 scope link 
            valid_lft forever preferred_lft forever

# Este comando configura iptables para hacer NAT de los paquetes que salen del servidor.
root@localhost:~# iptables -t nat -A POSTROUTING -o eth1 -j MASQUERADE

# añado reglas de tráfico según enunciado ejercicio 2
root@localhost:~# iptables -A FORWARD -i eth1 -o eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT
root@localhost:~# iptables -A FORWARD -i eth0 -o eth1 -j ACCEPT

# Hacemos las reglas persistentes (si a todo)
root@localhost:~# sudo apt-get update
root@localhost:~# apt-get install iptables-persistent
```
`iptables -A FORWARD -i eth1 -o eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT`:  
Esta regla permite que el tráfico que ha sido iniciado desde los nodos (Node1-3) y que ha salido a través del servidor (haciendo NAT) retorne al servidor y de ahí a los nodos. Esto significa que cuando un nodo inicia una conexión a Internet, las respuestas de esa conexión (que son paquetes "RELACIONADOS" o "ESTABLECIDOS") están permitidas para regresar a través del servidor.

`iptables -A FORWARD -i eth0 -o eth1 -j ACCEPT`:  
Esta regla permite que cualquier tráfico originado en la red privada (desde los nodos) sea reenviado a través del servidor hacia Internet. Esto es necesario para que los nodos puedan iniciar conexiones hacia fuera.

```sh
# Configuro la red en los nodos
root@localhost:~# ip route add default via 192.168.0.11
    RTNETLINK answers: File exists

root@localhost:~# ip route show
    default via 84.88.58.65 dev eth1 onlink 
    84.88.58.64/26 dev eth1 proto kernel scope link src 84.88.58.69 
    192.168.0.0/24 dev eth0 proto kernel scope link src 192.168.0.11 

# verificando
root@localhost:~# ping -c 3 google.com
    PING google.com (142.250.184.14) 56(84) bytes of data.
    64 bytes from mad41s10-in-f14.1e100.net (142.250.184.14): icmp_seq=1 ttl=119 time=10.2 ms
    64 bytes from mad41s10-in-f14.1e100.net (142.250.184.14): icmp_seq=2 ttl=119 time=10.4 ms
    64 bytes from mad41s10-in-f14.1e100.net (142.250.184.14): icmp_seq=3 ttl=119 time=10.3 ms
    --- google.com ping statistics ---
    3 packets transmitted, 3 received, 0% packet loss, time 2004ms
    rtt min/avg/max/mdev = 10.188/10.263/10.350/0.066 ms
```

**Instalo Apache en servidor y cambio página index**

```sh
root@localhost:~# apt-get update
root@localhost:~# apt-get install apache2

# cambiando index.html
root@localhost:~# cd /var/www/html
root@localhost:/var/www/html# sudo nano index.html
root@localhost:/var/www/html# cat index.html
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta http-equiv="X-UA-Compatible" content="IE=edge">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>SERVER</title>
    </head>
    <body>
        <h1>This is SERVER</h1>
        <p>Welcome to the SERVER of our network.</p>
        <!-- Add your custom content here -->
    </body>
    </html>
```

Los nodos ya tienen configurado el servidor Debian como puerta de enlace predeterminada para que puedan acceder a Internet a través de él.

**Verificar la configuración de NAT en Server:**

```sh
# Verificar la configuración de iptables
root@localhost:~# iptables -t nat -L -v -n
    Chain PREROUTING (policy ACCEPT 0 packets, 0 bytes)
    pkts bytes target     prot opt in     out     source               destination         

    Chain INPUT (policy ACCEPT 0 packets, 0 bytes)
    pkts bytes target     prot opt in     out     source               destination         

    Chain OUTPUT (policy ACCEPT 0 packets, 0 bytes)
    pkts bytes target     prot opt in     out     source               destination         

    Chain POSTROUTING (policy ACCEPT 0 packets, 0 bytes)
    pkts bytes target     prot opt in     out     source               destination         
    138 11230 MASQUERADE  all  --  *      eth1    0.0.0.0/0            0.0.0.0/0           

root@localhost:~# iptables -L -v -n
    Chain INPUT (policy ACCEPT 0 packets, 0 bytes)
    pkts bytes target     prot opt in     out     source               destination         

    Chain FORWARD (policy ACCEPT 0 packets, 0 bytes)
    pkts bytes target     prot opt in     out     source               destination         
    28  2548 ACCEPT     all  --  eth1   eth0    0.0.0.0/0            0.0.0.0/0            state RELATED,ESTABLISHED
    28  2104 ACCEPT     all  --  eth0   eth1    0.0.0.0/0            0.0.0.0/0           

    Chain OUTPUT (policy ACCEPT 0 packets, 0 bytes)
    pkts bytes target     prot opt in     out     source               destination         
```


>---
> **3.** Actualizar Debian11 e instalar Apache2 sobre todas las máquinas cambiando la página por defecto creando una página con cierto contenido (texto e imágenes) pero que sean todas diferentes y que identifiquen el nodo.
>
>---


**Doy DNS a nodos y agregamos la puerta de enlace predeterminada 192.168.0.11:**

Estos pasos permiten el tráfico de Internet hacia y desde los nodos a través del servidor,

**nodo1**

```sh
# conecto al nodo1
root@localhost:~# ssh -v -i /root/.ssh/id_rsa -p 55000 root@192.168.0.14

# Esto establecerá el servidor DNS de Google como tu servidor DNS predeterminado
root@nodo1:~# echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
    sudo: unable to resolve host nodo1: Temporary failure in name resolution
    nameserver 8.8.8.8

root@nodo1:~# cat /etc/resolv.conf
nameserver 8.8.8.8

# Resolver el problema de nombre de host en el nodo1:
# Esto debería corregir los errores relacionados con "sudo: unable to resolve host nodo1".
root@nodo1:~# echo "127.0.1.1 nodo1" | sudo tee -a /etc/hosts
127.0.1.1 nodo1

# añado esta linea 127.0.1.1	nodo1
root@nodo1:~# cat /etc/hosts
    127.0.0.1	localhost
    ::1		localhost ip6-localhost ip6-loopback
    ff02::1		ip6-allnodes
    ff02::2		ip6-allrouters

    127.0.1.1 nodo1
    127.0.1.1 nodo1

# Agregamos la puerta de enlace predeterminada
root@nodo1:~# sudo ip route add default via 192.168.0.11
```

**nodo2**

```sh
# conecto al nodo2
root@localhost:~# ssh -v -i /root/.ssh/id_rsa -p 55000 root@192.168.0.15

root@nodo2:~# echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
    sudo: unable to resolve host nodo2: Temporary failure in name resolution
    nameserver 8.8.8.8

root@nodo2:~# echo "127.0.1.1 nodo2" | sudo tee -a /etc/hosts
    sudo: unable to resolve host nodo2: Temporary failure in name resolution
    127.0.1.1 nodo2

# cambio el nombre
root@nodo2:~# sudo hostname nodo2
root@nodo2:~# echo "nodo2" | sudo tee /etc/hostname
    nodo2

root@nodo2:~# cat /etc/hosts
    127.0.0.1	localhost
    ::1		localhost ip6-localhost ip6-loopback
    ff02::1		ip6-allnodes
    ff02::2		ip6-allrouters

    127.0.1.1 nodo2

#  ruta predeterminada
root@nodo2:~# sudo ip route add default via 192.168.0.11

root@nodo2:~# ping -c 4 8.8.8.8
    PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
    64 bytes from 8.8.8.8: icmp_seq=1 ttl=118 time=10.9 ms
    64 bytes from 8.8.8.8: icmp_seq=2 ttl=118 time=10.6 ms
    64 bytes from 8.8.8.8: icmp_seq=3 ttl=118 time=10.7 ms
    ^C
    --- 8.8.8.8 ping statistics ---
    3 packets transmitted, 3 received, 0% packet loss, time 2003ms
    rtt min/avg/max/mdev = 10.592/10.734/10.944/0.151 ms
```

**nodo3**

```sh
root@nodo3:~# echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
    sudo: unable to resolve host nodo3: Temporary failure in name resolution
    nameserver 8.8.8.8

root@nodo3:~# echo "127.0.1.1 nodo3" | sudo tee -a /etc/hosts
    sudo: unable to resolve host nodo3: Temporary failure in name resolution
    127.0.1.1 nodo3

root@nodo3:~# sudo hostname nodo3
root@nodo3:~# echo "nodo3" | sudo tee /etc/hostname
    nodo3

root@nodo3:~#  cat /etc/hosts
    127.0.0.1	localhost
    ::1		localhost ip6-localhost ip6-loopback
    ff02::1		ip6-allnodes
    ff02::2		ip6-allrouters

    127.0.1.1 nodo3

# agregando ruta a ip publica
root@nodo3:~# sudo ip route add default via 192.168.0.11

root@nodo3:~# ping -c 4 8.8.8.8
    PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
    64 bytes from 8.8.8.8: icmp_seq=1 ttl=118 time=10.9 ms
    64 bytes from 8.8.8.8: icmp_seq=2 ttl=118 time=10.8 ms
    64 bytes from 8.8.8.8: icmp_seq=3 ttl=118 time=10.7 ms
    ^C
    --- 8.8.8.8 ping statistics ---
    3 packets transmitted, 3 received, 0% packet loss, time 2003ms
    rtt min/avg/max/mdev = 10.700/10.792/10.870/0.070 ms
```

Ahora que los tres nodos tiene conexion a internet, podemos instalar apache


**Instalando Apache a todos los nodos 1,2,3 : Repite lo mismo en cada nodo**

```sh
# updating the system:
root@nodo1:~# sudo apt update
root@nodo1:~# sudo apt upgrade -y

# Installing Apache2
root@nodo1:~# sudo apt install apache2 -y

root@nodo1:~# cd /var/www/html
root@nodo1:~# sudo nano index.html

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Nodo 1</title>
</head>
<body>
    <h1>This is Nodo 1</h1>
    <p>Welcome to the first node of our network.</p>
    <!-- Add your custom content here -->
</body>
</html>


root@nodo1:~# sudo systemctl restart apache2
root@nodo1:~# sudo systemctl status apache2
    ● apache2.service - The Apache HTTP Server
        Loaded: loaded (/lib/systemd/system/apache2.service; enabled; vendor preset: enabled)
        Active: active (running) since Thu 2024-03-21 19:18:53 UTC; 1min 48s ago
        Docs: https://httpd.apache.org/docs/2.4/
        Process: 24547 ExecStart=/usr/sbin/apachectl start (code=exited, status=0/SUCCESS)
    Main PID: 24551 (apache2)
        Tasks: 55 (limit: 826)
        Memory: 10.6M
            CPU: 74ms
        CGroup: /system.slice/apache2.service
                ├─24551 /usr/sbin/apache2 -k start
                ├─24552 /usr/sbin/apache2 -k start
                └─24553 /usr/sbin/apache2 -k start

    Mar 21 19:18:52 nodo1 systemd[1]: Starting The Apache HTTP Server...
    Mar 21 19:18:53 nodo1 apachectl[24550]: AH00558: apache2: Could not reliably determine the server's fully qualified domain name, using>
    Mar 21 19:18:53 nodo1 systemd[1]: Started The Apache HTTP Server.
```

**Comprovando que puedo acceder al nodo1, nodo2 y nodo3 desde Server**

Esto nos indica que hay conexión, el problema es que no navego desde mi navegador http://192.168.0.14

```sh
root@localhost:~# ping -c 3 192.168.0.14
PING 192.168.0.14 (192.168.0.14) 56(84) bytes of data.
64 bytes from 192.168.0.14: icmp_seq=1 ttl=64 time=0.837 ms
64 bytes from 192.168.0.14: icmp_seq=2 ttl=64 time=0.638 ms
64 bytes from 192.168.0.14: icmp_seq=3 ttl=64 time=0.821 ms

--- 192.168.0.14 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2013ms
rtt min/avg/max/mdev = 0.638/0.765/0.837/0.090 ms
root@localhost:~# ping -c 3 192.168.0.15
PING 192.168.0.15 (192.168.0.15) 56(84) bytes of data.
64 bytes from 192.168.0.15: icmp_seq=1 ttl=64 time=1.77 ms
64 bytes from 192.168.0.15: icmp_seq=2 ttl=64 time=0.767 ms
64 bytes from 192.168.0.15: icmp_seq=3 ttl=64 time=0.784 ms

--- 192.168.0.15 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2003ms
rtt min/avg/max/mdev = 0.767/1.106/1.769/0.468 ms
root@localhost:~# ping -c 3 192.168.0.16
PING 192.168.0.16 (192.168.0.16) 56(84) bytes of data.
64 bytes from 192.168.0.16: icmp_seq=1 ttl=64 time=2.07 ms
64 bytes from 192.168.0.16: icmp_seq=2 ttl=64 time=0.789 ms
64 bytes from 192.168.0.16: icmp_seq=3 ttl=64 time=0.758 ms

--- 192.168.0.16 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2029ms
rtt min/avg/max/mdev = 0.758/1.205/2.069/0.610 ms
root@localhost:~# 

root@localhost:~# curl http://192.168.0.14
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta http-equiv="X-UA-Compatible" content="IE=edge">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Nodo 1</title>
    </head>
    <body>
        <h1>This is Nodo 1</h1>
        <p>Welcome to the first node of our network.</p>
        <!-- Add your custom content here -->
    </body>
    </html>

```


>---
> **4.** Cargar los módulos correspondientes en server para configurar un servicio proxy balanced y
configurarlo para que realice un balanceo por diferentes metodologías (algoritmos).
>
>---

**Habilitar los módulos necesarios para el balanceo de carga**
```sh
a2enmod proxy
a2enmod proxy_http
a2enmod proxy_balancer
a2enmod proxy proxy_http
a2enmod lbmethod_byrequests  # Para el algoritmo round-robin
a2enmod lbmethod_bytraffic   # Para el algoritmo basado en tráfico
a2enmod lbmethod_bybusyness  # Para el algoritmo por ocupación
a2enmod status               # Para acceder al balance-manager
```

**Crear o editar el archivo de hosts**
Para "añadir el servidor de entrada en /etc/hosts", generalmente querrías agregar una línea en este archivo que asocie la dirección IP del servidor Apache que actúa como balanceador de carga con el nombre de host que le hayas dado, que en tu ejemplo de configuración es `proxy.netum.org`.

```sh
root@localhost:~# cat /etc/hosts
    127.0.0.1       localhost localhost.localdomain
    ::1		        localhost ip6-localhost ip6-loopback
    ff02::1		    ip6-allnodes
    ff02::2		    ip6-allrouters
    84.88.58.69     proxy.netum.org # he añadido este
```

Al hacer esto, cuando alguien (o un proceso) en tu servidor intente acceder a proxy.netum.org, inmediatamente se resolverá a 84.88.58.69 sin necesidad de consultar un servidor DNS externo. Es útil cuando estás configurando un servicio y aún no has establecido DNS externo, o para sobrescribir el DNS global por razones de redirección local o pruebas.

Este paso es esencialmente para el servidor de balanceo de carga. Si tuvieras que configurar nombres de dominio para cada BalancerMember o nodo específico, también los añadirías al archivo /etc/hosts de manera similar.

**Crear el archivo de configuración del virtual host para el balanceador:**
```sh
root@localhost:~# nano /etc/apache2/sites-available/proxy.conf
root@localhost:~# cat /etc/apache2/sites-available/proxy.conf

    <VirtualHost *:80>
        ServerName proxy.netum.org
        ProxyRequests Off
        <Proxy balancer://mycluster>
            BalancerMember http://192.168.0.14:80
            BalancerMember http://192.168.0.15:80
            BalancerMember http://192.168.0.16:80
            ProxySet lbmethod=byrequests
        </Proxy>

        <Location /balancer-manager>
            SetHandler balancer-manager
            Require host localhost
        </Location>

        ProxyPass /balancer-manager !
        ProxyPass / balancer://mycluster/
        ProxyPassReverse / balancer://mycluster/
    </VirtualHost>
```

Habilito  con `a2ensite proxy.conf` esto crea un enlace simbólico de ese archivo desde el directorio /etc/apache2/sites-available/ al directorio /etc/apache2/sites-enabled/. Esto le dice a Apache que quieres habilitar ese sitio y que lea su configuración cuando el servicio se inicie o reinicie.

```sh
root@localhost:~# a2ensite proxy.conf
root@localhost:~# systemctl reload apache2
root@localhost:~# systemctl restart apache2
```


>---
> **5.** Incorporar una 5ª máquina virtual e instalar un entorno gráfico para realizar evaluaciones
funcionales haciendo peticiones sobre el IP pública y viendo si distribuye bien el contenido en
función del algoritmo escogido en cada recarga de la página del proxy. Analizar también el entorno
del balance-manager que incorpora Apache2.
>
>---

```sh
root@localhost:~# ssh -v -i /root/.ssh/id_rsa -p 55000 root@192.168.0.26
root@localhost:~# ip addr

    1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
        link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
        inet 127.0.0.1/8 scope host lo
        valid_lft forever preferred_lft forever
        inet6 ::1/128 scope host 
        valid_lft forever preferred_lft forever
    2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
        link/ether 02:00:c0:a8:00:1a brd ff:ff:ff:ff:ff:ff
        altname enp0s3
        altname ens3
        inet 192.168.0.26/24 brd 192.168.0.255 scope global eth0
        valid_lft forever preferred_lft forever
        inet6 fe80::c0ff:fea8:1a/64 scope link 
        valid_lft forever preferred_lft forever

root@localhost:~# hostnamectl set-hostname test-client
root@localhost:~# hostname
    test-client


root@test-client:~# echo "nameserver 8.8.8.8" > /etc/resolv.conf
root@test-client:~# cat /etc/resolv.conf
    nameserver 8.8.8.8

root@test-client:~# ip route add default via 192.168.0.11
root@test-client:~# ip route show
    default via 192.168.0.11 dev eth0 
    192.168.0.0/24 dev eth0 proto kernel scope link src 192.168.0.26 

root@test-client:~# ping -c 4 8.8.8.8
    PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
    64 bytes from 8.8.8.8: icmp_seq=1 ttl=118 time=10.7 ms
    64 bytes from 8.8.8.8: icmp_seq=2 ttl=118 time=10.7 ms
    64 bytes from 8.8.8.8: icmp_seq=3 ttl=118 time=10.7 ms
    64 bytes from 8.8.8.8: icmp_seq=4 ttl=118 time=10.7 ms
        --- 8.8.8.8 ping statistics ---
    4 packets transmitted, 4 received, 0% packet loss, time 3004ms
    rtt min/avg/max/mdev = 10.655/10.683/10.724/0.027 ms

root@test-client:~# ping -c 4 google.com
    PING google.com (172.217.17.14) 56(84) bytes of data.
    64 bytes from mad07s09-in-f14.1e100.net (172.217.17.14): icmp_seq=1 ttl=118 time=10.6 ms
    64 bytes from mad07s09-in-f14.1e100.net (172.217.17.14): icmp_seq=2 ttl=118 time=10.7 ms
    64 bytes from mad07s09-in-f14.1e100.net (172.217.17.14): icmp_seq=3 ttl=118 time=10.7 ms
    64 bytes from mad07s09-in-f14.1e100.net (172.217.17.14): icmp_seq=4 ttl=118 time=10.9 ms

    --- google.com ping statistics ---
    4 packets transmitted, 4 received, 0% packet loss, time 3004ms
    rtt min/avg/max/mdev = 10.564/10.713/10.860/0.104 ms
```

**OJO**

Aunque configuré la puerta de enlace `ip route add default via 192.168.0.11` cuando hago `reboot` se desconfigura. Esto le pasará a cuaquier máquina, la solucion es no hacer reboot o cuando lo hagas volver a colocar el gateway

**Instalar el entorno gráfico en test-client**

```sh
root@test-client:~# apt update
root@test-client:~# apt install xfce4 xfce4-goodies lightdm
root@test-client:~# systemctl start lightdm
```

Después de instalar el entorno gráfico y ejecutar systemctl start lightdm, deberías ser llevado automáticamente a la pantalla de login de LightDM donde puedes iniciar sesión con tu usuario y contraseña. Sin embargo, si estás accediendo a través de SSH, no verás esta interfaz gráfica porque SSH es un entorno de línea de comandos.

Para interactuar con el entorno gráfico, necesitas estar sentado físicamente frente a la máquina o utilizar una herramienta que permita el acceso remoto al escritorio gráfico, como VNC, XRDP, o similar. Aquí te explico cómo podrías configurar un acceso VNC, que es una de las opciones más comunes:

```sh
root@test-client:~# apt install tightvncserver
# Server
root@localhost:~# ssh -v -i /root/.ssh/id_rsa -p 55000 root@192.168.0.26
root@test-client:~# vncserver # 6y1axb

        New 'X' desktop is test-client:3
        Starting applications specified in /root/.vnc/xstartup
        Log file is /root/.vnc/test-client:3.log

root@test-client:~# cat /root/.vnc/xstartup

        #!/bin/sh
        xrdb "$HOME/.Xresources"
        xsetroot -solid grey
        #x-terminal-emulator -geometry 80x24+10+10 -ls -title "$VNCDESKTOP Desktop" &
        #x-window-manager &
        # Fix to make GNOME work
        export XKL_XMODMAP_DISABLE=1
        /etc/X11/Xsession
```


Para acceder al entorno de escritorio de la máquina test-client que está en una red privada, no puedes conectarte directamente desde tu máquina local si esta última no se encuentra en la misma red privada.

Dado que la máquina Server es la única con una IP pública y actúa como puente, para alcanzar tu objetivo de realizar evaluaciones de rendimiento desde tu máquina local a través de la máquina test-client, lo mejor será establecer un túnel SSH. Esto te permitirá, de manera segura, redirigir el puerto VNC de test-client a tu máquina local para que puedas interactuar con el entorno gráfico de test-client como si estuvieras físicamente presente en la red privada donde reside.


**Establecer un Túnel SSH para VNC**

```sh
# en máquina local
$ ssh -L 5903:192.168.0.26:5903 -p 55000 -N -f -i ~/.ssh/id_rsa root@84.88.58.69
```

- `L 5903:192.168.0.26:5903` crea un mapeo de puerto de tu máquina local al puerto VNC de test-client.
- `p 55000` especifica el puerto SSH si Server está escuchando en un puerto no estándar.
- `N` indica a SSH que no ejecute un comando remoto.
- `f` pide a SSH que vaya al fondo (background) después de la autenticación.
- `i /path/to/your/key` es el camino a tu llave SSH privada.

Reemplaza usuario con tu nombre de usuario real y ip_publica_del_server con la dirección IP pública de tu Server.
Usa un cliente VNC para conectarte a `localhost:5903`. Esto te conectará a través del túnel SSH al servicio VNC que se ejecuta en test-client.

**Conexión**

Para aclarar, no puedes conectarte a un servicio VNC a través de un navegador web usando http://. El protocolo VNC no es el mismo que HTTP y requiere un cliente VNC para establecer la conexión.

Para conectarte a test-client utilizando VNC, debes seguir los siguientes pasos después de haber establecido el túnel SSH correctamente:

1. En tu máquina local, inicia el cliente VNC.
2. Conéctate al servidor VNC que está corriendo en test-client a través del túnel SSH utilizando localhost:5903 como la dirección en tu cliente VNC.
3. Entra la contraseña que configuraste cuando iniciaste el servidor VNC (vncserver) en test-client.

![](/img/8.png)

![](/img/3.png)

```sh
root@test-client:~# sudo apt-get install dbus
    Reading package lists... Done
    Building dependency tree... Done
    Reading state information... Done
    dbus is already the newest version (1.12.28-0+deb11u1).
    dbus set to manually installed.
    0 upgraded, 0 newly installed, 0 to remove and 0 not upgraded.

# reemplazo el contenido del archivo
root@test-client:~# nano /root/.vnc/xstartup
root@test-client:~# cat /root/.vnc/xstartup
    #!/bin/sh
    unset SESSION_MANAGER
    unset DBUS_SESSION_BUS_ADDRESS
    exec dbus-launch startxfce4

# hago el script ejecutable
root@test-client:~# chmod +x /root/.vnc/xstartup

# reinicio el servidor
root@test-client:~# vncserver -kill :3
root@test-client:~# vncserver
```

![](/img/4.png)

```sh
root@test-client:~# nano /root/.vnc/xstartup
root@test-client:~# cat /root/.vnc/xstartup

    #!/bin/sh
    unset SESSION_MANAGER
    unset DBUS_SESSION_BUS_ADDRESS
    [ -x /etc/vnc/xstartup ] && exec /etc/vnc/xstartup
    [ -r $HOME/.Xresources ] && xrdb $HOME/.Xresources
    exec dbus-launch startxfce4

root@test-client:~# chmod +x /root/.vnc/xstartup
root@test-client:~# vncserver -kill :3
root@test-client:~# vncserver

root@test-client:~# apt-get install xfce4
root@test-client:~# vncserver -kill :3
root@test-client:~# vncserver

root@test-client:~# cat /root/.vnc/test-client:3.log
    23/03/24 08:28:52 rfbProcessClientNormalMessage: ignoring unknown encoding 1109
    23/03/24 08:28:52 rfbProcessClientNormalMessage: ignoring unknown encoding 1110
    /root/.vnc/xstartup: 6: exec: dbus-launch: not found
```

`dbus-launch: not found` nos indica que  dbus-launch no funciona

```sh
root@test-client:~# sudo apt-get update
root@test-client:~# sudo apt-get install dbus-x11
root@test-client:~# vncserver -kill :3
root@test-client:~# vncserver 
```

**importante**
tú puedes ver qué VSC están activos, cuántos y cuál: En este caso te dice que es el `Xtightvnc :2`

```sh
root@test-client:~# ps -ef | grep Xtightvnc | grep -v grep | wc -l
1

root@test-client:~# ps -ef | grep Xtightvnc
root       69433       1  0 08:36 pts/0    00:00:00 Xtightvnc :2 -desktop X -auth /root/.Xauthority -geometry 1024x768 -depth 24 -rfbwait 120000 -rfbauth /root/.vnc/passwd -rfbport 5902 -fp /usr/share/fonts/X11/misc/,/usr/share/fonts/X11/Type1/,/usr/share/fonts/X11/75dpi/,/usr/share/fonts/X11/100dpi/ -co /etc/X11/rgb
root       69600   69353  0 08:40 pts/0    00:00:00 grep Xtightvnc
```



![](/img/5.png)

Cuando pruebo el navegador me da problemas. Esto podría deberse a varias razones, como un navegador no instalado correctamente o problemas con el perfil del usuario actual.

![](/img/6.png)

```sh
root@test-client:~# sudo apt-get update
root@test-client:~# sudo apt-get install firefox-esr
# compruebo
root@test-client:~# xdg-settings get default-web-browser
firefox-esr.desktop
# lo hago predeterminado
root@test-client:~# xdg-settings set default-web-browser firefox.desktop
```

Ya deverías estar navegando. 

**Problemas** : navego por internet pero no hacia el servidor vía ip publica. Todo va hiper lento.
**Solucion** : He tenido que crear un MV nueva con más capacidad y configurar todo de nuevo.

Hasta ahora, has:

* Incorporado una 5ª máquina virtual, la test-client.
* Instalado y configurado un entorno gráfico en la test-client.
* Establecido una conexión VNC para acceder a la test-client.
* Comprobado la conectividad a Internet desde la test-client.

Ahora intento navegar y no tiene acceso, esto es debido a que Firefos tenía un Proxy habilitado. Lo he quitado y funciona: ya veo la página del Server.

**Habilitar el módulo status y proxy_balancer en Apache en el Servidor**

```sh
root@localhost:~# sudo a2enmod status
    Module status already enabled

root@localhost:~# sudo a2enmod proxy
    Module proxy already enabled

root@localhost:~# sudo a2enmod proxy_balancer
    Module proxy_balancer already enabled

root@localhost:~# sudo a2enmod lbmethod_byrequests
    Module lbmethod_byrequests already enabled

root@localhost:~# sudo systemctl restart apache2
```

**Configurar el balancer-manager**

Agrega la siguiente configuración dentro de tu <VirtualHost>:

Ya creaste este archivo:

```sh
root@localhost:~# cat /etc/apache2/sites-available/proxy.conf
    <VirtualHost *:80>
        ServerName proxy.netum.org
        ProxyRequests Off
        <Proxy balancer://mycluster>
            BalancerMember http://192.168.0.14:80
            BalancerMember http://192.168.0.15:80
            BalancerMember http://192.168.0.16:80
            ProxySet lbmethod=byrequests
        </Proxy>

        <Location /balancer-manager>
            SetHandler balancer-manager
            Require all granted
        </Location>

        ProxyPass /balancer-manager !
        ProxyPass / balancer://mycluster/
        ProxyPassReverse / balancer://mycluster/
    </VirtualHost>
```

Copia el contenido del archivo, lo pegas en `root@localhost:~# nano /etc/apache2/sites-available/000-default.conf` y luego desabilitas este archivo anterior `proxy.conf` . Todo esto es porque no conecta bien desde la web y no puedo ver el balanceador.


```sh
root@localhost:~# nano /etc/apache2/sites-available/000-default.conf 

    <VirtualHost *:80>
            # The ServerName directive sets the request scheme, hostname and port that
            # the server uses to identify itself. This is used when creating
            # redirection URLs. In the context of virtual hosts, the ServerName
            # specifies what hostname must appear in the request's Host: header to
            # match this virtual host. For the default virtual host (this file) this
            # value is not decisive as it is used as a last resort host regardless.
            # However, you must set it for any further virtual host explicitly.
            #ServerName www.example.com

            ServerAdmin webmaster@localhost
            DocumentRoot /var/www/html

            # Available loglevels: trace8, ..., trace1, debug, info, notice, warn,
            # error, crit, alert, emerg.
            # It is also possible to configure the loglevel for particular
            # modules, e.g.
            #LogLevel info ssl:warn

            ErrorLog ${APACHE_LOG_DIR}/error.log
            CustomLog ${APACHE_LOG_DIR}/access.log combined

            # For most configuration files from conf-available/, which are
            # enabled or disabled at a global level, it is possible to
            # include a line for only one particular virtual host. For example the
            # following line enables the CGI configuration for this host only
            # after it has been globally disabled with "a2disconf".
            #Include conf-available/serve-cgi-bin.conf

            ServerName proxy.netum.org
            ProxyRequests Off
            <Proxy balancer://mycluster>
                    BalancerMember http://192.168.0.14:80
                    BalancerMember http://192.168.0.15:80
                    BalancerMember http://192.168.0.16:80
                    ProxySet lbmethod=byrequests
            </Proxy>

            <Location /balancer-manager>
                    SetHandler balancer-manager
                    Require all granted
            </Location>

            ProxyPass /balancer-manager !
            ProxyPass / balancer://mycluster/
            ProxyPassReverse / balancer://mycluster/
    </VirtualHost>
```

```sh
# Desactiva el sitio de configuración antiguo
root@localhost:~# sudo a2dissite proxy.conf

# Activa el nuevo sitio
root@localhost:~# sudo a2ensite 000-default.conf

root@localhost:~# sudo systemctl restart apache2

# Verifica la configuración 
root@localhost:~# sudo apache2ctl configtest
```

![](/img/9_.png)

Ahora tienes acceso al `Load Balancer Manager` de Apache en tu servidor. Esto significa que puedes ver y gestionar la configuración de tu balanceador de carga.

En la pantalla del `Load Balancer Manager`, podrás:

* Ver el estado actual de cada balancer y sus miembros (los servidores backend/nodos).
* Realizar cambios en la configuración del balanceador, como ajustar los algoritmos de balanceo, añadir o quitar nodos, o habilitar/deshabilitar nodos para mantenimiento.
* Observar métricas en tiempo real como el número de solicitudes procesadas y el tráfico actual.

Recuerda que cualquier cambio que hagas aquí no será persistente tras un reinicio de Apache a menos que también los hagas en la configuración de archivos de Apache correspondiente. Es decir, si ajustas algo en el Load Balancer Manager, también deberías ajustar tu archivo de configuración (`000-default.conf` o el específico del sitio virtual) para que esos cambios se mantengan después de reiniciar el servicio.

He recargado varias veces la página YouTube y además he recargado la web del balanceador

![](/img/10.png)

La interfaz muestra los nodos individuales que forman parte del clúster y las estadísticas como el número de solicitudes que han sido dirigidas a cada nodo (Elected), que es lo que "Elected" representa.

Por ejemplo, puedes ver que el nodo 192.168.0.14 ha procesado 167 solicitudes, al igual que el 192.168.0.15. El nodo 192.168.0.16 ha procesado 166. Esta distribución bastante equitativa indica que el balanceo de carga está funcionando como se espera, distribuyendo las solicitudes entrantes de manera uniforme entre los nodos.

La columna Load muestra un valor negativo para dos nodos y un valor alto para uno, esto puede indicar un cálculo de carga incorrecto o una representación visual inesperada en el Load Balancer Manager. Usualmente, el valor de Load debería ser un número que representa la carga actual estimada para cada nodo, basado en la cantidad de solicitudes o sesiones activas. Si los valores parecen inusuales o inconsistentes, podría ser un indicio de que necesitas revisar la configuración del balanceador o cómo Apache está calculando la carga.

Además podemos ir viendo que cada vez que recargamos la página ip pública, el balanceador va distribuyendo la carga a los diferentes nodos:

![](/img/11.png)

![](/img/12.png)

![](/img/13.png)

>---
> **6.** Desde la 5ª máquina realizar evaluaciones de prestaciones a través de herramientas que nos permitan realizar diferentes procesos de carga. Para ello se hará a dos niveles del proceso de performance measurement: 
>* el comando ab (https://httpd.apache.org/docs/2.4/programs/ab.html dentro del paquete apache2-utils) que es una herramienta potente pero simple.
>* Jmeter https://jmeter.apache.org/ (o similar). Herramienta de análisis muy completa (y por tanto más compleja) y utilizada profesionalmente en entornos empresariales.
>
>---

**Realizar Pruebas de Carga usando `ab`**

Se puede variar los parámetros para simular diferentes patrones de tráfico y carga. Por ejemplo:

Prueba con concurrencia baja: `ab -n 100 -c 5 http://84.88.58.69/`
Prueba con concurrencia media: `ab -n 1000 -c 50 http://84.88.58.69/`
Prueba con concurrencia alta: `ab -n 10000 -c 100 http://84.88.58.69/`

```sh
root@localhost:~# ab -n 500 -c 20 http://84.88.58.69/
        This is ApacheBench, Version 2.3 <$Revision: 1903618 $>
        Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
        Licensed to The Apache Software Foundation, http://www.apache.org/

        Benchmarking 84.88.58.69 (be patient).....done


        Server Software:        Apache/2.4.56
        Server Hostname:        84.88.58.69
        Server Port:            80

        Document Path:          /
        Document Length:        380 bytes

        Concurrency Level:      10
        Time taken for tests:   0.243 seconds
        Complete requests:      100
        Failed requests:        66
        (Connect: 0, Receive: 0, Length: 66, Exceptions: 0)
        Total transferred:      64968 bytes
        HTML transferred:       37868 bytes
        Requests per second:    411.10 [#/sec] (mean)
        Time per request:       24.325 [ms] (mean)
        Time per request:       2.433 [ms] (mean, across all concurrent requests)
        Transfer rate:          260.82 [Kbytes/sec] received

        Connection Times (ms)
                    min  mean[+/-sd] median   max
        Connect:        1    4   1.1      4       6
        Processing:     3   11  10.0      9     101
        Waiting:        2   10   9.8      7      96
        Total:          7   15   9.7     12     103

        Percentage of the requests served within a certain time (ms)
        50%     12
        66%     14
        75%     15
        80%     16
        90%     20
        95%     23
        98%     31
        99%    103
        100%    103 (longest request)
 ```

* Requests por Segundo: Se completaron 411.10 solicitudes por segundo, lo que sugiere que el servidor responde rápidamente a las solicitudes en el nivel de concurrencia establecido.
* Tiempo de Respuesta: En promedio, cada solicitud tomó 24.325 milisegundos (ms) para ser procesada. El tiempo promedio por solicitud, teniendo en cuenta la concurrencia, fue de 2.433 ms. Estos son tiempos de respuesta relativamente rápidos.
* Errores de Longitud: Hubo 66 solicitudes fallidas debido a discrepancias en la longitud del contenido, lo que significa que el tamaño del contenido recibido no coincidía con lo esperado (Document Length: 380 bytes). Esto podría ser un indicio de que algunos de tus nodos están sirviendo contenido diferente o hay páginas de error involucradas.
* Transferencia de Datos: Se transfirieron un total de 64.968 bytes y 37.868 bytes de HTML. Dado el tamaño del documento de 380 bytes, los números parecen consistentes con el número de solicitudes completadas y fallidas.
* Conexión y Tiempos de Procesamiento:
  * El tiempo mínimo fue de 7 ms, el promedio fue de 15 ms, y el máximo fue de 103 ms.
  * El tiempo de conexión fue rápido, lo que sugiere que la red o la conectividad entre ab y el servidor no es un cuello de botella.
* Distribución del Tiempo de Respuesta: La mayoría de las solicitudes (95%) se sirvieron en 23 ms o menos, lo que es un buen indicador de consistencia en la respuesta, aunque algunas solicitudes (5%) tardaron significativamente más tiempo, hasta 103 ms, que puede ser un indicio de variaciones en el tiempo de procesamiento o posibles cuellos de botella.

Para mejorar el balanceo de carga y reducir los errores de longitud, debes asegurarte de que todos los nodos devuelvan exactamente el mismo contenido. Si los nodos sirven diferentes versiones de una página o si uno de los nodos está configurado incorrectamente y sirve contenido de error, esto puede causar discrepancias en el tamaño del contenido que ab detecta como errores.


Elaborar un informe con las evidencias, comentarios de despliegue y conclusiones (en PDF) y
entregarlo al CV en la fecha indicada. Se valorará tanto los resultados obtenidos y la solución de los
problemas, como el análisis y la valoración de los resultados y las conclusiones propias del trabajo
desarrollado.

**Realizar Pruebas de Carga usando `JMeter`**

JMeter es una aplicación Java, por lo que necesitarás tener Java instalado

```sh
# instalando java
root@test-client:~# sudo apt update
root@test-client:~# sudo apt install default-jdk
root@test-client:~# java -version
    openjdk version "11.0.22" 2024-01-16
    OpenJDK Runtime Environment (build 11.0.22+7-post-Debian-1deb11u1)
    OpenJDK 64-Bit Server VM (build 11.0.22+7-post-Debian-1deb11u1, mixed mode, sharing)
```

```sh
root@test-client:~# wget https://downloads.apache.org//jmeter/binaries/apache-jmeter-5.6.3.tgz
root@test-client:~# tar -xzf apache-jmeter-5.6.3.tgz

root@test-client:~# cd apache-jmeter-5.6.3/bin
root@test-client:~/apache-jmeter-5.6.3/bin# ./jmeter
```

He instalado desde mi local el programa pero ahora me pide una interfaz gráfica. Desde la pnatalal del servidor veo lo instaldo y abro el programa

![](/img/14.png)

![](/img/15.png)

![](/img/16.png)

![](/img/17.png)

![](/img/18.png)

![](/img/19.png)

![](/img/20.png)


Basado en los resultados de tus pruebas con JMeter, parece una configuración de balanceo de carga que está respondiendo a las peticiones correctamente, ya que no hay errores reportados. Aquí hay algunos detalles a considerar:

* Tiempo de Respuesta: El tiempo de respuesta promedio parece ser de 17 milisegundos, lo cual es bastante bueno. No obstante, hay una desviación estándar significativa, lo cual indica que algunas peticiones se tardaron mucho más que otras. Puede ser normal en pruebas de carga debido a varios factores como GC (Garbage Collection) en el servidor o variaciones en la carga de red.
* Throughput: Estás obteniendo alrededor de 25-26 peticiones por minuto. Dependiendo de lo que esperes en tu entorno de producción, esto podría ser bajo. Si necesitas un throughput mayor, podrías aumentar el número de usuarios concurrentes (hilos) en tu Test Plan.
* Latencia: La latencia parece estar en un rango bajo, lo cual es una señal positiva.
* Errores: No reportaste errores, lo que significa que todas las peticiones fueron procesadas exitosamente.
* Balanceo de Carga: Si los nodos de tu balanceador de carga tienen identificadores únicos en sus páginas (por ejemplo, un número de nodo o algún otro identificador), podrías verificar en los resultados del árbol de respuesta si las peticiones están siendo distribuidas equitativamente.


![](/img/21.png)

![](/img/22.png)

![](/img/23.png)

* Throughput: El throughput ha aumentado significativamente a 57.75/min, lo cual es una mejora sustancial. Esto indica que el servidor está manejando una cantidad más alta de peticiones por minuto.
* Tiempo de Respuesta: El tiempo promedio de respuesta es de 7 ms, con una mediana de 5 ms, lo que es bastante rápido y sugiere que el servidor está respondiendo bien bajo carga.
* Desviación Estándar: Una desviación estándar de 17 ms indica variabilidad en el tiempo de respuesta, pero dado que los valores promedio y mediano son bajos, esto puede no ser un problema significativo.
* Errores: Sigue sin tener errores, lo cual es excelente.