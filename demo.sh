#!/bin/bash

mapfile -t mapa < sala1.txt
player="■"
px=5
py=6
sala="sala1.txt"
inven=()
vida=15
mvida=15
declare -A rmsv
dx=0
dy=1
limsg=$(( ${#mapa[@]} + 2 ))

tput civis
stty -echo
trap "stty -echo; tput cnorm; clear; exit" INT TERM EXIT

inl() {
        case "$sala:$1,$2" in
                "sala1.txt:10,2") echo "Papel" ;;
                "sala1.txt:14,7") echo "Chave" ;;
                "sala1.txt:31,3") echo "Machado" ;;
                "sala2.txt:27,4")  echo "Pedra estranha" ;;
                "sala3.txt:21,4") echo "Fim" ;;
                *) echo "" ;;
        esac
}


drawin(){

        local lin=$((${#mapa[@]} + 3))
        for i in {0..4}; do
                tput cup $((lin + i)) 0
                printf "%-25s" "$((i + 1)). ${inven[$i]}"
        done
}

dvida(){

        local lin=$(( ${#mapa[@]} + 9 ))
        local barra=""

        for (( i=1; i<=mvida; i++ )); do
                if (( i<=vida )); then
                        barra+="♡"
                else
                        barra+="!"
                fi
        done

        tput cup $lin 0
        printf "HP: [%s] %d/%d   " "$barra" "$vida" "$mvida"
}

morte() {

        if (( vida <= 0 )); then
                mudar "death.txt" 9 8
                msg "Eu devia fazer uma conquista para algo tão estúpido"
        fi
}

mudar() {

        rmsv["$sala"]=$(printf "%s\n" "${mapa[@]}")

        sala="$1"

        if [[ -n "${rmsv[$sala]}" ]]; then
                mapfile -t mapa <<< "${rmsv[$sala]}"
        else
                mapfile -t mapa < "$sala"
        fi

        px=$2
        py=$3
        limsg=$(( ${#mapa[@]} + 2 ))

        clear
        printf "%s\n" "${mapa[@]}"
        echo ""
        printf "[Setas] Mover|[Q] Sair|[E] Interagir|[1-5] Usar item"
        drawin
        dvida
}

tra() {
        local max_y=$(( ${#mapa[@]} - 1 ))
        local max_x=$(( ${#mapa[$2]} - 1 ))

        if (( $1 == 0 || $1 == max_x || $2 == 0 || $2 == max_y )); then
                return 0
        else
                return 1
        fi
}

menu() {

        local menu
        mapfile -t menu < "menu.txt"

        clear
        printf "%s\n" "${menu[@]}"

        while true; do
                read -rsn1 tela
                if [[ "$tela" == "r" || "$tela" == "R" ]]; then
                        break
                fi
        done

        clear
        printf "%s\n" "${mapa[@]}"
        echo ""
        printf "[R] Menu"
        drawin
        dvida

}

dash() {

local ox=$px
local oy=$py

        for i in {1..3}; do
                local nex=$((px + dx))
                local ney=$((py + dy))
                local dest="${mapa[$ney]:$nex:1}"

                case "$dest" in
                        "!")
                                if [[ $i -eq 3 ]]; then
                                        tput cup $py $px
                                        echo -n "${mapa[$py]:$px:1}"
                                        px=$ox
                                        py=$oy
                                        ((vida -= 3))
                                        (( vida < 0 )) && vida=0
                                        dvida
                                        msg "Errou"
                                        morte
                                        return
                                fi
                                ;;

                        "#")
                                [[ $i -eq 3 ]] && break ;;

                        "@"|":"|"?"|"◇"|"×"|"□"|"|"|"_"|"—"|"/")
                                break ;;
                        ".")
                                case "$sala:$nex,$ney" in
                                        "sala1.txt:40,4") mudar "sala2.txt" 1 4; return ;;
                                        "sala2.txt:0,4")  mudar "sala1.txt" 39 4; return ;;
                                        "sala1.txt:6,0") mudar "sala3.txt" 6 7; return ;;
                                        "sala3.txt:6,8") mudar "sala1.txt" 6 1; return ;;
                                        "sala3.txt:2,0") mudar "sala4.txt" 2 3; return ;;
                                        "sala4.txt:2,4") mudar "sala3.txt" 2 1; return ;;
                                        "sala3.txt:39,0") mudar "sala4.txt" 39 3; return ;;
                                        "sala4.txt:39,4") mudar "sala3.txt" 39 1; return ;;
                                        "death.txt:6,13") exit 0 ;;
                                        "death.txt:19,6") vida=$mvida; mudar "sala1.txt" 6 2; return ;;
                                esac
                                ;;
                esac

                tput cup $py $px
                echo -n "${mapa[$py]:$px:1}"
                px=$nex
                py=$ney
        done
}


msg() {
    tput cup $limsg 0
    printf "%-40s" "$1"
}

apagar() {
    mapa[$2]="${mapa[$2]:0:$1}${3:- }${mapa[$2]:$1+1}"
    tput cup $2 $1
}

quebrar() {
        for (( y=0; y<${#mapa[@]}; y++ )); do
                for (( x=0; x<${#mapa[$y]}; x++ )); do
                        if [[ "${mapa[$y]:$x:1}" == ":" ]]; then
                                apagar $x $y " "
                                printf " "
                        fi
                done
        done
}


interagir() {

        local vx=$((px+dx))
        local vy=$((py+dy))
        local alvo="${mapa[$vy]:vx:1}"

        msg

        case "$alvo" in

                "◇")
                        local item
                        item=$(inl $vx $vy)
                        if [[ -n "$item" ]]; then
                                inven+=("$item")
                                drawin
                                apagar $vx $vy
                                printf " "
                                msg "Você pegou $item"
                        fi
                        ;;
                "□")
                        local item
                        item=$(inl $vx $vy)
                        if [[ -n "$item" ]]; then
                                inven+=("$item")
                                drawin
                                apagar $vx $vy "×"
                                printf "×"
                                msg "Você abriu um baú e achou: $item"
                        else
                                msg "baú está vazio"
                        fi
                        ;;
                "?")
                        quebrar
                        msg "Você ouvi algo quebrando"
                        ;;
                "×")
                        msg "o baú está vazio"
                        ;;
                "/")
                        msg "está trancado"
                        ;;
        esac
}

usar() {
    local idx=$(($1 - 1))
    local item="${inven[$idx]}"
    [[ -z "$item" ]] && msg " " && return

    local vx=$((px + dx))
    local vy=$((py + dy))
    local alvo="${mapa[$vy]:$vx:1}"

    case "$item" in
        "Chave")
            if [[ "$alvo" == "/" ]]; then
                if tra $vx $vy; then
                    apagar $vx $vy "."
                    printf "."
                else
                    apagar $vx $vy
                    printf " "
                fi
                unset 'inven[$idx]'
                drawin
                msg "Você ouvi um som depois de virar a chave"
            else
                msg "Você tentou encaixar a chave no ar."
            fi ;;

        "Machado")
            case "$alvo" in
                "/")
                    if tra $vx $vy; then
                        apagar $vx $vy "."
                        printf "."
                    else
                        apagar $vx $vy
                        printf " "
                    fi
                    msg "você quebrou a porta" ;;
                "□"|"×")
                    apagar $vx $vy
                    printf " "
                    msg "Você quebrou o baú" ;;
                *)
                    msg "Você é idiota?." ;;
            esac ;;

        "Papel")
            unset 'inven[$idx]'
            drawin
            msg "Está escrito: 'com o F algumas paredes se tornam ar'" ;;

        "Pedra estranha")
                if [[ "$alvo" == "@" ]]; then
                        apagar $vx $vy "."
                        printf "."
                        unset 'inven[$idx]'
                        drawin
                else
                        msg "está pedra tem um formato perculiar"
                fi
            ;;

        "Fim")
                msg "Obrigado por jogar S2"
    esac
}

