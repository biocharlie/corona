#!/bin/sh
#---------------------------------------------------------
# Coronavirus data script
# Data source: https://github.com/NovelCOVID/API
# News source: https://github.com/sagarkarira/coronavirus-tracker-cli
# Author: Carlos Milan
# Last update: 03/26/2020
# --------------------------------------------------------

#Input states as parameters to the scrip or have them presets
#If no parameters, use to presets
if [ "$#" -eq 0 ]
then
	StateArray=("Wisconsin" "Puerto Rico" )
else
	StateArray=( "$@" )
fi


read -p 'Download/Update data? [Y/N]: ' answer
if [ $answer == y ]
then
	echo "Downloading/Updating data..."
	curl -s https://corona.lmao.ninja/all                   > global-data
	curl -s https://corona.lmao.ninja/countries/us          > us-data
	curl -s https://corona.lmao.ninja/states                > state-data

	#Global data
	awk -F ',' '{print "Global," $1"," $2}' global-data |
        	sed 's/{//g ; s/"//g ; s/}//g' > output-data

	#US Total
	awk -F ',' '{print "US," $9"," $10"," $9"," $11}' us-data |
        	sed 's/"//g' >> output-data

	#States
	for StateElement in "${StateArray[@]}"
	do
		statename="$(cat state-data | tr ',' '\n' | grep -n "$StateElement" | cut -d : -f 1)"
		cases="$((statename+1))"
		todaycases="$((statename+2))"
		death="$((statename+3))"
		todaydeath="$((statename+4))"
		awk -F ',' '{print $'$statename' "," $'$cases' "," $'$death' "," $'$todaycases' "," $'$todaydeath'}' state-data |
        		sed '1,/:/s/:// ; s/\[//g  ; s/{//g ; s/state//g ; s/"//g ; s/}//g' >> output-data
	done

	echo -e "Location,Cases,Deaths,TodayCases,TodayDeaths\n$(cat output-data)" > output-data
	sed -i 's/cases://g ; s/deaths://g ; s/todayCases://g ; s/todayDeaths://g' output-data

	if grep -q html ./output-data
	then
		echo -e "\e[31mERROR:\e[0m Download/Update data unsuccessfull"
		echo "Run the program again and download/update data files"
		exit
	else
		echo "------------------------------------------------------------------------------"
		column -t -s $',' output-data
		echo "------------------------------------------------------------------------------"
	fi

elif [ ! -f ./output-data ]
then
	echo -e "\e[31mERROR:\e[0m NO DATA"
	echo "Run the program again and download data files"
	exit

elif grep -q html ./output-data
then
	echo -e "\e[31mERROR:\e[0m DATA CORRUPTED"
	echo "Run the program again and download data files"
	exit
else
	echo "------------------------------------------------------------------------------"
	column -t -s $',' output-data
	echo "------------------------------------------------------------------------------"
fi

read -p 'Lates News? [Y/N]: ' answer
if [ $answer == y ] 
then
	echo "Downloading news..."
	curl -s  https://corona-stats.online/updates > news-data
	cat news-data
	echo ""
else
	:
fi

