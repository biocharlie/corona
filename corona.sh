#!/bin/bash
#--------------------------------------------------------------------
# Coronavirus data script
# Data source: https://github.com/NovelCOVID/API
# Author: Carlos Milan
# Last update: 05/31/2020
# -------------------------------------------------------------------

#Input states as parameters to the scrip or have them presets
#If no parameters, use to presets
if [ "$#" -eq 0 ];
then
	StateArray=("Wisconsin" "Puerto Rico")
else
	StateArray=( "$@" )
fi


read -p 'Download/Update data? [Y/N]: ' answer
if [ $answer == y ]
then
	echo "Downloading/Updating data..."
	curl -s https://corona.lmao.ninja/v2/all                   > global-data
	curl -s https://corona.lmao.ninja/v2/countries/us          > us-data
	curl -s https://corona.lmao.ninja/v2/states                > state-data

	#Global data
	awk -F ',' '{print "Global," $2"," $4"," $3"," $5"," $11"," $1}' global-data |
        	sed 's/{//g ; s/"//g ; s/}//g' > output-data

	#US Total
	awk -F ',' '{print "US," $9"," $11"," $10"," $12"," $18"," $1}' us-data |
        	sed 's/{//g ; s/"//g' >> output-data

	#States
	for StateElement in "${StateArray[@]}"
	do
		statename="$(cat state-data | tr ',' '\n' | grep -n "$StateElement" | cut -d : -f 1)"
		cases="$((statename+2))"
		todaycases="$((statename+3))"
		death="$((statename+4))"
		todaydeath="$((statename+5))"
		tests="$((statename+9))"
		awk -F ',' '{print $'$statename' "," $'$cases' "," $'$death' "," $'$todaycases' "," $'$todaydeath' "," $'$tests'}' state-data |
        		sed '1,/:/s/:// ; s/\[//g  ; s/{//g ; s/state//g ; s/"//g ; s/}//g' >> output-data
	done

	#Updated date
	timeglobal=$(awk -F ',|:' 'NR==1{print $13}' output-data)
	timemillisecglobal=$(sed 's/.\{3\}$//' <<< "$timeglobal")
	timeformatedglobal=$(date -d '@'$timemillisecglobal)

	timeus=$(awk -F ',|:' 'NR==2{print $13}' output-data)
	timemillisecus=$(sed 's/.\{3\}$//' <<< "$timeus")
	timeformatedus=$(date -d '@'$timemillisecus)

	sed -i "s/$timeglobal/$timeformatedglobal/g ; s/$timeus/$timeformatedus/g" output-data #Add "" after -i to makeit work in older versions of sed (like MacOS)

	#Comment following two lines to validade data if source formating change
	echo -e "Location,Cases,Deaths,TodayCases,TodayDeaths,Tests,LastUpdated\n$(cat output-data)" > output-data
	sed -i 's/cases://g ; s/deaths://g ; s/todayCases://g ; s/todayDeaths://g ; s/updated://g ; s/tests://g' output-data #Add "" after -i to makeit work in older versions of sed (like MacOS)


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
