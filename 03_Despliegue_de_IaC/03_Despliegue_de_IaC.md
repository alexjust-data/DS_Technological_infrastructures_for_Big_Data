# Infraestructuras tecnológicas para el Big Data

## Despliegue de IaC

Objetivos: desplegar infraestructura como código utilizando diferentes herramientas.


**Acceso con AWS CLI y un usuario federado:**

Recordar siempre utilizar instancias pequeñas (tiny y micro AWS) y verificar que tanto las instancias como los discos creados son eliminados después que se ha realizado todas las pruebas. Para AWS CLI y obtener las claves y tokens:

URL al acceso federado a AWS:

https://id-provider.uoc.edu/idp/profile/SAML2/Unsolicited/SSO?providerId=arn:aws:iam::579845986493:saml-provider/UOCLABS&target=https://eu-central-1.console.aws.amazon.com/console/home?region=eu-central-1#

y la región activa es: eu-central-1

Dado que en AWS se dispone de un usuario federado es necesario extraer las claves y token de acceso desde el acceso institucional. Si bien se puede extraer en forma manual es más fácil utilizar la extensión de Chrome https://github.com/prolane/samltoawsstskeys/blob/master/README.md. 

Cuando se conectan a AWS mediante la URL que les han pasado desde la UOC, esta extensión generará un archivo llamado credentials en el directorio Download que tenga configurado Chrome con el siguiente contenido:

[default]
* aws_access_key_id = ************
* aws_secret_access_key = ***************
* aws_session_token = **************

Se debe luego instalar la aws cli https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-welcome.html y reemplazar el archivo .aws/credentials con el contenido de este archivo. Luego se debe modificar el .aws/config con el siguiente contenido (o la zona por defecto que tengan asignada):

[default]
* region = eu-central-1
* output = json

Verificar que funciona ejecutando por ejemplo aws s3 ls.


<blockquote style="background-color: #e0f2fe; color: black; border-left: 5px solid #2196f3; padding: 10px;">
Prueba de concepto sobre AWS:   Utilizando Ansible se despliega un website con Apache2 (se podrá hacer desde una MV, desde OpenNebula o desde el propio host).
</blockquote>

**Instalando AWS Command Line Interface (AWS CLI)**  

Install or update to the latest version of the AWS CLI
https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html


1. In your browser, download the macOS pkg file: https://awscli.amazonaws.com/AWSCLIV2.pkg
2. Run your downloaded file and follow the on-screen instructions. You can choose to install the AWS CLI in the following ways:
   1. For all users on the computer (requires sudo)
      1. You can install to any folder, or choose the recommended default folder of /usr/local/aws-cli.
      2. The installer automatically creates a symlink at /usr/local/bin/aws that links to the main program in the installation folder you chose.


El comando sudo `ln -s /usr/local/aws-cli/aws /usr/local/bin/aws` tiene el propósito de crear un enlace simbólico (o "symlink") para el ejecutable aws del AWS CLI en el directorio `/usr/local/bin`. Este enlace permite que puedas ejecutar el comando aws desde cualquier lugar en tu terminal, sin tener que especificar la ruta completa.

```sh
# creo enlace simbolico
➜  ~ sudo ln -s /usr/local/aws-cli/aws /usr/local/bin/aws
    Password:
    ln: /usr/local/bin/aws: File exists

# compruebo que se ha creado el enlace simbólico
➜  ~ ls -l /usr/local/bin/aws
    lrwxr-xr-x  1 root  admin  22 Jun 10 10:03 /usr/local/bin/aws -> /usr/local/aws-cli/aws 

➜  ~ which aws
/usr/local/bin/aws

➜  ~ aws --version
    aws-cli/2.16.4 Python/3.11.8 Darwin/23.3.0 exe/x86_64
```

A partir de ahora, puedes usar los comandos de AWS CLI sin necesidad de especificar la ruta completa al ejecutable.  

El directorio `~/.aws` es un estándar para almacenar configuraciones y credenciales de AWS CLI en tu directorio de inicio, es un directorio específico en tu carpeta de inicio que AWS CLI usa para almacenar archivos de configuración y credenciales. Este directorio es diferente de los directorios donde se instala el software AWS CLI (/usr/local/aws-cli) y el enlace simbólico (/usr/local/bin/aws).

```sh
➜  ~ pwd
    /Users/alex

➜  ~ mkdir -p ~/.aws
➜  ~ nano ~/.aws/credentials

    [default]
    * aws_access_key_id = ************
    * aws_secret_access_key = ***************
    * aws_session_token = **************
```


