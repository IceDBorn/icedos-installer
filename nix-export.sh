EXEC="$1"
PATH="$(nix-shell --quiet -p "$EXEC" --run "bash -c 'which $EXEC'")"

echo "Querying nix store for $EXEC..."

echo "$PATH"

