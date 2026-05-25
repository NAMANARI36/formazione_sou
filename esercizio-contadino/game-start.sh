#!/bin/bash

# Config
IP_VM2="192.168.1.3"  # IP VM2
USER_VM2="vagrant"    # User VM2

restore_to_initial_state() {

    clear

    echo "Preparo lo stato iniziale del gioco"
    echo "Ripristino lo stato iniziale"

    sudo podman rm -a -f > /dev/null 2>&1
    ssh "$USER_VM2@$IP_VM2" "sudo podman rm -a -f > /dev/null 2>&1"

}

containers_init() {

    echo "Creo e avvio il container del Contadino"
    sudo podman run -d --name contadino alpine sleep infinity > /dev/null 2>&1
    actors_river_bank_a+=("contadino")

    echo "Creo e avvio il container del Lupo"
    sudo podman run -d --name lupo alpine sleep infinity > /dev/null 2>&1
    actors_river_bank_a+=("lupo")

    echo "Creo e avvio il container della Capra"
    sudo podman run -d --name capra alpine sleep infinity > /dev/null 2>&1
    actors_river_bank_a+=("capra")

    echo "Creo e avvio il container del Cavolo"
    sudo podman run -d --name cavolo alpine sleep infinity > /dev/null 2>&1
    actors_river_bank_a+=("cavolo")

    echo "Attendo l'avvio dei container..."
    sleep 8

}

check_constrictions() {

    farmer_position=""
    for element in "${actors_river_bank_a[@]}"; do
        if [[ "$element" == "contadino" ]]; then
            farmer_position="a"
        fi
    done
    for element in "${actors_river_bank_b[@]}"; do
        if [[ "$element" == "contadino" ]]; then
            farmer_position="b"
        fi
    done

    if [[ "$farmer_position" == "a" ]]; then
        uncovered_river_bank=("${actors_river_bank_b[@]}")
    else
        uncovered_river_bank=("${actors_river_bank_a[@]}")
    fi

    wolf_unattended=false
    goat_unattended=false
    cabbage_unattended=false

    for element in "${uncovered_river_bank[@]}"; do
        case "$element" in
            lupo)   wolf_unattended=true ;;
            capra)  goat_unattended=true ;;
            cavolo) cabbage_unattended=true ;;
        esac
    done

    if $wolf_unattended && $goat_unattended; then
        echo "SCONFITTA: il lupo ha mangiato la capra!"
        game_running=false
        return
    fi
    if $goat_unattended && $cabbage_unattended; then
        echo "SCONFITTA: la capra ha mangiato il cavolo!"
        game_running=false
        return
    fi

    farmer_on_b=false; wolf_on_b=false; goat_on_b=false; cabbage_on_b=false

    for element in "${actors_river_bank_b[@]}"; do
        case "$element" in
            contadino) farmer_on_b=true ;;
            lupo)      wolf_on_b=true ;;
            capra)     goat_on_b=true ;;
            cavolo)    cabbage_on_b=true ;;
        esac
    done
    if $farmer_on_b && $wolf_on_b && $goat_on_b && $cabbage_on_b; then
        echo "VITTORIA! Hai trasportato tutti sani e salvi sulla sponda B!"
        game_running=false
        return
    fi
}

game_init() {

    restore_to_initial_state

    actors_river_bank_a=()
    actors_river_bank_b=()

    containers_init

    farmer_position="a"
    game_running=true
    echo "Gioco Avviato!"

}

