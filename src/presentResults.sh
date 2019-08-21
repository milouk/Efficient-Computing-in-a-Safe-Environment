#!/bin/bash

DIR_RESULTS=$1
rm -rf ${DIR_RESULTS}/final_form
mkdir -p ${DIR_RESULTS}/final_form
touch ${DIR_RESULTS}/final_form/energy_log_base_10.txt
touch ${DIR_RESULTS}/final_form/performance_log_base_10.txt
touch ${DIR_RESULTS}/final_form/energy_raw.txt
touch ${DIR_RESULTS}/final_form/performance_raw.txt


energy_cocktail_raw=""
performance_cocktail_raw=""
energy_cocktail_log=""
performance_cocktail_log=""

energy_first="true"
performance_first="true"

flag_get_names="false"

for i in `ls ${DIR_RESULTS}`; do

	if [ "${flag_get_names}" == "false" ]; then
		flag_get_names="true"
		getNames=$(ls ${DIR_RESULTS}/$i | grep performance* | awk -F"." '{print $1}' | sed 's/performance_//' | tr "\n" ":")

		echo ${getNames} >> ${DIR_RESULTS}/final_form/energy_log_base_10.txt
		echo ${getNames} >> ${DIR_RESULTS}/final_form/performance_log_base_10.txt
		echo ${getNames} >> ${DIR_RESULTS}/final_form/energy_raw.txt
		echo ${getNames} >> ${DIR_RESULTS}/final_form/performance_raw.txt
	fi

	if [ "$i" != "final_form" ]; then
		for j in `ls ${DIR_RESULTS}/$i`; do
			case $j in
				energy*)
					if [ "$j" != "energy_https.txt" -a "$j" != "energy_http.txt" ]; then
						ENERGY=0
						while IFS= read -r var; do
							ENERGY=$(echo ${ENERGY} + $var | bc)
						done < "$DIR_RESULTS/$i/$j"
						TEST=$(echo $j | awk -F"." '{print $1}' | awk -F"_" '{$1=""; print $0}' | sed 's/\ /_/g' | sed 's/_//1')
						if [ ${energy_first} == "true" ]; then
							energy_first="false"
							energy_cocktail_raw=${ENERGY}
							ENERGY=$(echo 'scale=2; l('${ENERGY}')/l(10)' | bc -l)
							energy_cocktail_log=${ENERGY}
						else
							energy_cocktail_raw=${energy_cocktail_raw}":"${ENERGY}
							ENERGY=$(echo 'scale=2; l('${ENERGY}')/l(10)' | bc -l)
							energy_cocktail_log=${energy_cocktail_log}":"${ENERGY}
						fi
					fi
					;;
				performance*)
					MINUTES=0
					SECONDS=0
					getReal=$(cat ${DIR_RESULTS}/$i/$j | grep "real" | tail -1)

					if [ "$getReal" != "" ]; then
						MINUTES=$( echo $getReal |awk '{print $2}' | awk -F "." '{print $1}' | awk -F "m" '{print $1}')
						SECONDS=$( echo $getReal | awk '{print $2}' | awk -F "." '{print $1}' | awk -F "m" '{print $2}')
					fi	

					TIME=0
					if [ ${MINUTES} -ne 0 ]; then
						TIME=$(((MINUTES * 60) + SECONDS))
					else
						TIME=${SECONDS}
					fi
					TEST=$(echo $j | awk -F"." '{print $1}' | awk -F"_" '{$1=""; print $0}' | sed 's/\ /_/g' | sed 's/_//1')
					#echo "$TEST:$TIME" >> ${DIR_RESULTS}/$i/final_form/performance.txt
					if [ ${performance_first} == "true" ]; then
						performance_first="false"
						performance_cocktail_raw=${TIME}
						TIME=$(echo 'scale=2; l('${TIME}')/l(10)' | bc -l)
						performance_cocktail_log=${TIME}
					else
						performance_cocktail_raw=${performance_cocktail_raw}":"${TIME}
						TIME=$(echo 'scale=2; l('${TIME}')/l(10)' | bc -l)
						performance_cocktail_log=${performance_cocktail_log}":"${TIME}
					fi
					;;
			esac
		done
		echo ${performance_cocktail_raw} >> ${DIR_RESULTS}/final_form/performance_raw.txt
		echo ${energy_cocktail_raw} >> ${DIR_RESULTS}/final_form/energy_raw.txt
		echo ${performance_cocktail_log} >> ${DIR_RESULTS}/final_form/performance_log_base_10.txt
		echo ${energy_cocktail_log} >> ${DIR_RESULTS}/final_form/energy_log_base_10.txt
		performance_cocktail_log=""
		energy_cocktail_log=""
		performance_cocktail_raw=""
		energy_cocktail_raw=""
		energy_first="true"
		performance_first="true"
	fi
done

exit 0