```sh
➜  ~ nano ~/.aws/config 

    [default]
    region = eu-central-1
    output = json
```

```sh
➜  ~ aws s3 ls              
    An error occurred (AccessDenied) when calling the ListBuckets operation: Access Denied
```

"puede ser que no tengas permiso al s3 y como los permisos los dan los Adm AWS-UOC cuando crean las cuentas esta edición veo que no les han dado permisos, si puedes ejecutar el get-caller quiere decir que ya te está funcionando..."

```sh
➜  ~ aws sts get-caller-identity
    {
        "UserId": "AROAIU2Z2ULEWL3JH76BU:arodriguezjus@uoc.edu",
        "Account": "579845986493",
        "Arn": "arn:aws:sts::579845986493:assumed-role/student/arodriguezjus@uoc.edu"
    }
```

**Instalado Ansible**

```sh
# python instalado
➜  ~ python3 --version
    Python 3.9.6

# pip instaldo
➜  ~ python3 -m pip -V
    pip 21.2.4 from /Library/Developer/CommandLineTools/Library/Frameworks/Python3.framework/Versions/3.9/lib/python3.9/site-packages/pip (python 3.9)

# Instalar Ansible 
➜  ~ python3 -m pip install --user ansible

➜  ~ nano ~/.zshrc
    # añado esta linea
    export PATH="$HOME/Library/Python/3.9/bin:$PATH"

# recargo archivo configuracino
➜  ~ source ~/.zshrc

# Verificar la instalación de Ansible

➜  ~ ansible --version
    ansible [core 2.15.12]
    config file = None
    configured module search path = ['/Users/alex/.ansible/plugins/modules', '/usr/share/ansible/plugins/modules']
    ansible python module location = /Users/alex/Library/Python/3.9/lib/python/site-packages/ansible
    ansible collection location = /Users/alex/.ansible/collections:/usr/share/ansible/collections
    executable location = /Users/alex/Library/Python/3.9/bin/ansible
    python version = 3.9.6 (default, Nov 10 2023, 13:38:27) [Clang 15.0.0 (clang-1500.1.0.2.5)] (/Library/Developer/CommandLineTools/usr/bin/python3)
    jinja version = 3.1.4
    libyaml = True
```


**Generando par de claves**

Esto generará dos archivos: `my-key-pair.pem` (clave privada) y `my-key-pair.pem.pub` (clave pública).

```sh
➜  ~ pwd
    /Users/alex

➜  ~ ssh-keygen -t rsa -b 2048 -f my-key-pair.pem
    Generating public/private rsa key pair.
    Enter passphrase (empty for no passphrase): 
    Enter same passphrase again: 
    Your identification has been saved in my-key-pair.pem
    Your public key has been saved in my-key-pair.pem.pub
    The key fingerprint is:
    SHA256:NxYy+79zA/WPW8DoTKrprh9LhDihpcECwnX3LfM7LdU alex@Alexs-MacBook-Pro.local
    The key's randomart image is:
    +---[RSA 2048]----+
    |+ .. . .         |
    |oo  . . . .      |
    |. o o   o+..     |
    | . = o . ++. oo  |
    |  o o . S +.oooE |
    |     . . + *=  ..|
    |        o o+oo .o|
    |       . = .+ +..|
    |      .=B   o+.o |
    +----[SHA256]-----+
```

```sh
# permisos de las claves
chmod 400 my-key-pair.pem
```

**Crear un grupo de seguridad en AWS**

```sh
➜  ~ aws ec2 create-security-group --group-name my-security-group --description "Security group for HTTP and SSH access"

    An error occurred (RequestExpired) when calling the CreateSecurityGroup operation: Request has expired.
```



```sh
➜  ~ nano ~/.aws/credentials                                                             

➜  ~ aws sts get-caller-identity
    {
        "UserId": "AROAIU2Z2ULEWL3JH76BU:arodriguezjus@uoc.edu",
        "Account": "579845986493",
        "Arn": "arn:aws:sts::579845986493:assumed-role/student/arodriguezjus@uoc.edu"
    }
```

```sh
# Crear un grupo de seguridad
➜  ~ aws ec2 create-security-group --group-name my-security-group --description "Security group for HTTP and SSH access"
    {
        "GroupId": "sg-0d6bace4b983f1a7d"
    }
```

