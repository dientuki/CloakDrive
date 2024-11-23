#!/bin/bash

# Env config
DEVICE="/dev/ttyACM0"  # Cambia esto si tu puerto es diferente
BAUD=9600

if [ ! -c "$DEVICE" ]; then
  exit 1
fi

xset dpms 0 0 300

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

# Kill
trap 'kill $(jobs -p) && xrandr --output eDP-1 --brightness 1.0; exit' SIGINT SIGTERM