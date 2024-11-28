# Configuración de un Clúster Hadoop Pseudo-Distribuido en Docker

Este documento proporciona una guía detallada para configurar un clúster Hadoop en modo pseudo-distribuido utilizando Docker. Al final de esta guía, tendrás un entorno Hadoop completamente funcional en un contenedor Docker, ideal para propósitos de desarrollo y pruebas.

---

## **Tabla de Contenidos**

1. [Introducción](#introducción)
2. [Prerrequisitos](#prerrequisitos)
3. [Estructura del Proyecto](#estructura-del-proyecto)
   - 3.1. [Descargar Hadoop](#descargar-hadoop)
4. [Configuración de Hadoop](#configuración-de-hadoop)
   - 4.1. [core-site.xml](#core-sitexml)
   - 4.2. [hdfs-site.xml](#hdfs-sitexml)
   - 4.3. [mapred-site.xml](#mapred-sitexml)
   - 4.4. [yarn-site.xml](#yarn-sitexml)
5. [Archivo Dockerfile](#archivo-dockerfile)
6. [Script de Inicio: start-hadoop.sh](#script-de-inicio-start-hadoopsh)
7. [Construcción y Ejecución del Contenedor](#construcción-y-ejecución-del-contenedor)
   - 7.1. [Construir la Imagen Docker](#71-construir-la-imagen-docker)
   - 7.2. [Ejecutar el Contenedor Docker](#72-ejecutar-el-contenedor-docker)
8. [Verificación de la Configuración](#verificación-de-la-configuración)
   - 8.1. [Comprobar los Procesos de Hadoop](#81-comprobar-los-procesos-de-hadoop)
   - 8.2. [Acceder a las Interfaces Web](#82-acceder-a-las-interfaces-web)
   - 8.3. [Probar Comandos HDFS](#83-probar-comandos-hdfs)
   - 8.4. [Ejecutar un Trabajo de MapReduce](#84-ejecutar-un-trabajo-de-mapreduce)
9. [Conclusión](#conclusión)
---

## **Introducción**

La configuración de un clúster Hadoop en modo **pseudo-distribuido** permite simular un entorno distribuido en una sola máquina. Utilizando Docker, podemos aislar este entorno, facilitando su gestión y portabilidad.

---

## **Prerrequisitos**

- **Docker** instalado en tu sistema.
- Conocimientos básicos de **Linux** y **Docker**.
- Conexión a Internet para descargar Hadoop y las imágenes base.

---

## **Estructura del Proyecto**

Organiza tu proyecto con la siguiente estructura de directorios y archivos:

```bash
hadoop-pseudo-docker/
├── config/
│   ├── core-site.xml
│   ├── hdfs-site.xml
│   ├── mapred-site.xml
│   └── yarn-site.xml
├── Dockerfile
├── hadoop-3.4.1.tar.gz
└── start-hadoop.sh
```

- **config/**: Directorio que contiene los archivos de configuración de Hadoop.
- **Dockerfile**: Archivo de construcción de la imagen Docker.
- **hadoop-3.4.1.tar.gz**: Archivo comprimido de Hadoop (debe descargarse previamente).
- **start-hadoop.sh**: Script para iniciar los servicios dentro del contenedor.

---

## **Descargar Hadoop**

Descarga la versión de Hadoop que deseas utilizar desde el [sitio oficial de Apache Hadoop](https://hadoop.apache.org/releases.html). En este caso, se utiliza Hadoop 3.4.1.

```bash
wget https://downloads.apache.org/hadoop/common/hadoop-3.4.1/hadoop-3.4.1.tar.gz
```

## **Configuración de Hadoop**

Crea los archivos de configuración en el directorio `config/` con el contenido siguiente.

### **core-site.xml**

Configura el sistema de archivos predeterminado.

```xml
<?xml version="1.0"?>
<configuration>
    <property><?xml version="1.0"?>
       <configuration>
          <property>
             <name>fs.defaultFS</name>
             <value>hdfs://localhost:9000</value>
          </property>
          <property>
             <name>hadoop.http.staticuser.user</name>
             <value>hadoop</value>
          </property>
       </configuration>
    </property>
</configuration>
```

### **hdfs-site.xml**

Establece la replicación de datos.

```xml
<?xml version="1.0"?>
<configuration><?xml version="1.0"?>
   <configuration>
      <property>
         <name>dfs.replication</name>
         <value>1</value>
      </property>
      <property>
         <name>dfs.namenode.name.dir</name>
         <value>/datos/namenode</value>
      </property>
      <property>
         <name>dfs.datanode.data.dir</name>
         <value>/datos/datanode</value>
      </property>
   </configuration>
</configuration>
```

### **mapred-site.xml**

Define el framework de MapReduce.

```xml
<?xml version="1.0"?>
<configuration>
    <property>
        <name>mapreduce.framework.name</name>
        <value>yarn</value>
    </property>
</configuration>
```

### **yarn-site.xml**

Configura YARN para soportar MapReduce.

```xml
<?xml version="1.0"?>
<configuration>
    <property>
        <name>yarn.nodemanager.aux-services</name>
        <value>mapreduce_shuffle</value>
    </property>
</configuration>
```

---

## **Archivo Dockerfile**

El `Dockerfile` define cómo se construirá la imagen Docker. A continuación, se presenta el contenido completo:

```dockerfile
# Base image
FROM openjdk:11-jdk

# Set environment variables
ENV HADOOP_VERSION=3.4.1
ENV HADOOP_HOME=/usr/local/hadoop
ENV JAVA_HOME=/usr/local/openjdk-11
ENV PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin

# Install necessary packages
RUN apt-get update && \
    apt-get install -y openssh-server wget rsync sudo && \
    rm -rf /var/lib/apt/lists/*

# Create hadoop user and group
RUN groupadd hadoop && \
    useradd -ms /bin/bash -g hadoop hadoop

# Allow hadoop user to use sudo without password
RUN echo "hadoop ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Configure SSH for hadoop user
RUN mkdir -p /home/hadoop/.ssh && \
    ssh-keygen -t rsa -f /home/hadoop/.ssh/id_rsa -q -N "" && \
    cat /home/hadoop/.ssh/id_rsa.pub >> /home/hadoop/.ssh/authorized_keys && \
    chown -R hadoop:hadoop /home/hadoop/.ssh && \
    chmod 600 /home/hadoop/.ssh/authorized_keys

# Install Hadoop
COPY hadoop-${HADOOP_VERSION}.tar.gz /tmp/
RUN tar -xzvf /tmp/hadoop-${HADOOP_VERSION}.tar.gz -C /usr/local/ && \
    mv /usr/local/hadoop-${HADOOP_VERSION} $HADOOP_HOME && \
    rm /tmp/hadoop-${HADOOP_VERSION}.tar.gz && \
    chown -R hadoop:hadoop $HADOOP_HOME

# Configure Hadoop environment variables
RUN echo "export JAVA_HOME=/usr/local/openjdk-11" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh

# Copy configuration files
COPY config/* $HADOOP_HOME/etc/hadoop/
RUN chown -R hadoop:hadoop $HADOOP_HOME/etc/hadoop/

#crear namenode y datanode
RUN mkdir -p /datos/namenode/current && \
    chown -R hadoop:hadoop /datos

# Switch to hadoop user
USER hadoop

# Format HDFS
RUN $HADOOP_HOME/bin/hdfs namenode -format -force

# Expose ports
EXPOSE 9870 8088 9000 8042 22 9864

# Switch back to root to copy the start script
USER root

# Copy the start script
COPY start-hadoop.sh /start-hadoop.sh
RUN chmod +x /start-hadoop.sh

# Switch to hadoop user
USER hadoop

# Set entry point
CMD ["/start-hadoop.sh"]
```

---

## **Script de Inicio: start-hadoop.sh**

Crea el archivo `start-hadoop.sh` en el directorio raíz de tu proyecto con el siguiente contenido:

```bash
#!/bin/bash

# Iniciar el servicio SSH (requiere privilegios de root)
sudo service ssh start

# Iniciar los servicios de Hadoop
$HADOOP_HOME/sbin/start-dfs.sh
$HADOOP_HOME/sbin/start-yarn.sh

# Mantener el contenedor en ejecución
tail -f /dev/null
```

Concede permisos de ejecución al script:

```bash
chmod +x start-hadoop.sh
```

# Construcción y Ejecución del Contenedor

## **7. Construcción y Ejecución del Contenedor**

### **7.1. Construir la Imagen Docker**

Ejecuta el siguiente comando desde el directorio raíz del proyecto para construir la imagen Docker:

```bash
docker build -t hadoop-pseudo .
```

- `-t hadoop-pseudo`: Asigna el nombre `hadoop-pseudo` a la imagen.
- `.`: Especifica el contexto de construcción como el directorio actual.

### **7.2. Ejecutar el Contenedor Docker**

Inicia un contenedor a partir de la imagen creada:

```bash
docker run -it --name hadoop-container \
    -p 9870:9870 \
    -p 8088:8088 \
    -p 9000:9000 \
    -p 8042:8042 \
    -p 22:22 \
    -p 9864:9864 \
    hadoop-pseudo
```

- `-it`: Ejecuta el contenedor en modo interactivo.
- `--name hadoop-container`: Asigna el nombre `hadoop-container` al contenedor.
- `-p`: Mapea puertos para permitir el acceso a las interfaces web.

### **Configuración Crítica de /etc/hosts**

Para que Hadoop funcione correctamente, es **esencial** agregar una entrada en el archivo `/etc/hosts` de tu máquina anfitriona para mapear `localhost` a `hadoop-container-id`. Esto se puede hacer añadiendo la siguiente línea:

```plaintext
127.0.0.1   hadoop-container-id (sería algo así -> 509a58aebacd)
```




---

## **8. Verificación de la Configuración**

### **8.1. Comprobar los Procesos de Hadoop**

Dentro del contenedor, ejecuta el comando `jps` para verificar los procesos en ejecución:

```bash
jps
```

Deberías obtener una salida similar a:

```
XXXX NameNode
XXXX DataNode
XXXX ResourceManager
XXXX NodeManager
XXXX SecondaryNameNode
XXXX Jps
```

Cada uno de estos procesos representa un componente clave de Hadoop.

### **8.2. Acceder a las Interfaces Web**

Verifica que las interfaces web estén funcionando accediendo a las siguientes URL desde tu navegador:

- **NameNode UI**: [http://localhost:9870](http://localhost:9870)  
  Proporciona información sobre el sistema de archivos distribuido (HDFS).
  
- **ResourceManager UI**: [http://localhost:8088](http://localhost:8088)  
  Muestra información sobre los recursos YARN y las aplicaciones en ejecución.

### **8.3. Probar Comandos HDFS**

Prueba el sistema de archivos HDFS creando un directorio:

```bash
hdfs dfs -mkdir /user/hadoop
hdfs dfs -ls /user
```

Si todo está configurado correctamente, deberías ver el directorio listado sin errores.

### **8.4. Ejecutar un Trabajo de MapReduce**

Ejecuta un ejemplo de cálculo de Pi para probar el framework MapReduce:

```bash
hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar pi 2 5
```

Este comando ejecutará un trabajo de MapReduce y mostrará una estimación del valor de Pi.

---

## **9. Conclusión**

Has configurado exitosamente un clúster Hadoop en modo pseudo-distribuido dentro de un contenedor Docker. Este entorno te permite desarrollar y probar aplicaciones Hadoop sin necesidad de un clúster físico distribuido, reduciendo la complejidad.