```sh
# Obtener el ID del grupo de seguridad
➜  ~ SECURITY_GROUP_ID=$(aws ec2 describe-security-groups --group-names my-security-group --query "SecurityGroups[0].GroupId" --output text)
```

```sh
# # Permitir tráfico SSH (puerto 22)
➜  ~ aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port 22 --cidr 0.0.0.0/0
    {
        "Return": true,
        "SecurityGroupRules": [
            {
                "SecurityGroupRuleId": "sgr-077e288c62ccd4106",
                "GroupId": "sg-0d6bace4b983f1a7d",
                "GroupOwnerId": "579845986493",
                "IsEgress": false,
                "IpProtocol": "tcp",
                "FromPort": 22,
                "ToPort": 22,
                "CidrIpv4": "0.0.0.0/0"
            }
        ]
    }
```

```sh
# Permitir tráfico HTTP (puerto 80)
➜  ~ aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port 80 --cidr 0.0.0.0/0
    {
        "Return": true,
        "SecurityGroupRules": [
            {
                "SecurityGroupRuleId": "sgr-05e2c8df14cbafb29",
                "GroupId": "sg-0d6bace4b983f1a7d",
                "GroupOwnerId": "579845986493",
                "IsEgress": false,
                "IpProtocol": "tcp",
                "FromPort": 80,
                "ToPort": 80,
                "CidrIpv4": "0.0.0.0/0"
            }
        ]
    }
```

**Lanzar una instancia EC2**

Lanza una instancia EC2 usando la clave SSH generada y el grupo de seguridad:

```sh
# AMI específica en la región eu-central-1:
aws ec2 describe-images --region eu-central-1 --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" --query "Images[*].[ImageId,Name]" --output text

#  lista de subnets disponibles en tu región eu-central-1
aws ec2 describe-subnets --region eu-central-1 --query "Subnets[*].SubnetId" --output text

# Especifica el ID de la imagen de Amazon Linux 2 (puedes buscar otras AMI si prefieres)
➜  ~ AMI_ID=ami-0f3d898ae42d775a6
➜  ~ SUBNET_ID=subnet-0b304df8b3d7ffc22

➜  ~ # Lanzar una instancia EC2
INSTANCE_ID=$(aws ec2 run-instances --image-id $AMI_ID --count 1 --instance-type t2.micro --key-name my-key-pair --security-group-ids $SECURITY_GROUP_ID --query "Instances[0].InstanceId" --output text --
cmdsubst> 
```


```sh
➜  ~ # Crear un grupo de seguridad en la VPC especificada
SECURITY_GROUP_ID=$(aws ec2 create-security-group --group-name my-security-group --description "Security group for HTTP and SSH access" --vpc-id $VPC_ID --query "GroupId" --output text --region eu-central-1)

➜  ~ # Permitir tráfico SSH (puerto 22)
aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port 22 --cidr 0.0.0.0/0 --region eu-central-1


{
    "Return": true,
    "SecurityGroupRules": [
        {
            "SecurityGroupRuleId": "sgr-05af16b2cae8f16c2",
            "GroupId": "sg-03f0c731e21ec0e7f",
            "GroupOwnerId": "579845986493",
            "IsEgress": false,
            "IpProtocol": "tcp",
            "FromPort": 22,
            "ToPort": 22,
            "CidrIpv4": "0.0.0.0/0"
        }
    ]
}


➜  ~ # Permitir tráfico HTTP (puerto 80)
aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port 80 --cidr 0.0.0.0/0 --region eu-central-1


{
    "Return": true,
    "SecurityGroupRules": [
        {
            "SecurityGroupRuleId": "sgr-08b1b5938d030583d",
            "GroupId": "sg-03f0c731e21ec0e7f",
            "GroupOwnerId": "579845986493",
            "IsEgress": false,
            "IpProtocol": "tcp",
            "FromPort": 80,
            "ToPort": 80,
            "CidrIpv4": "0.0.0.0/0"
        }
    ]
}


➜  ~ echo "El nuevo ID del grupo de seguridad es: $SECURITY_GROUP_ID"
El nuevo ID del grupo de seguridad es: sg-03f0c731e21ec0e7f
```


--------------

**Verifico la Región Configurada**

```sh
➜  ~ aws configure

AWS Access Key ID [****************4ZOW]: 
AWS Secret Access Key [****************91PT]: 
Default region name [eu-central-1]: 
Default output format [json]: 
```

**Verifico Instancias EC2 en Ejecución**

