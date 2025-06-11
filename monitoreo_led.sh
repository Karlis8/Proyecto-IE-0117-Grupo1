#!/bin/bash
 
#este archivo debe tener permisos de ejecucion (chmod +x monitoreo_led.sh)

trap 'terminar' SIGINT SIGTERM #esto llama la funcion terminar al detener el script
terminar() { #esta funcion termina el subproceso verificar_proceso
    echo " Saliendo..."
    kill "$PID_VERIFICADOR" 2>/dev/null
    exit
}

FILE=/home/vboxuser/Escritorio/monitoreo_led.txt #esta ruta depende de cada equipo, reemplazar por la ruta al escritorio de cada equipo

#lo primero es saber si existe el archivo de monitoreo, esto se va a repetir en bucle. por lo que deberia crear el archivo solo la primera iteracion 
if [ -f "$FILE" ]; then
    echo "archivo encontrado" #esto no deberia aparecer en la version final
else
    echo "El archivo no existe" #si el archivo no existe, lo creamos
    touch "$FILE"
    echo "$FILE creado"
fi


encender_led(){
  echo "led encendido"
  #aqui deberia invocar el comando que diga al kernel que encienda el led
}

apagar_led(){
    echo "led apagado"
    #aqui deberia invocar el comando que diga al kernel que apague el led
}

verificar_proceso(){
    while true; do
        if [ -n "$PID" ]; then #si hay un pid guardado, verifica si el proceso está activo
            if ! ps -p "$PID" > /dev/null; then #si el proceso no está activo, apaga el led
                echo "El proceso $PID no está activo, apagar LED"
                PID="" #esto limpia el pid
                apagar_led
            fi
        fi
    sleep 1
    done
}

PID="" # esto va a almacenar el pid del proceso que abra el archivo
verificar_proceso & #esto llama a la funcion verificar proceso a trabajar en segundo plano
PID_VERIFICADOR=$! #esto guarda el pid del subproceso

while true; do #esto crea un bucle que esta revisando coninuamente si el archivo es abierto o cerrado
EVENTO=$(inotifywait --format '%e' --event open,close_write,attrib "$FILE" 2>/dev/null) 



 #si hay un evento, lo imprime y lo procesa
    echo "$EVENTO"
    
    if [[ "$EVENTO" == *"OPEN"* ]]; then #si el archivo fue abierto...
        PID=$(lsof -t "$FILE" 2>/dev/null | head -n 1) #toma el pproceso que lo abre
        if [ -n "$PID" ]; then
            echo "Archivo abierto con el proceso $PID" #si hay proceso enciende el led
            encender_led
        else
            echo "open sin proceso activo ignorado" #si ya no hay proceso, entonces es un access al cerrar 
        fi
       
    elif [[ "$EVENTO" == *"CLOSE_WRITE"* ]]; then #si el archivo fue cerrado despues de modificar...
        echo "Archivo cerrado" 
        apagar_led

    elif [[ "$EVENTO" == *"ATTRIB"* ]]; then #si el archivo fue cerrado despues de modificar...
        echo "Archivo guardado" 
        apagar_led

    fi #cierra el if
done


    fi #cierra el if

fi
done


