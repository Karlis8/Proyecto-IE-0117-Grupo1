#!/bin/bash
 
#este archivo debe tener permisos de ejecucion (chmod +x demonio.sh)

FILE=/home/aaron/Escritorio/monitoreo_led.txt #esta ruta depende de cada equipo, reemplazar por la ruta al escritorio de cada equipo

#lo primero es saber si existe el archivo de monitoreo, esto se va a repetir en bucle. por lo que deberia crear el archivo solo la primera iteracion 
if [ -f "$FILE" ]; then
    echo "archivo encontrado" #esto no deberia aparecer en la version final
else
    echo "El archivo no existe" #si el archivo no existe, lo creamos
    touch "$FILE"
    echo "$FILE creado"
fi

while true; do #esto crea un bucle que esta revisando coninuamente si el archivo es abierto o cerrado
EVENTO=$(inotifywait -e open,close_write,close_nowrite,delete_self --format '%e' "$FILE" 2>/dev/null) 
         if [[ "$EVENTO" == *"OPEN"* ]]; then #si el archivo esta abierto...
            echo "Archivo abierto" #aqui deberia invocar el comando que diga al kernel que encienda el led

        elif [[ "$EVENTO" == *"CLOSE_WRITE"* || "$EVENTO" == *"CLOSE_NOWRITE"* || "$EVENTO" == *"DELETE_SELF"* ]]; then #si el archivo fue cerrado despues de modificar, o solo fue cerrado...
            echo "Archivo cerrado" #aqui deberia invocar el comando que diga al kernel que apague el led

        fi #cierra el if
done