```sh
➜  ~ aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name,PublicIpAddress]' --output table

--------------------------------------------
|             DescribeInstances            |
+----------------------+-----------+-------+
|  i-013f4da9521e1b547 |  stopped  |  None |
|  i-0f2d4f9f2d3073f39 |  stopped  |  None |
|  i-06a435320f767f47f |  stopped  |  None |
|  i-0c8c0e18de7307288 |  stopped  |  None |
|  i-0c216a861257f58a5 |  stopped  |  None |
+----------------------+-----------+-------+
```

**Instancias Tienen una IP Pública**

```sh
➜  ~ aws ec2 allocate-address

{
    "PublicIp": "18.199.200.65",
    "AllocationId": "eipalloc-05a52fdef244829f4",
    "PublicIpv4Pool": "amazon",
    "NetworkBorderGroup": "eu-central-1",
    "Domain": "vpc"
}
(END)
```

**Asocio la Elastic IP a una Instancia EC2**

```sh
➜  ~ aws ec2 start-instances --instance-ids i-013f4da9521e1b547
    {
        "StartingInstances": [
            {
                "CurrentState": {
                    "Code": 0,
                    "Name": "pending"
                },
                "InstanceId": "i-013f4da9521e1b547",
                "PreviousState": {
                    "Code": 80,
                    "Name": "stopped"
                }
            }
        ]
    }
    (END)
```

**Verifico que la instancia esté corriendo**


```sh
➜  ~ aws ec2 describe-instances --instance-ids i-013f4da9521e1b547 --query 'Reservations[*].Instances[*].State.Name' --output text

# Esto debería devolver "running"
running
(END)
```


**Asocio la Elastic IP a la instancia**

```sh
➜  ~ aws ec2 associate-address --instance-id i-013f4da9521e1b547 --allocation-id eipalloc-05a52fdef244829f4

    {
        "AssociationId": "eipassoc-0ba09b0351b84de37"
    }
    (END)
```

**Verifico la Asociación de la Elastic IP**

```sh
➜  ~ aws ec2 describe-instances --instance-ids i-013f4da9521e1b547 --query 'Reservations[*].Instances[*].[InstanceId,PublicIpAddress]' --output table

    ------------------------------------------
    |            DescribeInstances           |
    +----------------------+-----------------+
    |  i-013f4da9521e1b547 |  18.199.200.65  |
    +----------------------+-----------------+
    (END)
```

**Configuración del Inventario de Ansible**


```sh
➜  ~ nano hosts
➜  ~ cat hosts 
    [web]
    ec2_instance ansible_host=18.199.200.65 ansible_user=ubuntu ansible_ssh_private_key_file=/Users/alex/my-key-pair.pem
```

**Creo el Playbook de Ansible**

```sh
➜  ~ nano playbook.yml

➜  ~ cat playbook.yml

- name: Deploy Apache2 web server
  hosts: web
  become: yes
  tasks:
    - name: Update and upgrade apt packages
      apt:
        update_cache: yes
        upgrade: dist

    - name: Install Apache2
      apt:
        name: apache2
        state: present

    - name: Start Apache2 service
      service:
        name: apache2
        state: started
        enabled: yes

    - name: Create a simple HTML file
      copy:
        dest: /var/www/html/index.html
        content: "<html><body><h1>Hello, World! I´m Alex Just</h1></body></html>"
```

**Ejecuto**

```sh
➜  ~ ansible-playbook -i hosts playbook.yml

    PLAY [Deploy Apache2 web server] *********************************************************

    TASK [Gathering Facts] *******************************************************************
    The authenticity of host '18.199.200.65 (18.199.200.65)' can't be established.
    ED25519 key fingerprint is SHA256:wdjG82/FOgNJpbtfu6CcCjk4vL/xOqSX+oLhXiEudrc.
    This key is not known by any other names.
    Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
    fatal: [ec2_instance]: UNREACHABLE! => {"changed": false, "msg": "Failed to connect to the host via ssh: Warning: Permanently added '18.199.200.65' (ED25519) to the list of known hosts.\r\nno such identity: /Users/alex/.ssh/my-key-pair.pem: No such file or directory\r\nubuntu@18.199.200.65: Permission denied (publickey).", "unreachable": true}

    PLAY RECAP ********************************************************************************
    ec2_instance               : ok=0    changed=0    unreachable=1    failed=0    skipped=0    rescued=0    ignored=0   

```

