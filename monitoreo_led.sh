#!/bin/bash
 
#este archivo debe tener permisos de ejecucion (chmod +x demonio.sh)

FILE=/home/vboxuser/Escritorio/monitoreo_led.txt #esta ruta depende de cada equipo, reemplazar por la ruta al escritorio de cada equipo

#lo primero es saber si existe el archivo de monitoreo, esto se va a repetir en bucle. por lo que deberia crear el archivo solo la primera iteracion 
if [ -f "$FILE" ]; then
    echo "archivo encontrado" #esto no deberia aparecer en la version final
else
    echo "El archivo no existe" #si el archivo no existe, lo creamos
    touch "$FILE"
    echo "$FILE creado"
fi

PID="" # esto va a almacenar el pid del proceso que abra el archivo
contador_open=0
while true; do #esto crea un bucle que esta revisando coninuamente si el archivo es abierto o cerrado



EVENTO=$(inotifywait -t 3  --format '%e' "$FILE" 2>/dev/null) #cada segundo verifica si hay un proceso

if [ -z "$EVENTO" ]; then #si evento está vacío, verifica si hay un pid guardado
    if [ -n "$PID" ]; then #si hay un pid guardado, verifica si el proceso está activo
        if ! ps -p "$PID" > /dev/null; then #si el proceso no está activo, apaga el led
            echo "El proceso $PID no está activo, apagar LED"
            contador_open=0
            PID="" #esto limpia el pid

            #aqui deberia invocar el comando que diga al kernel que apague el led

        fi
    fi
else #si hay un evento, lo imprime y lo procesa
    echo "$EVENTO"
    if [[ "$EVENTO" == *"OPEN"* ]]; then #si el archivo esta abierto...
        PID=$(lsof "$FILE" | awk 'NR==2 {print $2}') #esto guarda el pid del proceso
        contador_open=$((contador_open + 1))
        if [[ "$contador_open" -eq 1 ]]; then #la idea es que si detectmos dos open seguidos quiere decir que guardó
            echo "Archivo abierto"

            #aqui deberia invocar el comando que diga al kernel que encienda el led

        else
            echo "proceso terminado "

            #aqui deberia invocar el comando que diga al kernel que apague el led
        fi

    elif [[ "$EVENTO" == *"ACCESS"* ]]; then #si el archivo fue abierto...
        #echo "Archivo abierto"
        
        #aqui deberia invocar el comando que diga al kernel que encienda el led

    elif [[ "$EVENTO" == *"CLOSE_WRITE"* ]]; then #si el archivo fue cerrado despues de modificar...
        echo "Archivo cerrado" 
        contador_open=0
        #aqui deberia invocar el comando que diga al kernel que apague el led

    elif [[ "$EVENTO" == *"ATTRIB"* ]]; then #si el archivo fue cerrado despues de modificar...
        echo "Archivo guardado" 
        contador_open=0

        #aqui deberia invocar el comando que diga al kernel que apague el led


    fi #cierra el if

fi
done

