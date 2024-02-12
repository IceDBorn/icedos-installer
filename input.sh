#!/usr/bin/env bash

MESSAGE="$1"
LOWER_LIMIT=$2
PATTERN="$3"

while :; do
    printf "$MESSAGE"
    read -r INPUT

    # Convert string to uppercase
    INPUT=$(echo "$INPUT" | tr '[:lower:]' '[:upper:]')

    if [[ "$INPUT" =~ $PATTERN ]]; then
        # TODO: Convert swap from G to M if needed


        # Get numbers only and clear trailing zeroes
        INPUT=$(echo "$INPUT" | tr -dc '0-9' | sed -E 's/^0+//')

        if ((INPUT >= LOWER_LIMIT)); then
            break
        else
            echo "Value is too low. Try one that is equal to or bigger than ${LIMIT}M"
        fi
    else
        printf "Wrong value! Use this format: $PATTERN\n"
    fi
done
