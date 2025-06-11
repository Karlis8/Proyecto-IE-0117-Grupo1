#!/bin/bash
 
#este archivo debe tener permisos de ejecucion (chmod +x monitoreo_led.sh)

FILE=/home/vboxuser/Escritorio/monitoreo_led.txt #esta ruta depende de cada equipo, reemplazar por la ruta al escritorio de cada equipo
EDITOR="mousepad" #todo el proyecto esta pensado para funcionar con mousepad

command -v inotifywait >/dev/null || { echo "inotifywait no está instalado"; exit 1; } #esto avisa si falta alguna dependencia
command -v pgrep >/dev/null || { echo "pgrep no está instalado"; exit 1; }

trap 'terminar' SIGINT SIGTERM #esto llama la funcion terminar al detener el script
terminar() { #esta funcion termina el subproceso verificar_proceso
    echo " Saliendo..."
    kill "$PID_VERIFICADOR" 2>/dev/null
    exit
}

encender_led(){
  echo "led encendido"
  #aqui deberia invocar el comando que diga al kernel que encienda el led
}

apagar_led(){
    echo "led apagado"
    #aqui deberia invocar el comando que diga al kernel que apague el led
}

parpadeo(){
    tempo=0.3
    apagar_led
    sleep $tempo
    encender_led
    sleep $tempo
    apagar_led
    sleep $tempo
    encender_led
}

verificar_proceso() {
    while true; do
        # Busca el PID del editor con ese archivo abierto
        local pid=$(pgrep -af "$EDITOR" | grep -F "$FILE" | awk '{print $1}' | head -n 1)
        
        if [[ -n "$pid" ]]; then
            if [[ "$EDITOR_PID" != "$pid" ]]; then
                echo "-Editor $EDITOR abierto con $FILE (PID $pid)"
                encender_led
                EDITOR_PID="$pid"
            fi
        else
            if [[ -n "$EDITOR_PID" ]]; then
                sleep 1
                echo "-Archivo cerrado"
                EDITOR_PID=""
                apagar_led
            fi
        fi
        sleep 1
    done
}


#lo primero es saber si existe el archivo de monitoreo, esto se va a repetir en bucle. por lo que deberia crear el archivo solo la primera iteracion 
if [ -f "$FILE" ]; then
    echo "archivo encontrado" #esto no deberia aparecer en la version final
else
    echo "El archivo no existe" #si el archivo no existe, lo creamos
    touch "$FILE"
    echo "$FILE creado"
fi

verificar_proceso & #esto llama a la funcion verificar proceso a trabajar en segundo plano
PID_VERIFICADOR=$! #esto guarda el pid del subproceso


while true; do #esto crea un bucle que esta revisando coninuamente si el archivo es abierto o cerrado
EVENTO=$(inotifywait --format '%e' --event open,close_write,attrib "$FILE" 2>/dev/null) 
 #si hay un evento, lo imprime y lo procesa  
    if [[ "$EVENTO" == *"ATTRIB"* ]]; then #si el archivo fue cerrado despues de modificar...
        echo "-Archivo guardado" 
        parpadeo

    fi #cierra el if
done

