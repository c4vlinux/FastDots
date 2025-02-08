#!/bin/bash
GITHUB_NAME="c4dots"
search_light=false
diodon=false
reboot=false

function list_configs() {
    local -n res=$1
    repos="$(curl -s "https://api.github.com/users/$GITHUB_NAME/repos" | grep -o '"name": "[^"]*' | cut -d'"' -f4)"

    # AKA. ratelimited by github
    if [[ "$repos" == "" ]]; then
        repos="gnome_green_feb_25 gnome_modern_feb_25 grub_2themes_feb_25 sddm_astronaut_feb_25"
    fi

    echo $repos | tr ' ' '\n' | awk -v github="$GITHUB_NAME" 'BEGIN { printf "%-3s %-20s %-40s\n", "ID", "NAME", "URL" } { printf "%-3s %-20s %-40s\n", NR, $1, "https://github.com/" github "/" $1 }'
    res=($(echo "$repos" | tr ' ' '\n' | awk '{ print $1 }'))
}

function load_config() {
    # Usage: load_config $config
    cd ~/
    echo ">> Installing $config..."
    command='bash <(curl -s "https://raw.githubusercontent.com/c4dots/$1/refs/heads/main/pacman.sh") --ignore-wrong-attr '

    if [[ "$diodon" = false ]]; then
        command+=" --no-diodon"
    fi

    if [[ "$reboot" = false ]]; then
        command+=" --no-reboot"
    fi

    if [[ "$search_light" = false ]]; then
        command+=" --no-search-light"
    fi

    eval "$command"

    cd ~/
    sudo rm -R "$1"
    echo ">> Done!"
}

function ask_for_config() {
    local -n res="$1"
    i=false
    while true; do
        clear
        if [[ "$i" == "true" ]]; then
            echo ">> Invalid Config! Try again!"
        fi

        echo ">> List of Configs:"
        list_configs configs
        echo ""
        echo "======================================================="
        echo ""
        read -p "Select one configuration: " selection

        if [[ "$selection" =~ ^[0-9]+$ ]] && (( selection > 0 && selection <= ${#configs[@]} )); then
            selection=${configs[$(($selection-1))]}
            break
        fi


        i=true
    done
    res="$selection"
}

for ARG in "$@"; do
  case $ARG in
    --x=*)
      x="${ARG#*=}"
      list_configs configs &> /dev/null
      name=${configs[$(($x-1))]}
      load_config "$name"
      exit 0
      ;;
    --n=*)
      name="${ARG#*=}"
      load_config "$name"
      exit 0
      ;;
    --diodon)
      diodon=true
      ;;
    --search-light)
      search_light=true
      ;;
    --reboot)
      search_light=true
      ;;
    --repo=*)
      x="${ARG#*=}"
      list_configs configs &> /dev/null
      name=${configs[$(($x-1))]}
      echo ">> https://github.com/$GITHUB_NAME/$name/"
      exit 0
      ;;
    *)
      echo ">> Usage: $0 [--x=<config_id>] [--n=<config_name>] [--search-light] [--reboot] [--diodon] [--repo=<repo-id>]"
      echo ">> Example: $0 [--x=1] [--n=gnome_green_feb_25] [--search-light] [--reboot] [--diodon] [--repo=1]"
      exit 1
      ;;
  esac
done

ask_for_config config
load_config $config
