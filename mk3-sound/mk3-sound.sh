#!/bin/bash

# Env config
DEVICE="/dev/ttyACM0"  # Cambia esto si tu puerto es diferente
BAUD=9600
SOUND="/proc/asound/card0/pcm0p/sub0/status"
VOLUME_CONTROL="Master"

initial_volume=0
final_volume=100
duration=5
isSound=false
soundUpPid=0

if [ ! -c "$DEVICE" ]; then
  exit 1
fi

xset dpms 0 0 120
echo "L" > $DEVICE
amixer sset "$VOLUME_CONTROL" $initial_volume% >/dev/null 2>&1

change_brightness() {
  local initial_value=$1
  local final_value=$2
  local time=$3

  # Calculate the number of steps (100 steps for smooth transition)
  local steps=100
  local increment=$(echo "($final_value - $initial_value) / $steps" | bc -l)
  local time_per_step=$(echo "$time / $steps" | bc -l)

  local current_value=$initial_value

  for i in $(seq 1 $steps); do
    xrandr --output eDP-1 --brightness $current_value
    current_value=$(echo "$current_value + $increment" | bc -l)
    sleep $time_per_step
  done
}

# Función de easing (ejemplo: easing cuadrático)
easing() {
  local t=$1   # tiempo actual
  local b=$2   # volumen inicial
  local c=$3   # cambio de volumen (final - inicial)
  local d=$4   # duración

  # Easing cuadrático: t/d * t
  # echo $(bc -l <<< "$b + $c * (($t / $d) * ($t / $d))")
  # Easing sinusoidal: 1 - cos(t / d * (pi / 2))
  echo $(bc -l <<< "$b + $c * (1 - c(3.14159 * $t / (2 * $d)))")
}

# Función para subir el volumen con easing
soundUp() {
  start_time=$(date +%s)

  while true; do
    current_time=$(($(date +%s) - $start_time))

    # Verificamos si hemos alcanzado la duración deseada
    if [ $current_time -ge $duration ]; then
      # Establecemos el volumen final
      amixer sset "$VOLUME_CONTROL" $final_volume% >/dev/null 2>&1
      break
    fi

    # Calculamos el volumen con la función de easing
    eased_volume=$(easing $current_time $initial_volume $(($final_volume - $initial_volume)) $duration)

    # Establecemos el volumen con amixer (eliminamos decimales)
    amixer sset "$VOLUME_CONTROL" ${eased_volume%\.*}% >/dev/null 2>&1

    # Esperamos un poco antes de la siguiente actualización
    sleep 0.1
  done
}

# Configurar el puerto serie
stty -F $DEVICE $BAUD cs8 -cstopb -parenb -hupcl

# Proceso en segundo plano para leer del Arduino
read_arduino() {
  while IFS= read -r line < "$DEVICE"; do
    if [[ -n "$line" ]]; then
      line=$(echo "$line" | tr -d '\r\n' | xargs)

      if [[ "$line" == "1" ]]; then
        monitor_status=$(xset q | grep "Monitor is" | awk '{print $3}')
        if [ "$monitor_status" == "Off" ]; then
          echo 'encender'
          xrandr --output eDP-1 --brightness 0.0
          xset dpms force on
          change_brightness 0.0 1.0 5      
        else
          xset s reset
        fi
      fi
    fi
  done
}

# Ejecutar la lectura en segundo plano
read_arduino &

# Monitorea cambios en el archivo especificado
inotifywait -m -e close "$SOUND" |
while read path action file; do
  status=$(cat "$SOUND")

  if [[ "$status" == "closed" ]]; then
    if [ "$isSound" == true ]; then
      if [ $soundUpPid -gt 0 ]; then
        kill $soundUpPid
        wait $soundUpPid 2>/dev/null  # Espera a que el proceso termine de matarse
        soundUpPid=0
      else
        final_volume=$(amixer get Master | grep -oP '\d+(?=%)' | head -n 1)
      fi
      
      echo "L" > $DEVICE
      amixer sset "$VOLUME_CONTROL" $initial_volume% >/dev/null 2>&1
      isSound=false
    fi
  else
    if [ "$isSound" == false ]; then
      isSound=true
      echo "H" > $DEVICE
      soundUp &
      soundUpPid=$!
    fi
  fi
done

# Kill
trap 'kill $(jobs -p) && xrandr --output eDP-1 --brightness 1.0; exit' SIGINT SIGTERM