move_to_river_bank_b() {

    echo "Cosa vuoi spostare sulla sponda B?"

    select choice in "${actors_river_bank_a[@]}"; do

        if [[ -n "$choice" ]]; then
            echo "$choice verrà spostato sulla sponda B"

            actors_river_bank_b+=("$choice")

            if [[ "$choice" != "contadino" ]]; then
                sudo podman stop contadino > /dev/null 2>&1
                sudo podman rm contadino > /dev/null 2>&1
                ssh "$USER_VM2@$IP_VM2" "sudo podman run -d --name contadino alpine sleep infinity > /dev/null 2>&1"

                actors_river_bank_b+=("contadino")
                bank_a_without_farmer=()
                for element in "${actors_river_bank_a[@]}"; do
                    if [[ "$element" != "contadino" ]]; then
                        bank_a_without_farmer+=("$element")
                    fi
                done
                actors_river_bank_a=("${bank_a_without_farmer[@]}")
            fi

            new_bank_a=()
            for element in "${actors_river_bank_a[@]}"; do
                if [[ "$element" != "$choice" ]]; then
                    new_bank_a+=("$element")
                fi
            done
            actors_river_bank_a=("${new_bank_a[@]}")

            sudo podman stop "$choice" > /dev/null 2>&1
            sudo podman rm "$choice" > /dev/null 2>&1
            ssh "$USER_VM2@$IP_VM2" "sudo podman run -d --name $choice alpine sleep infinity > /dev/null 2>&1"

            echo "Attendo l'avvio dei container..."
            sleep 8

            check_constrictions
            break
        else
            echo "Scelta non valida, riprova."
        fi
    done

}

move_to_river_bank_a() {

    echo "Cosa vuoi spostare sulla sponda A?"

    select choice in "${actors_river_bank_b[@]}"; do
        if [[ -n "$choice" ]]; then
            echo "$choice verrà spostato sulla sponda A"
            actors_river_bank_a+=("$choice")

            if [[ "$choice" != "contadino" ]]; then
                ssh "$USER_VM2@$IP_VM2" "sudo podman stop contadino > /dev/null 2>&1; sudo podman rm contadino > /dev/null 2>&1"
                sudo podman run -d --name contadino alpine sleep infinity > /dev/null 2>&1
                actors_river_bank_a+=("contadino")

                bank_b_without_farmer=()
                for element in "${actors_river_bank_b[@]}"; do
                    if [[ "$element" != "contadino" ]]; then
                        bank_b_without_farmer+=("$element")
                    fi
                done
                actors_river_bank_b=("${bank_b_without_farmer[@]}")
            fi

            new_bank_b=()
            for element in "${actors_river_bank_b[@]}"; do
                if [[ "$element" != "$choice" ]]; then
                    new_bank_b+=("$element")
                fi
            done
            actors_river_bank_b=("${new_bank_b[@]}")

            ssh "$USER_VM2@$IP_VM2" "sudo podman stop $choice > /dev/null 2>&1; sudo podman rm $choice > /dev/null 2>&1"
            sudo podman run -d --name "$choice" alpine sleep infinity > /dev/null 2>&1

            echo "Attendo l'avvio dei container..."
            sleep 8

            check_constrictions
            break
        else
            echo "Scelta non valida, riprova."
        fi
    done
}

# Main del gioco
game_init

while $game_running; do
    echo "----------------------------------------------------------"
    echo "Sponda A: ${actors_river_bank_a[@]}"
    echo "Sponda B: ${actors_river_bank_b[@]}"
    echo "Cosa vuoi fare?"
    echo "1) Spostare un attore sulla sponda A"
    echo "2) Spostare un attore sulla sponda B"
    echo "3) Esci dal gioco"
    read -r choice
    echo "----------------------------------------------------------"
    case $choice in
        1)
            if [[ "$farmer_position" == "b" ]]; then
                move_to_river_bank_a
            else
                echo "Non puoi spostare un attore sulla sponda A se il contadino non è sulla sponda B."
            fi
            ;;
        2)
            if [[ "$farmer_position" == "a" ]]; then
                move_to_river_bank_b
            else
                echo "Non puoi spostare un attore sulla sponda B se il contadino non è sulla sponda A."
            fi
            ;;
        3)
            game_running=false
            ;;
        *)
            echo "Scelta non valida, riprova."
            ;;
    esac

done

exit 0