clear
printf "%s\n" "${mapa[@]}"
echo " "
printf "[R] Menu"
drawin
dvida

while true;
do

        tput cup $py $px
        echo -n "$player"

        read -rsn1 tecla

        if [[ "$tecla" == $'\e' ]]; then
                read -rsn2 -t 0.05 resto
                tecla+="$resto"
        fi

        newx=$px
        newy=$py

        case "$tecla" in
                w|W|$'\e[A'|$'\eOA') ((newy--)); dx=0; dy=-1 ;;
                s|S|$'\e[B'|$'\eOB') ((newy++)); dx=0; dy=1 ;;
                d|D|$'\e[C'|$'\eOC') ((newx++)); dx=1; dy=0 ;;
                a|A|$'\e[D'|$'\eOD') ((newx--)); dx=-1; dy=0 ;;
                e|E) interagir; continue ;;
                f|F) dash; continue;;
                r|R) menu; continue;;
                1|2|3|4|5) usar "$tecla"; continue ;;
                .) break ;;
                *) continue ;;
        esac

        destino="${mapa[$newy]:$newx:1}"

        case "$destino" in
                "!")
                        ((vida -= 3))
                        (( vida < 0 )) && vida=0
                        dvida
                        msg "Cuidado com o buraco"
                        morte
                        ;;

                ".")
                        case "$sala:$newx,$newy" in
                        "sala1.txt:40,4")
                                mudar "sala2.txt" 1 4
                                continue;;
                        "sala2.txt:0,4")
                                mudar "sala1.txt" 39 4
                                continue;;
                        "sala1.txt:6,0")
                                mudar "sala3.txt" 6 7
                                continue;;
                        "sala3.txt:6,8")
                                mudar "sala1.txt" 6 1
                                continue;;
                        "sala3.txt:2,0")
                                mudar "sala4.txt" 2 3
                                continue;;
                        "sala3.txt:39,0")
                                mudar "sala4.txt" 39 3
                                continue;;
                        "sala4.txt:39,4")
                                mudar "sala3.txt" 39 1
                                continue;;
                        "sala4.txt:2,4")
                                mudar "sala3.txt" 2 1
                                continue;;
                        "death.txt:6,13")
                                break;;
                        "death.txt:19,6")
                                vida=$mvida
                                mudar "sala1.txt" 6 2
                                msg "Ih lá vamos nós!"
                                continue;;
                        esac
                        ;;

                "@"|":"|"?"|"#"|"◇"|"×"|"□"|"|"|"_"|"—"|"/") ;;

                *)
                        tput cup $py $px
                        echo -n "${mapa[$py]:$px:1}"
                        px=$newx
                        py=$newy
        esac
done
