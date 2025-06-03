#!/bin/bash

clear_on_exit(){
        wait
        rm -rf ${temp_dir} 1>/dev/null 2>&1
        exit 1
}
trap clear_on_exit SIGINT

script_id=$$
wordlist=${1}

check_wordlist(){
        ! [[ -e "${wordlist}" ]] && echo "Especificar o arquivo de palavras. Exemplo: ${0} wordlist.txt" && exit 1 
        ! [[ -s "${wordlist}" ]] && echo "O arquivo ${wordlist} está vazio." && exit 1
        [[ $(< ${wordlist}) =~ [^a-z$'\n'] ]] && echo "Somente letra e/ou palavra em minúsculo" && exit 1
        while read -r length; do 
                (( ${#length} >= 30 )) && echo "A palavra ${length} ultrapassa o limite de caracteres." 
        done < ${wordlist} && exit 1
}
check_wordlist

words=()
while read -r word; do
        words+=("${word}")
        words+=("${word^}")
        words+=("${word^^}")
done < ${wordlist}

symbols=("!" "@" "#" "$" "%" "&" "*" "_" "-")
numbers=({0..9999})

evaluate_permutations(){
        first=$(( ${#words[@]} ))
        second=$(( ${#words[@]} * ${#numbers[@]} * 2 ))
        third=$(( ${#words[@]} * ${#symbols[@]} * 2 ))
        fourth=$(( ${#words[@]} * ${#numbers[@]} * ${#symbols[@]} * 6 ))
        fifth=$(( ${#words[@]} * ${#words[@]} - ${#words[@]} ))
        sixth=$(( ( ${#words[@]} * ${#words[@]} - ${#words[@]} ) * ${#numbers[@]} * 3 ))
        seventh=$(( ( ${#words[@]} * ${#words[@]} - ${#words[@]} ) * ${#symbols[@]} * 3 ))
        eight=$(( ( ${#words[@]} * ${#words[@]} - ${#words[@]} ) * ${#numbers[@]} * ${#symbols[@]} * 12 ))
        total=$(( first + second + third + fourth + fifth + sixth + seventh + eight ))
}
evaluate_permutations

output_file="${PWD}/wordlist.lst"
LC_NUMERIC=en_US.utf8 printf "Total de permutações e combinações: "%\'d\\n"" ${total}
printf "Arquivo de saída: ${output_file}\n"

max_procs=$(nproc)
printf "Quantos núcleos para a tarefa [1-${max_procs}]? "
read CPU
if (( ${CPU} <= ${max_procs} )) && (( ${CPU} >= 1 )); then
        max_procs=${CPU}
else
        printf "\nNúmero mínimo ou máximo de CPU excedido"
        exit 1
fi

count=4
update_progress(){
        count=$((count + 12 ))
        echo -ne "\rProgresso: [${count}%]" >&2
}

{
###########################
for word in ${words[@]}; do
        echo "${word}"
done
[[ $(declare -f update_progress) ]] && update_progress
#######################################
for word in ${words[@]}; do
        for number in ${numbers[@]}; do
                echo "${word}${number}"
                echo "${number}${word}"
        done
done
[[ $(declare -f update_progress) ]] && update_progress
#########################################
for word in ${words[@]}; do
        for symbol in "${symbols[@]}"; do
                echo "${word}${symbol}"
                echo "${symbol}${word}"
        done
done
[[ $(declare -f update_progress) ]] && update_progress
########################################################
for word in ${words[@]}; do
        for number in ${numbers[@]}; do
                for symbol in "${symbols[@]}"; do
                        echo "${word}${number}${symbol}"
                        echo "${word}${symbol}${number}"
                        echo "${number}${word}${symbol}"
                        echo "${number}${symbol}${word}"
                        echo "${symbol}${word}${number}"
                        echo "${symbol}${number}${word}"
                done
        done
done
[[ $(declare -f update_progress) ]] && update_progress
########################################################

######################################################
for word1 in ${words[@]}; do
        for word2 in ${words[@]}; do
                [[ ${word1} == ${word2} ]] && continue
                echo "${word1}${word2}"
        done
done
[[ $(declare -f update_progress) ]] && update_progress
##############################################################
for word1 in ${words[@]}; do
        for word2 in ${words[@]}; do
                for number in ${numbers[@]}; do
                        [[ ${word1} == ${word2} ]] && continue
                        echo "${word1}${word2}${number}"
                        echo "${number}${word1}${word2}"
                        echo "${word1}${number}${word2}"
                done
        done
done
[[ $(declare -f update_progress) ]] && update_progress
##############################################################
for word1 in ${words[@]}; do
        for word2 in ${words[@]}; do
                for symbol in "${symbols[@]}"; do
                        [[ ${word1} == ${word2} ]] && continue
                        echo "${word1}${word2}${symbol}"
                        echo "${symbol}${word1}${word2}"
                        echo "${word1}${symbol}${word2}"
                done
        done
done
[[ $(declare -f update_progress) ]] && update_progress
#########################################################################
temp_dir="${PWD}/wl_temp_${script_id}"
mkdir -p "${temp_dir}"

max_procs=${CPU}
i=0

for word1 in ${words[@]}; do
        (temp_out="${temp_dir}/part_${i}.tmp"
        for word2 in ${words[@]}; do
                for number in ${numbers[@]}; do
                        for symbol in "${symbols[@]}"; do
                                [[ ${word1} == ${word2} ]] && continue
                                echo "${word1}${word2}${number}${symbol}"
                                echo "${word1}${word2}${symbol}${number}"

                                echo "${word1}${symbol}${word2}${number}"
                                echo "${word1}${number}${word2}${symbol}"

                                echo "${word1}${symbol}${number}${word2}"
                                echo "${word1}${number}${symbol}${word2}"

                                echo "${symbol}${word1}${word2}${number}"
                                echo "${symbol}${word1}${number}${word2}"
                                echo "${symbol}${number}${word1}${word2}"

                                echo "${number}${word1}${word2}${symbol}"
                                echo "${number}${word1}${symbol}${word2}"
                                echo "${number}${symbol}${word1}${word2}"
                        done
                done
        done > "${temp_out}" ) &
        i=$(( i+1 ))
        (( i % max_procs == 0 )) && wait
done
wait
/usr/bin/cat ${temp_dir}/part_*.tmp
[[ $(declare -f update_progress) ]] && update_progress
} > "${output_file}"
#########################################################################
clear_on_exit
