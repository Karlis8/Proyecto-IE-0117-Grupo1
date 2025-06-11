#!/bin/bash
 
#este archivo debe tener permisos de ejecucion (chmod +x monitoreo_led.sh)

trap 'terminar' SIGINT SIGTERM #esto llama la funcion terminar al detener el script
terminar() { #esta funcion termina el subproceso verificar_proceso
    echo " Saliendo..."
    kill "$PID_VERIFICADOR" 2>/dev/null
    kill "$PID_BPFTRACE" 2>/dev/null
    exit
}

FILE=/home/vboxuser/Escritorio/monitoreo_led.txt #esta ruta depende de cada equipo, reemplazar por la ruta al escritorio de cada equipo
EDITOR="mousepad"
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

verificar_proceso() {
    while true; do
        # Busca el PID del editor con ese archivo abierto
        local pid=$(pgrep -af "$EDITOR" | grep -F "$FILE" | awk '{print $1}' | head -n 1)
        
        if [[ -n "$pid" ]]; then
            if [[ "$EDITOR_PID" != "$pid" ]]; then
                echo "Editor $EDITOR abierto con $FILE (PID $pid)"
                EDITOR_PID="$pid"
                encender_led
            fi
        else
            if [[ -n "$EDITOR_PID" ]]; then
                echo "Editor $EDITOR cerrado o no con $FILE"
                EDITOR_PID=""
                apagar_led
            fi
        fi
        sleep 1
    done
}
PID="" # esto va a almacenar el pid del proceso que abra el archivo
verificar_proceso & #esto llama a la funcion verificar proceso a trabajar en segundo plano
PID_VERIFICADOR=$! #esto guarda el pid del subproceso

exec 3< <(  #esto es un subproceso en segundo plano que registra el proceso que abre el archivo
    
    sudo bpftrace -e "
    tracepoint:syscalls:sys_enter_openat
    /str(args->filename) == \"$FILE\"/
    {
        printf(\"%d\\n\", pid);
    }" 2>/dev/null
)
PID_BPFTRACE=$!


while true; do #esto crea un bucle que esta revisando coninuamente si el archivo es abierto o cerrado
EVENTO=$(inotifywait --format '%e' --event open,close_write,attrib "$FILE" 2>/dev/null) 



 #si hay un evento, lo imprime y lo procesa
    echo "$EVENTO"
    
    if [[ "$EVENTO" == *"OPEN"* ]]; then #si el archivo fue abierto...
        while read -t 1 -u 3 line; do #toma el proceso que lo abre
            if [[ "$line" =~ ^[0-9]+$ ]]; then
                PID="$line"
                break
            fi
        done
        if [ -n "$PID" ]; then 
            editor=$(ps -p "$PID" -o comm=)
            if [[ "$editor" == "$EDITOR" ]]; then
                if [ "$EDITOR_PID" != "$PID" ]; then
                    echo "Archivo abierto con $EDITOR (PID $PID)"
                    EDITOR_PID="$PID"
                    encender_led
                fi
            else
                echo "Archivo abierto por otro proceso ($editor), ignorado"
            fi
        fi
       
    elif [[ "$EVENTO" == *"CLOSE_WRITE"* ]]; then #si el archivo fue cerrado despues de modificar...
        echo "Archivo cerrado" 
        apagar_led

    elif [[ "$EVENTO" == *"ATTRIB"* ]]; then #si el archivo fue cerrado despues de modificar...
        echo "Archivo guardado" 
        apagar_led

    fi #cierra el if
done

