#!/usr/bin/env bash

MESSAGE="$1"
LOWER_LIMIT=$2
PATTERN="$3"

while :; do
    printf "$MESSAGE"
    read -r INPUT

    # Convert string to uppercase
    INPUT=$(tr '[:lower:]' '[:upper:]' <<< "$INPUT")

    if [[ "$INPUT" =~ $PATTERN ]]; then
        # Get size unit
        SIZE_UNIT=$(tr -dc "[:upper:]" <<< "$INPUT")

        # Get numbers only and clear trailing zeroes
        INPUT=$(echo "$INPUT" | tr -dc '0-9' | sed -E 's/^0+//')

        # Convert GBs to MBs
        if [[ "$SIZE_UNIT" = "G" ]]; then INPUT=$((INPUT * 1024)); fi

        if ((INPUT >= LOWER_LIMIT)); then
            break
        else
            echo "Value is too low. Try one that is equal to or bigger than ${LOWER_LIMIT}M"
        fi
    else
        printf "Wrong value! Use this format: $PATTERN\n"
    fi
done
