#!/bin/bash

function wyswietl_dane
{	#funkcja wyswietla dane w postaci tabelki
	if test $# -eq 7; then
		echo -e "\n***Monitorowanie wolnego miejsca na partycji /home/$USER***\n"
        	echo -e "|     Nazwa dysku   |\t" $1"\t|"
        	echo -e "|   Zajete Miejsce  |\t" $2"MB\t|\t"$3"%\t|"
        	echo -e "|   Wolne Miejsce   |\t" $4"MB\t|\t"$5"%\t|"
        	echo -e "| Wartosc Graniczna |\t" $6"MB\t|\t"$7"%\t|"
	else
		echo "za malo argumentow do wyswietlenia danych"
	fi
}

#kontrola bledow
if test $# -lt 1; then
	#sprawdzanie czy za mala ilosc podanych argumentow
	echo "Za mala ilosc argumentow. Wpisz: $0 [wartosc graniczna]"
	exit 1
elif test $# -ge  2; then
	#sprawdzanie czy za duza ilosc argumentow
	echo "Za duza ilosc argumentow. Wpisz: $0 [wartosc graniczna]"
	exit 2
elif [ $(expr match "$1" "[0-9]*") -eq 0 ]; then
	#sprawdzanie czy paramter to liczba naturalna
	echo "parametr musi byc liczba naturalna (wieksza lub rowna 5)"
        exit 3
elif test $1 -ge 100; then
	#sprawdzanie czy parametr mniejszy od 100
	echo "Wartosc musi byc mniejsza od 100"
	exit 4
elif test $1 -lt 5; then
	#sprawdzanie czy parametr wiekszy lub rowny 5
	echo "wartosc musi byc wieksza lub rowna 5"
	exit 5
fi