```sh
➜  ~ aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name,PublicIpAddress]' --output table

-----------------------------------------------------
|                 DescribeInstances                 |
+----------------------+----------+-----------------+
|  i-013f4da9521e1b547 |  running |  18.199.200.65  |
|  i-0f2d4f9f2d3073f39 |  stopped |  None           |
|  i-06a435320f767f47f |  stopped |  None           |
|  i-0c8c0e18de7307288 |  stopped |  None           |
|  i-0c216a861257f58a5 |  stopped |  None           |
+----------------------+----------+-----------------+




➜  ~ aws ec2 describe-instances --instance-ids i-013f4da9521e1b547 --query 'Reservations[*].Instances[*].[InstanceId,ImageId,State.Name,PublicIpAddress]' --output table

------------------------------------------------------------------------------
|                              DescribeInstances                             |
+----------------------+-------------------------+----------+----------------+
|  i-013f4da9521e1b547 |  ami-01e444924a2233b07  |  running |  18.199.200.65 |
+----------------------+-------------------------+----------+----------------+



➜  ~ aws ec2 describe-images --image-ids ami-01e444924a2233b07 --query 'Images[*].[ImageId,Name,Description]' --output table


------------------------------------------------------------------------------------------------------------------------------------------------------------------------
|                                                                            DescribeImages                                                                            |
+-----------------------+----------------------------------------------------------------------+-----------------------------------------------------------------------+
|  ami-01e444924a2233b07|  ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-20240423  |  Canonical, Ubuntu, 24.04 LTS, amd64 noble image build on 2024-04-23  |
+-----------------------+----------------------------------------------------------------------+-----------------------------------------------------------------------+
```

**Grupos de seguridad**

```sh
➜  ~ aws ec2 describe-security-groups --group-ids sg-03f0c731e21ec0e7f --query "SecurityGroups[0].IpPermissions"

[
    {
        "FromPort": 80,
        "IpProtocol": "tcp",
        "IpRanges": [
            {
                "CidrIp": "0.0.0.0/0"
            }
        ],
        "Ipv6Ranges": [],
        "PrefixListIds": [],
        "ToPort": 80,
        "UserIdGroupPairs": []
    },
    {
        "FromPort": 22,
        "IpProtocol": "tcp",
        "IpRanges": [
            {
                "CidrIp": "0.0.0.0/0"
            }
        ],
        "Ipv6Ranges": [],
        "PrefixListIds": [],
        "ToPort": 22,
        "UserIdGroupPairs": []
    }
]
```

```sh
➜  ~ ssh -i /Users/alex/my-key-pair.pem ubuntu@18.199.200.65

ubuntu@18.199.200.65: Permission denied (publickey).

➜  ~ ssh -i /Users/alex/my-key-pair.pem ubuntu@18.199.200.65

ubuntu@18.199.200.65: Permission denied (publickey).
➜  ~ sudo tail -f /var/log/auth.log

Password:
tail: /var/log/auth.log: No such file or directory
```

**CREO UN PAR DE CLAVES NUEVAS**

```sh
➜  ~ ssh-keygen -t rsa -b 2048 -f ~/.ssh/new-key-pair

Generating public/private rsa key pair.
Enter passphrase (empty for no passphrase): 
Enter same passphrase again: 
Your identification has been saved in /Users/alex/.ssh/new-key-pair
Your public key has been saved in /Users/alex/.ssh/new-key-pair.pub
The key fingerprint is:
SHA256:TtqYy4rN/D4+GXhnkV7avdNjIokWUmXKh0xcSRnGV4o alex@Alexs-MacBook-Pro.local
The key's randomart image is:
+---[RSA 2048]----+
|       . +=+ ..  |
|        o.*...   |
|       + *E..    |
|        O o      |
|     . oS* .     |
|    . +B* . .    |
|     .+*oo . o   |
|   = .+.o o + +  |
|  . ==*+   . + . |
+----[SHA256]-----+
```

