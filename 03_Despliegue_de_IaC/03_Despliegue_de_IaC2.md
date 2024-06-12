```sh
➜  ~ aws sts get-caller-identity
    {
        "UserId": "AROAIU2Z2ULEWL3JH76BU:arodriguezjus@uoc.edu",
        "Account": "579845986493",
        "Arn": "arn:aws:sts::579845986493:assumed-role/student/arodriguezjus@uoc.edu"
    }
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
# PRIVATE KEY
➜  ~ cat ~/.ssh/new-key-pair

# PUBLIC KEY
➜  ~ cat ~/.ssh/new-key-pair.pub
```

```sh
➜  ~ chmod 400 ~/.ssh/new-key-pair
➜  ~ chmod 644 ~/.ssh/new-key-pair.pub
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

# confirmo que están en AWS
➜  ~ aws ec2 describe-key-pairs --query 'KeyPairs[*].KeyName' --output text

vagrant-master  
ansible-master  
ansible 
gborr_key       
vagrant-ubuntu  
new-key-pair    <--------
keys-pec        
ansible-public-key keys
```

**Configuro el Grupo de Seguridad**

```sh
➜  ~ SECURITY_GROUP_ID=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=my-security-group" --query 'SecurityGroups[0].GroupId' --output text)

echo $SECURITY_GROUP_ID

    sg-0d6bace4b983f1a7d
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

Aunque abrir el puerto 22 (SSH) a 0.0.0.0/0 es útil para pruebas y acceso general, no es recomendable para entornos de producción debido a los riesgos de seguridad. En un entorno de producción, deberías restringir el acceso SSH sólo a las direcciones IP específicas desde las cuales necesitas acceder a la instancia.

```sh
➜  ~ aws ec2 allocate-address

{
    "PublicIp": "18.192.157.65",
    "AllocationId": "eipalloc-00aeea23dd6ecb06e",
    "PublicIpv4Pool": "amazon",
    "NetworkBorderGroup": "eu-central-1",
    "Domain": "vpc"
}
```

**Verifico Instancias EC2 en Ejecución**

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


➜  ~ aws ec2 describe-instances --instance-ids i-013f4da9521e1b547 --query 'Reservations[*].Instances[*].State.Name' --output text

running
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
```

```sh
➜  ~ aws ec2 associate-address --instance-id i-013f4da9521e1b547 --allocation-id eipalloc-00aeea23dd6ecb06e 

{
    "AssociationId": "eipassoc-0e8e9ecb309b8ec81"
}
```

```sh
➜  ~ ssh -i ~/.ssh/new-key-pair ubuntu@18.192.157.65

The authenticity of host '18.192.157.65 (18.192.157.65)' can't be established.
ED25519 key fingerprint is SHA256:wdjG82/FOgNJpbtfu6CcCjk4vL/xOqSX+oLhXiEudrc.
This host key is known by the following other names/addresses:
    ~/.ssh/known_hosts:26: 18.199.200.65
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '18.192.157.65' (ED25519) to the list of known hosts.
ubuntu@18.192.157.65: Permission denied (publickey).
➜  ~ ssh -i ~/.ssh/new-key-pair ubuntu@18.199.200.65

^C
➜  ~ 
```

**Limpia el archivo known_hosts**

Puede haber un conflicto con las claves almacenadas anteriormente en el archivo known_hosts. Intenta eliminar la entrada correspondiente a la IP:

```sh
➜  ~ ssh-keygen -R 18.192.157.65

# Host 18.192.157.65 found: line 27
/Users/alex/.ssh/known_hosts updated.
Original contents retained as /Users/alex/.ssh/known_hosts.old
```


```sh
➜  ~ cat ~/.ssh/new-key-pair.pub 
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDgkIUISjOeb5qGDwaCKjkN38R67CXR+kpBCUh8EbRHfbpQZxrSMVm3r4dPsP/1Hre4Mq/BTmhuEXqjZDYJz1at0TdlI3VEXiOCPWhqUUh/vloBn5IbCHWnhGb74suntusZKUSUwwwhG6Wi9Xq6GcDBHupwT0jbtyq8QYoZEBKik0jmXEAKkZ37Qtvy+kLh5dnpxuFV5Arcv+8s2y2c6sRFwz5edaW3TQHi+z4CKMRkw4QwUNNt7ZJWT3S9Qpqkix8fCbdgOudxKw9Wk0iDaziO6MRO73/DOhcNOOlhwTn+TscurSW0EsIS51e5+Xkp9qtZ7d7pzoyVVxb8YmU/gV9z alex@Alexs-MacBook-Pro.local
```