#petla w ktorej odbywa sie glowny program
while [ TRUE ]; do
	clear
	#zapis danych do zmiennych
	nazwaDysku=`df -h /home/$USER | grep / | awk '{print $1}'`
        zajeteMiejsce=`df -m /home/$USER | grep / | awk '{print $3}'`
        wolneMiejsce=`df -m /home/$USER | grep / | awk '{print $4}'`
        zajeteMiejsceP=`df -h | grep "^$nazwaDysku" | awk '{print $5}' | sed "s/%//"`
        wolneMiejsceP=$((100-$zajeteMiejsceP))
        wartoscGraniczna=$((($wolneMiejsce+$zajeteMiejsce)*$1/100))

	#wyswietlanie danych przy pomocy funkcji
	wyswietl_dane $nazwaDysku $zajeteMiejsce $zajeteMiejsceP $wolneMiejsce $wolneMiejsceP $wartoscGraniczna $1

	#sprawdzanie czy wartosc graniczna zostala przekroczona
	if [[ $wolneMiejsceP -lt $1 ]]; then
		echo -e "\n\t\e[31mWartosc graniczna zostala przekroczona\e[0m\n"
		echo -e "\tWybierz co chcesz zrobic:"
		echo -e "\t\t (1) czyszczenie partycji"
		echo -e "\t\t (2) zignorowanie"
		while [ TRUE ]; do
			echo -e "Wybor: "
			read wybor
			if [[ $wybor  -eq 1 ]]; then
				#czyszczenie partycji

				clear
				iloscPlikow=10
				wielkoscPlikowUsunietych=0

				#tablica wielkosci w bajtach, gdzie n jest wielkoscia
				n=0
				declare -a tablicaWielkosci

				#tablica sciezek, gdzie j to wielkosc tablicy
				j=0
				declare -a tablicaSciezek

				#tablica wyborow, gdzie i to wielkosc tablicy
				i=0
				declare -a tablicaWyborow

				zajeteMiejsceBajty=$((`df /home/$USER | grep / | awk '{print $3}'`*1000)) 
				wolneMiejsceBajty=$((`df /home/$USER | grep / | awk '{print $4}'`*1000))
				wartoscGranicznaBajty=$((($wolneMiejsceBajty+$zajeteMiejsceBajty)*$1/100))

				while [ TRUE ]; do
				#tworzenie pliku tymczasowego do wczytania wielkosci plikow
				touch tmp.txt
				find /home/$USER -writable \( ! -path "hdguard.sh" ! -path "*.bin" ! -path "*/." ! -path "./.cache*" -o -path "./.temp*" \) -type f -exec du -S -h -b -x {} + | sort -rh | head -$iloscPlikow | awk '{print $1}' >tmp.txt

				#wczytywanie tablicy wielkosci i odswiezanie jej dzieki licznikowi
				licznik=0
				while read LINE; do
					if [ $licznik -ge $(($iloscPlikow-10)) ]; then
						tablicaWielkosci[$n]=$LINE
						((n++))
					fi
					((licznik++))
				done < tmp.txt

				find /home/$USER -writable \( ! -path "hdguard.sh" ! -path "*.bin" ! -path "*/." ! -path "./.cache*" -o -path "./.temp*" \) 
				-type f -exec du -S -h -b -x {} + | sort -rh | head -$iloscPlikow | awk '{print $2}' > tmp.txt

				#wczytywanie tablicy sciezek oraz wyswietlanie obu tablic
				licznik2=0
				while read -r LINE; do
					if [ $licznik2 -ge $(($iloscPlikow-10)) ]; then
                                        	tablicaSciezek[$j]=$LINE
                                        	((j++))
					fi
					((licznik2++))
                                done < tmp.txt
				rm tmp.txt

				#wyswietlanie tablic
				echo -e "Wybierz pliki do usuniecia z listy:\n"
				echo -e "potrzebne do zwolnienia: "$(($wartoscGranicznaBajty-$wolneMiejsceBajty))
                                echo -e "Lp.\tWielkosc[b]\t Sciezka"

				for ((k=$iloscPlikow-10;k<$iloscPlikow;k++)); do
					echo -e "("$((++c))")\t"${tablicaWielkosci[$k]}"\t\t"${tablicaSciezek[$k]}
				done
				echo -e "(u)\tusuwanie wszystkich plikow z listy"
				echo -e "\nWpisz wybrana cyfre, a nastepnie kliknij enter, \njesli chcesz zakonczyc wybieranie plikow do usuniecia wcisnij 0"


				#zapisywanie wyboru
				while [ TRUE ]; do
					echo "Wybor: "
					read wybor

					#kontola bledow
					if [ $(expr match "$wybor" "[u]") -eq 1 ]; then
						#sprawdzanie czy wartosc nie zostala$
						for ((k=1;k<$iloscPlikow+1;k++)); do
						sprawdzanie=0
							for ((f=0;f<$i;f++)); do
								if [ $k -eq ${tablicaWyborow[$f]} ]; then
									((sprawdzanie++))
									break
								fi
							done
						if [ $sprawdzanie -eq 0 ]; then
						#dodawanie wartosci
							tablicaWyborow[$i]=$k
							((i++))
							echo "dodano ("$k")"
						fi
						done
					elif [ $(expr match "$wybor" "[0-9]*") -eq 0 ]; then
						echo "Parametr musi byc liczba naturalna z zakresu [0,"$iloscPlikow"]"
						echo "Sprobuj jeszcze raz: "
					elif [ $wybor -eq 0 ]; then
                                                break
					elif [ $wybor -gt $iloscPlikow ]; then
						echo "Parametr za duzy. Przedzial: [0," $iloscPlikow"]"
						echo "Sprobuj jeszcze raz: "
					else
						#sprawdzanie czy wartosc nie zostala juz podana
						sprawdzanie=0
						for ((k=0;k<$i;k++)); do
							if [ $wybor -eq ${tablicaWyborow[$k-1]} ]; then
								echo "Juz podales ten parametr"
								echo "Sprobuj jeszcze raz: "
								((sprawdzanie++))
								break
							fi
						done
						if [ $sprawdzanie -eq 0 ]; then
							#dodawanie wyboru do tablicy
							tablicaWyborow[$i]=$wybor
							((i++))
							echo "dodano"
						fi
					fi
				done

				#sprawdzanie czy osiagnieta odpowiednia wartosc
				suma=0
				for ((k=0;k<i;k++)); do
					((suma=suma+${tablicaWielkosci[${tablicaWyborow[$k]}-1]}))

				done
				if [ $(($wolneMiejsceBajty+$suma)) -ge $wartoscGranicznaBajty ]; then
					echo -e "\nosiagnieto odpowiednia wartosc\n"
					break
				else
					echo "Nieosiagnieto wartosci. Wybierz kolejne pliki"
				fi

				((iloscPlikow=iloscPlikow+10))
				done

				#tworzenie pliku z lista usunietych plikow
				plik=hdgurad_$(date +%F)_$(date +%H):$(date +%M).deleted
				touch $plik
				
				for ((k=0;k<j;k++)); do
					echo ${tablicaSciezek[$k]}>>$plik
				done
				clear
				echo -e "\tUtworzono plik:"$plik"\n"

				#usuwanie plikow
				for ((k=0;k<i;k++)); do
					rm -rf ${tablicaSciezek[${tablicaWyborow[$k]}]}
					sleep 1
					echo "usunieto: " ${tablicaSciezek[${tablicaWyborow[$k]}]}
				done

				sleep 1
				echo -e "\n\n\t\t\t \e[32mUsunieto wszystko\e[0m"
				sleep 2
				clear
				wyswietl_dane $nazwaDysku $zajeteMiejsce $zajeteMiejsceP $wolneMiejsce $wolneMiejsceP $wartoscGraniczna $1

				break
			elif [[ $wybor -eq 2 ]]; then
				#ignorowanie przekroczenia wartosci
				clear
				wyswietl_dane $nazwaDysku $zajeteMiejsce $zajeteMiejsceP $wolneMiejsce $wolneMiejsceP $wartoscGraniczna $1
				break
			else
				#podanie blednego wyboru
				echo "Zly wybor.Sprobuj jeszcze raz..."
				continue
			fi
		done
	fi
	sleep 60
done