```sh
➜  ~ cat ~/.ssh/new-key-pair
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAACmFlczI1Ni1jdHIAAAAGYmNyeXB0AAAAGAAAABDSi1S0y9
uIH5kz7D5YYcS0AAAAGAAAAAEAAAEXAAAAB3NzaC1yc2EAAAADAQABAAABAQDgkIUISjOe
b5qGDwaCKjkN38R67CXR+kpBCUh8EbRHfbpQZxrSMVm3r4dPsP/1Hre4Mq/BTmhuEXqjZD
YJz1at0TdlI3VEXiOCPWhqUUh/vloBn5IbCHWnhGb74suntusZKUSUwwwhG6Wi9Xq6GcDB
HupwT0jbtyq8QYoZEBKik0jmXEAKkZ37Qtvy+kLh5dnpxuFV5Arcv+8s2y2c6sRFwz5eda
W3TQHi+z4CKMRkw4QwUNNt7ZJWT3S9Qpqkix8fCbdgOudxKw9Wk0iDaziO6MRO73/DOhcN
OOlhwTn+TscurSW0EsIS51e5+Xkp9qtZ7d7pzoyVVxb8YmU/gV9zAAAD4Do76Oh9lcSQwG
H4hj7gOeL5HP89ZASOM/3g4tBZj5dX6nTO+3+LNVyA0TCXPnzYCqwt9K2AqCFcJ0y9dE6T
sCM/SpKBmQjCoOZ5rB/+p7UzXUDIk7/ZhPwiCYrf5zDHy1kIvebgzgMt+uJMyfFbXJvgTa
lH/7fOC4gSgg0lSnZjsUCEobwSugegLpqPn7XJ8M/L3zMxjnGWMwbSDMuG5wpCNWpSi0Mg
BzU4IH2x+am9wRaud825vL1SWNodrRYlhO6g/mEQ1Y0S5MViOQnW6ghVolDk5dXpNhih8E
tygXlEI3WLMq27r2jtL1ArTsDY1qwFZw+DTACBcN4yj22wL2SRyN9DXpjEsoLkKTlPN8/o
yjau0Y4jh3tVDm1z1P09j3a+a3p0CgT8b2SriBJaEnN5LrULRu9Wx8Y3Deyfw7AABViGFb
ULI/FwyUXwenRLVFHpehzIviAGK0/gL8HIe94i0N9HEI6T+tuPp9Evp6+G47rn9sQtZR9w
rmKg1hBYtmbPChv0wbfGE1kNRHe7IZdSGZ8uxrt5a1oD+UFe/P5I49SJAUbxuPF06TIyD1
+1Y13UlY/nLkziJmvoPpEPUnsZdd+/VWt/k9ZFG0S+KdlxgLdaRXaTfv60EqtBKL0+cOu3
rdqgQEFYHwLBPJRNKt9qUPneHaHKjgRo3zwJaxBhgT7x9KsThd2/tGZWGYygkq5BEIWkFi
dFKfo1zwxUnDr/bHAY47R/i0HQHrul03+P/2ipjr5zjyUOigcoOJK6uwM9EDqv+MPyPX+j
8IueMYVAxEx98zFqi9vi6lvuHOsErikJLUuiqQkvHLCQerupy9T4R6mILUw3L9NeoX0BDo
80blcenjP0XfZ3oSCAbrOq5t0tSTsIr//zrdXF9/vYveRVIaHeFQuq3yuBw2Rbo0zX+gtq
4baquUtzMoMbmejyyiZNID1QGC16VLj+U8tDd8rtYb1JpkSPzlVpvEdOE5sdKIAFge7hLy
f6XHfInRpxUeBDNLq1XxYkZDxoNjX43z2rOFD15svwF7KmCHBN3LX7vKZ9dO0Og2yj3Bwb
64Ls/jXSeiaeipxeHyOw/CykeG4MzWAfc4Jvj7hFrd8YuTRJpGsUH7UJj702xyOZK0I3QD
+n5SLYOk/KURSr7WgBiotB22jM+qX47GNyqk6zMUYbbe3rbvCC9cUd5bJXi7RgFZwmJ1lk
ig6LWlfWSVFOp6H4sSIUk49OWNhopEGHYTdj8tYq43tpH0bVUf30zSevVOCy4br9R246+z
Ie3sg9xN37Sf41kP40yD8yXIDGPILJXQUN3DefyIN8M01CkTa4
-----END OPENSSH PRIVATE KEY-----
➜  ~ cat ~/.ssh/new-key-pair.pub

ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDgkIUISjOeb5qGDwaCKjkN38R67CXR+kpBCUh8EbRHfbpQZxrSMVm3r4dPsP/1Hre4Mq/BTmhuEXqjZDYJz1at0TdlI3VEXiOCPWhqUUh/vloBn5IbCHWnhGb74suntusZKUSUwwwhG6Wi9Xq6GcDBHupwT0jbtyq8QYoZEBKik0jmXEAKkZ37Qtvy+kLh5dnpxuFV5Arcv+8s2y2c6sRFwz5edaW3TQHi+z4CKMRkw4QwUNNt7ZJWT3S9Qpqkix8fCbdgOudxKw9Wk0iDaziO6MRO73/DOhcNOOlhwTn+TscurSW0EsIS51e5+Xkp9qtZ7d7pzoyVVxb8YmU/gV9z alex@Alexs-MacBook-Pro.local
➜  ~ 
```

