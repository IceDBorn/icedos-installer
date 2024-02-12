#!/usr/bin/env bash

MESSAGE="$1"

while :; do
    printf "Enter ${MESSAGE} \n"
    A=$(systemd-ask-password)
    printf "Re-enter ${MESSAGE}\n"
    B=$(systemd-ask-password)

    if [ "$A" = "$B" ]; then
        FINAL="$A"
        break
    else
        printf "Passwords do not match...\n"
    fi
done

printf "$FINAL"
