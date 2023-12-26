#!/bin/bash

echo "PID      TTY       STAT   TIME    COMMAND"

# Создаем массив, чтобы хранить информацию о процессах
declare -A processes

# Перебираем все директории /proc
for pid in /proc/[0-9]*/; do
    pid=${pid%*/}
    # Извлекаем PID
    pid=${pid##*/}

    # Проверяем, является ли PID числовым значением
    if [[ ! $pid =~ ^[0-9]+$ ]]; then
        continue
    fi

    # Проверяем наличие файла "stat" в директории PID
    if [ ! -e "/proc/$pid/stat" ]; then
        continue
    fi

    # Читаем информацию из файла "stat"
    stat=$(cat "/proc/$pid/stat")

    # Извлекаем нужные поля из строки
    tty=$(echo "$stat" | awk '{print $7}')
    state=$(echo "$stat" | awk '{print $3}')
    utime=$(echo "$stat" | awk '{print $14}')
    stime=$(echo "$stat" | awk '{print $15}')
    cmdline=$(tr -d '\0' < "/proc/$pid/cmdline")
    cmdline=${cmdline:-[N/A]}
    
    # Если поле cmdline пустое, извлекаем имя процесса из файла "stat"
    if [ "$cmdline" = "[N/A]" ]; then
        name=$(echo "$stat" | awk '{print $2}')
        cmdline=$name
    fi

    # Преобразуем время в формат ЧЧ:ММ:СС
    seconds=$((utime + stime))
    hours=$((seconds / 3600))
    minutes=$((seconds % 3600 / 60))
    seconds=$((seconds % 60))
    time=$(printf "%02d:%02d:%02d" $hours $minutes $seconds)

    # Сохраняем информацию о процессе в массиве
    processes["$pid"]="PID:$pid TTY:$tty STAT:$state TIME:$time COMMAND:$cmdline"
done

# Сортируем процессы по PID
sorted_pids=($(printf "%s\n" "${!processes[@]}" | sort -n))

# Выводим отсортированные процессы
for pid in "${sorted_pids[@]}"; do
    echo "${processes[$pid]}"
done