```sh
➜  ~ chmod 400 ~/.ssh/new-key-pair
```

**Creo un Par de Claves en AWS**

```SH
# Importo la clave pública a AWS para crear un nuevo par de claves
➜  ~ aws ec2 import-key-pair --key-name "new-key-pair" --public-key-material fileb://~/.ssh/new-key-pair.pub 

{
    "KeyFingerprint": "5d:2c:27:91:b1:8f:53:b0:84:ea:e9:a6:b1:65:91:7b",
    "KeyName": "new-key-pair",
    "KeyPairId": "key-0b0d565ded98af21b"
}
```

Confirmo que se han importado bien en AWS

```sh
➜  ~ aws ec2 describe-key-pairs --query 'KeyPairs[*].KeyName' --output text

    vagrant-master  
    ansible-master  
    ansible 
    gborr_key       
    vagrant-ubuntu  
    new-key-pair    
    keys-pec       
    ansible-public-key 
    keys
```

**Configuro el Grupo de Seguridad**

```sh
➜  ~ SECURITY_GROUP_ID=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=my-security-group" --query 'SecurityGroups[0].GroupId' --output text)
echo "El ID del grupo de seguridad existente es: $SECURITY_GROUP_ID"

    El ID del grupo de seguridad existente es: sg-0d6bace4b983f1a7d
```

**Permitir tráfico SSH y HTTP en el grupo de seguridad:**

```sh
# Permitir tráfico SSH (puerto 22)
➜  ~ aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port 22 --cidr 0.0.0.0/0
    {
        "Return": true,
        "SecurityGroupRules": [
            {
                "SecurityGroupRuleId": "sgr-077e288c62ccd4106",
                "GroupId": "sg-0d6bace4b983f1a7d",
                "GroupOwnerId": "579845986493",
                "IsEgress": false,
                "IpProtocol": "tcp",
                "FromPort": 22,
                "ToPort": 22,
                "CidrIpv4": "0.0.0.0/0"
            }
        ]
    }
```

```sh
# Permitir tráfico HTTP (puerto 80)
➜  ~ aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port 80 --cidr 0.0.0.0/0
    {
        "Return": true,
        "SecurityGroupRules": [
            {
                "SecurityGroupRuleId": "sgr-05e2c8df14cbafb29",
                "GroupId": "sg-0d6bace4b983f1a7d",
                "GroupOwnerId": "579845986493",
                "IsEgress": false,
                "IpProtocol": "tcp",
                "FromPort": 80,
                "ToPort": 80,
                "CidrIpv4": "0.0.0.0/0"
            }
        ]
    }
```

**Obtener el ID de la Subred**

```sh
# Lista las subredes disponibles en tu región eu-central-1:
➜  ~ aws ec2 describe-subnets --query "Subnets[*].[SubnetId,AvailabilityZone,DefaultForAz]" --output table

--------------------------------------------------------
|                    DescribeSubnets                   |
+---------------------------+-----------------+--------+
|  subnet-0b304df8b3d7ffc22 |  eu-central-1a  |  False |
|  subnet-07d420e8ccfb519da |  eu-central-1a  |  False |
+---------------------------+-----------------+--------+


➜  ~ SUBNET_ID=subnet-0b304df8b3d7ffc22
```

**Lanzo una Nueva Instancia EC2** : ERROR


```sh 
# Obtengo ID de la AMI (Amazon Linux 2 en este caso)
➜  ~ INSTANCE_ID=$(aws ec2 run-instances --image-id $AMI_ID --count 1 --instance-type t2.micro --key-name new-key-pair --security-group-ids $SECURITY_GROUP_ID --subnet-id $SUBNET_ID --query 'Instances[0].InstanceId' --output text)
echo "El ID de la nueva instancia es: $INSTANCE_ID"


An error occurred (InvalidParameter) when calling the RunInstances operation: Security group sg-0d6bace4b983f1a7d and subnet subnet-0b304df8b3d7ffc22 belong to different networks.
El ID de la nueva instancia es: 
```

Solucionando error


