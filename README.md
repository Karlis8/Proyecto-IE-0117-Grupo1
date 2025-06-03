# Proyecto-IE-0117-Grupo1
Para habilitar el servicio:

es necesaria la instalación de itnotify-tools, puede ser instalada con el siguiente comando sudo apt-get -y install inotify-tools

primero, dentro  del archivo monitoreo_led.sh, en la linea 5, después de FILE debe estar la ruta al escritorio
después, dentro del archivo monitoeo_led.service, cambiar el usuario en linea18, por un usuario que tenga acceso a GPIO

el archivo monitoreo_led.sh debe tener permisos de ejecución, pueden ser otorgados con chmod +x monitoreo_led.sh

Después de realizar estos cambios, se debe mover(o copiar) el archivo monitoreo_led/sh a /usr/local/bin, puede ser con el comando 
sudo cp monitoreo_led.sh /usr/local/bin/monitoreo_led.sh para copiar o sudo mv monitoreo_led.sh /usr/local/bin/monitoreo_led.sh para mover

luego debe copiar o mover el archivo monitoreo_led.ervice a etc/systemctl/system, con el comando
sudo cp monitoreo_led.service etc/systemctl/system/monitoreo_led.service para copiar o sudo mv monitoreo_led.service etc/systemctl/system/monitoreo_led.service para mover

para habilitar el servicio es necesario ejecutar los siguientes comandos en la terminal
sudo systemctl daemon-reexecc
sudo systemctl daemon-reload
sudo systemctl enable monitor_led.service 
sudo systemctl start monitor_led.service

ver la salida del servicio
journalctl -u monitoreo_led.service -f

para deshabilitar
sudo systemctl stop monitor_led.service
sudo systemctl disable monitor_led.service