```sh
# VPC del grupo de seguridad
➜  ~ aws ec2 describe-security-groups --group-ids $SECURITY_GROUP_ID --query 'SecurityGroups[0].VpcId' --output text

    vpc-04184d6be94cef398

# resultado a una variable de entorno
➜  ~ SECURITY_GROUP_VPC_ID=$(aws ec2 describe-security-groups --group-ids $SECURITY_GROUP_ID --query 'SecurityGroups[0].VpcId' --output text)
echo "El ID de la VPC del grupo de seguridad es: $SECURITY_GROUP_VPC_ID"

    El ID de la VPC del grupo de seguridad es: vpc-04184d6be94cef398


# Verificar la VPC de la Subred
➜  ~ aws ec2 describe-subnets --subnet-ids $SUBNET_ID --query 'Subnets[0].VpcId' --output text

vpc-0dcbbca477c748c31

# resultado a una variable de entorno
➜  ~ SUBNET_VPC_ID=$(aws ec2 describe-subnets --subnet-ids $SUBNET_ID --query 'Subnets[0].VpcId' --output text)
echo "El ID de la VPC de la subred es: $SUBNET_VPC_ID"

El ID de la VPC de la subred es: vpc-0dcbbca477c748c31

# Verifica que ambos IDs de VPC coincidan
if [ "$SECURITY_GROUP_VPC_ID" != "$SUBNET_VPC_ID" ]; then
    echo "El grupo de seguridad y la subred pertenecen a diferentes VPCs. Necesitamos usar recursos que pertenezcan a la misma VPC."
    exit 1
fi
```
!---------------


```sh
➜  ~ echo $SUBNET_VPC_ID

    vpc-0dcbbca477c748c31

➜  ~ NEW_SECURITY_GROUP_ID=$(aws ec2 create-security-group --group-name my-new-security-group --description "Security group for HTTP and SSH access" --vpc-id $SUBNET_VPC_ID --query 'GroupId' --output text)
echo "El ID del nuevo grupo de seguridad es: $NEW_SECURITY_GROUP_ID"

    El ID del nuevo grupo de seguridad es: sg-0becd2e808068c532

➜  ~ aws ec2 authorize-security-group-ingress --group-id $NEW_SECURITY_GROUP_ID --protocol tcp --port 22 --cidr 0.0.0.0/0

{
    "Return": true,
    "SecurityGroupRules": [
        {
            "SecurityGroupRuleId": "sgr-0b941606cbc6d5471",
            "GroupId": "sg-0becd2e808068c532",
            "GroupOwnerId": "579845986493",
            "IsEgress": false,
            "IpProtocol": "tcp",
            "FromPort": 22,
            "ToPort": 22,
            "CidrIpv4": "0.0.0.0/0"
        }
    ]
}


➜  ~ aws ec2 authorize-security-group-ingress --group-id $NEW_SECURITY_GROUP_ID --protocol tcp --port 80 --cidr 0.0.0.0/0
{
    "Return": true,
    "SecurityGroupRules": [
        {
            "SecurityGroupRuleId": "sgr-0124c8150e64967fd",
            "GroupId": "sg-0becd2e808068c532",
            "GroupOwnerId": "579845986493",
            "IsEgress": false,
            "IpProtocol": "tcp",
            "FromPort": 80,
            "ToPort": 80,
            "CidrIpv4": "0.0.0.0/0"
        }
    ]
}
```


```sh
➜  ~ EXISTING_SECURITY_GROUP_ID=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=my-new-security-group" "Name=vpc-id,Values=$SUBNET_VPC_ID" --query 'SecurityGroups[0].GroupId' --output text)
echo "El ID del grupo de seguridad existente es: $EXISTING_SECURITY_GROUP_ID"

El ID del grupo de seguridad existente es: sg-0becd2e808068c532
```




**referencias:**
* https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_intro.html#about-playbooks
* https://docs.ansible.com/ansible/latest/installation_guide/index.html 
  

```sh
  ➜  ~ SECURITY_GROUP_IDS=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$SUBNET_VPC_ID" --query 'SecurityGroups[?GroupName!=`default`].GroupId' --output text)
for sg in $SECURITY_GROUP_IDS; do
    aws ec2 delete-security-group --group-id $sg
    echo "Eliminado el grupo de seguridad: $sg"
done


An error occurred (InvalidGroupId.Malformed) when calling the DeleteSecurityGroup operation: The security-group ID 'sg-03f0c731e21ec0e7f	sg-0a0b2001a2b132bde	sg-0becd2e808068c532' is malformed
Eliminado el grupo de seguridad: sg-03f0c731e21ec0e7f	sg-0a0b2001a2b132bde	sg-0becd2e808068c532
```







