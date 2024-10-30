#!/usr/bin/env bash

wait_for_enter() {
  if [ "$AutoContinue" -eq 1 ]; then
    #echo -e "\nScript is set to continue automatically, not waiting for user input.\n"
    echo -e "\nOption, automatisch durchzulaufen, ist gesetzt. Ich fahre einfach fort ohne Benutzereingabe.\n"
  else
    read
  fi
}

initialize_arguments() {

  # Only use the first page of each assignment. Can be changed by setting NumberOfPagesPerAssignment variable (in bash)
  if ! ((NumberOfPagesPerAssignment>0)); then NumberOfPagesPerAssignment=1; fi
  if ((AutoContinue!=1)); then AutoContinue=0; fi
  if ((DontRequireCommands!=1)); then DontRequireCommands=0; fi
  # if ((AcceptMoreThanOneFile!=1)); then AcceptMoreThanOneFile=0; fi # not yet implemented, and perhaps never will be, since ILIAS already limits the number of files students can hand in.

}

print_script_info() {

  echo -e "\nilias-to-booklet-converter, Copyright (c) 2024 Fabian Stöhr, Universität Konstanz"
  echo -e "===================================================================================\n"
  echo -e "Dieses Skript erstellt aus Übungen, die über das ILIAS-LMS abgegeben wurden,\nBooklets, wie sie etwa für Klausuren eingesetzt werden können."
  echo -e "Dazu muss das Skript in einem Verzeichnis ausgeführt werden, dass\nvon ILIAS heruntergeladene .Zip-Dateien mit einzelnen Übungen enthält."
  echo -e "Die Zip-Dateien werden extrahiert, die Dateien umsortiert, und für jeden\nTeilnehmer ein einzelnes Pdf mit allen eingereichten Übungen erstellt."
  echo -e "Dabei wird aus jeder eingereichten Pdf-Datei nur die erste Seite berücksichtigt."
  echo -e "Die Reihenfolge der Seiten richtet sich nach den Namen\nder Übungen in ILIAS (alphabetisch sortiert)."
  echo ""

  echo -e "Außerdem werden Bilddateien, die auf .jpg, .jpeg, .png  oder .sec enden,\nin Pdfs konvertiert."
  echo -e "Die Seiten werden auf A5 skaliert und hochkant rotiert."

  # echo "Alternativ kann das Verzeichnis, in dem sich die .zip-Dateien befinden, auch als KommandozeilenArgument angegeben werden."
  # echo "Beispiel: $0 ./Pfad/zu/dem/Verzeichnis"
  # bzw. "nix run github-link -- ./Pfad/zu/dem/Verzeichnis"

}

print_command_line_argument_help() {

  echo -e "\nKommandozeilenoptionen:\n-----------------------------\n"
  echo "-p, --pages-per-assignment number_of_pages"
  echo "                        Die Anzahl an Seiten, die maximal von jeder eingereichten Datei ins Booklet übernommen werden sollen. (Voreingestellt: number_of_pages=1)."
  echo "-a, --auto-continue:"
  echo "                        Skript pausiert nicht, sondern läuft komplett durch."
  echo "--no-auto-continue:"
  echo "                        Skript pausiert an einigen Stellen, damit manuel Änderungen an den Dateien vorgenommen werden, falls erwünscht. (Voreingestellt)"
  echo "--no-check-commands:"
  echo "                        Skript fährt auch dann fort, wenn nicht alle benötigten Programme installiert sind. Das führt in der Regel zu Fehlern."
  echo "--check-commands:"
  echo "                        Skript bricht ab, wenn nicht alle benötigten Programme installiert sind. (Voreingestellt)"
  echo "-h, --help:"
  echo "                        Diese Hilfe."

}


create_target_directories() {

  echo -e "Erstelle Verzeichnisse.\n"
  mkdir VonIlias
  mkdir Sorted
  mkdir IndividualRotated
  mkdir A5FinalPages
  mkdir FinalBooklets
}

exit_if_commands_not_installed() {
  if [ "$commands_not_installed" -eq 1 ]; then
    if ((DontRequireCommands!=1)); then
      #echo -e "\nSome required commands are not installed. Exiting."
      echo -e "\nEinige benötigte Befehle sind nicht installiert. Breche ab."
      exit 1
    else
      #echo -e "\nTrying to continue even though some required commands are not installed.\n"
      echo -e "\nIch versuche fortzufahren, obwohl einige benötigte Befehle nicht installiert sind.\n"
    fi
  fi
}

check_for_required_commands() {

  # use magick if it is installed (ImageMagick7+), but convert if it isn't (ImageMagick6-)
  if command -v magick > /dev/null 2>&1; then
	  #echo "ImageMagick 7+ found, using the \"magick\" command."
	  #echo "ImageMagick 7+ wurde gefunden, benutze den \"magick\"-Befehl."
	  MAGICKCOMMAND="magick"
  else
	  if command -v convert > /dev/null 2>&1; then
		  #echo "ImageMagick 6- found, using the \"convert\" command."
		  #echo "ImageMagick 6- wurde gefunden, benutze den \"convert\"-Befehl."
		  MAGICKCOMMAND="convert"
	  else
		  # echo "ImageMagick not found! Exiting."
		  #echo "Please install ImageMagick!"
		  echo "ImageMagick wurde nicht gefunden!"
		  echo "Bitte installieren Sie ImageMagick!"
		  commands_not_installed=1;
	  fi
  fi

  # List of additional commands to check
  usedcommands=("ls" "gs" "pdfinfo" "7z" "pdftk" "find" "bc" "sed" "cp" "mv" "file" "tee")

  # Check for each command this script needs
  commands_not_installed=0
  for cmd in "${usedcommands[@]}"; do
      if ! command -v "$cmd" &> /dev/null; then
	  #echo "Error: $cmd is not installed or not in your PATH."
	  echo "Fehler: $cmd ist nicht installiert oder nicht im PATH."
	  echo "Bitte installieren Sie $cmd!"
	  commands_not_installed=1;
      fi
  done

}


#### MAIN ####

run_in_dir=""

#### PARSING COMMAND LINE ARGUMENTS ####

while [[ $# -gt 0 ]]; do
  case $1 in
    -p|--pages-per-assignment)
      NumberOfPagesPerAssignment="$2" # if non-number entered, is set to 1.
      shift
      shift
      ;;
    -a|--auto-continue)
      AutoContinue=1
      shift
      ;;
    --no-auto-continue)
      AutoContinue=0
      shift
      ;;
    --no-check-commands)
      DontRequireCommands=1
      shift
      ;;
    --check-commands)
      DontRequireCommands=0
      shift
      ;;
    -h|--help)
      print_script_info
      echo ""
      print_command_line_argument_help
      exit 0
      ;;
    -*|--*)
      echo "Unbekannte Option: $1"
      exit 1
      ;;
    *)
      run_in_dir="$1"
      shift
      ;;
  esac
done

initialize_arguments # Initialize arguments if not explicitly set by command line arguments

check_for_required_commands

exit_if_commands_not_installed



print_script_info

if [[ "$run_in_dir" != "" ]]; then
  if [ -d "$run_in_dir" ]; then
    cd "$run_in_dir"
  else
    echo "Fehler: Verzeichnis $run_in_dir existiert nicht!"
    echo "Ich breche ab!"
    #echo "Directory $run_in_dir does not exist!"
    #echo "Exiting..."
    exit 1
  fi
fi


echo -e "Bitte fahren Sie nur fort, wenn das aktuelle (oder per Kommandozeilenoption ausgewählte) Verzeichnis\ndie aus ILIAS exportierten Zip-Dateien enthält."
echo ""
echo -e " \nDrücken Sie <Enter>, um vortzufahren, oder <Strg-c>, um abzubrechen.\n"
wait_for_enter

if [ -d VonIlias ] || [ -d Sorted ] || [ -d IndividualRotated ] || [ -d A5FinalPages ] || [ -d FinalBooklets ]; then
	echo "Es sieht so aus, als wurde das Skript schon einmal in diesem Verzeichnis ausgeführt."
	echo "Wenn Sie das Skript noch mal ausführen möchten, löschen Sie bitte zuerst"
	echo "alle Dateien in diesem Verzeichnis, die bei den letzten Durchläufen erstellt wurden."
	echo "Das sind die Ordner \"VonIlias\", \"Sorted\", \"IndividualRotated\", \"A5FinalPages\", \"FinalBooklets\"."
	exit 1
fi

create_target_directories

basedir=`pwd`
cd VonIlias

if ls ../*.zip 1> /dev/null 2>&1; then
  echo -e  "\nExtrahiere Archive"
  echo
  for i in ../*.zip; do 7z -bb0 x "$i"; done
else
  echo -e "\nKeine Zip-Archive gefunden.\n"
  echo -e "Soll ich stattdessen alle Unterordner in diesem Ordner verwenden?"
  echo -e "Dies ist dann sinnvoll, wenn diese Unterordner aus den entsprechenden, von ILIAS"
  echo -e "generierten Zip-Dateien extrahiert sind. Unter MacOS geschieht das manchmal automatisch.\n"

  echo -e "\n------------------------------------------"
  echo -e "Das betrifft die folgenden Ordner:\n"
  #shopt -s extglob # Enable extended globbing to make ls ignore files we've created ourselves
  # ls -d ../*/ ! (*VonIlias|*Sorted|*IndividualRotated|*A5FinalPages|*FinalBooklets)
  ls -d ../*/ | cut -c 4- | grep -vE "(VonIlias|Sorted|IndividualRotated|A5FinalPages|FinalBooklets)"
  echo -e "------------------------------------------"

  echo -e " \nDrücken Sie <Enter>, um vortzufahren, oder <Strg-c>, um abzubrechen.\n"
  wait_for_enter
  for dir in ../*/; do
    if [ -d "$dir" ]; then
      case "$(basename "$dir")" in 
	VonIlias|Sorted|IndividualRotated|A5FinalPages|FinalBooklets)
	  # do nothing
	;;
      *)
	cp -R "$dir" ./
      esac
    fi
  done
fi

echo -e "\n \n \n"

echo -e "=============================================================================\n"

echo "Im Verzeichnis \"VonIlias\" finden Sie jetzt die extrahierten Dateien der Übungen."
echo "Die Einzelnen Übungen erscheinen in der Reihenfolge im Booklet, in der die Ordner in"
echo "diesem Verzeichnis erscheinen, alphabetisch sortiert."
echo ""
echo "Falls Sie die Reihenfolge manuell ändern möchten, können Sie das jetzt tun, indem"
echo "Sie die Unterordner im Verzeichnis \"VonIlias\" jetzt vor dem nächsten Schitt"
echo "noch umbenennen."
echo -e "\n<Enter> drücken, um mit dem nächsten Schritt fortzufahren!\n"
wait_for_enter

echo -e "\n \n"

echo -e "=============================================================================\n\n"

echo "Ich versuche gleich, alle Dateien, die keine Pdfs sind, in Pdfs zu konvertieren."
echo "Dieses Skript konvertert .jpg, .jpeg-, png- und .sec-Dateien automatisch."
echo "Dazu müssen die Dateien auch die entsprechenden Endungen haben!"
echo -e "Andere Dateien müssen manuell konvertiert werden.\n"

echo -e "-----------------------------------------------------------------------------\n"
echo "Ich suche jetzt Dateien, die eine falsche Dateiendung haben, aber Pdfs sind und automatisch konvertiert werden können. Diese Dateien werden zunächst umbenannt."
echo
find ./ -type f -ipath "*/Abgaben/*" -not -iname "*.pdf" -and -not -iname "*.jpg" -and -not -iname "*.jpeg" -and -not -iname "*.sec" -and -not -iname "*.png" | while read -r currentfile; do
  filetype=$(file --mime-type -b "$currentfile")
  case "$filetype" in
    application/pdf)
      echo -e "Benenne um:\n$currentfile\nzu\n$currentfile.pdf\n"
      mv -n "$currentfile" "$currentfile.pdf"
      ;;
    image/jpeg)
      echo "Benenne um:\n$currentfile\nzu\n$currentfile.jpg\n"
      mv -n "$currentfile" "$currentfile.jpg"
      ;;
    image/png)
      echo "Benenne um:\n$currentfile\nzu\n$currentfile.png\n"
      mv -n "$currentfile" "$curretfile.png"
      ;;
    esac
done


echo -e "\n\n-----------------------------------------------------------------------------"
echo "Ich suche jetzt Dateien, die keine Pdfs sind und die nicht automatisch konvertiert werden können:"
echo ""

files_i_cant_convert=$(find ./ -type f -ipath "*/Abgaben/*" -not -iname "*.pdf" -and -not -iname "*.jpg" -and -not -iname "*.jpeg" -and -not -iname "*.sec" -and -not -iname "*.png" | tee /dev/tty)

if [ -z $files_i_cant_convert ]
  then
    echo -e "Keine nicht-konvertierbaren Dateien gefunden! :-)"
  else
    echo -e "-----------------------------------------------------------------------------\n"
    echo -e "\n"
    echo "Dieses Skript kann nur mit .pdf, .jpg, .jpeg-, png- und .sec-Dateien umgehen."
    echo "Falls andere Dateien dabei sind, die Sie ebenfalls in das Pdf-Booklet integrieren möchten,"
    echo "bitte jetzt entsprechend manuell in .pdf-Dateien konvertieren, bevor Sie fortfahren."
fi
echo -e "\n<Enter> drücken, um fortzufahren!\n"
wait_for_enter
echo "Ich fahre fort und konvertiere alle jpg-, jpeg-, png- und sec-Bilder:"


echo -e "\nBeginne mit der Konvertierung der Bilder, das kann eine Weile dauern....\n"


find ./ -type f -iname "*.jpg" | while ISF= read -r i; do ${MAGICKCOMMAND} "$i" "${i%.jpg}".pdf; done
find ./ -type f -iname "*.jpeg" | while ISF= read -r i; do ${MAGICKCOMMAND} "$i" "${i%.jpeg}".pdf; done
find ./ -type f -iname "*.sec" | while ISF= read -r i; do ${MAGICKCOMMAND} "$i" "${i%.sec}".pdf; done
find ./ -type f -iname "*.png" | while ISF= read -r i; do ${MAGICKCOMMAND} "$i" "${i%.png}".pdf; done
echo -e "\nFertig!\n \n"
echo "Sortiere Dateien nach Nutzern, Ergebnisse dann im Ordner \"Sorted\":"
echo
export n=1;
for f in *; do pushd "$f/Abgaben/" > /dev/null; for i in *; do mkdir -p "../../../Sorted/$i"; cp -i "$i"/*.pdf "../../../Sorted/$i/"`printf '%02d' $n`.pdf; done; popd > /dev/null; (( n += 1 )); #echo $n; 
done
echo -e "\nFertig!\n"
echo -e "=============================================================================\n"
echo "Extrahiere von jedem Dokument nur die erste Seite, und rotiere sie wenn nötig:"
echo "Die Ergebnisse kommen in den Ordner \"IndividualRotated\"."
# echo "Evtl. werden gleich viele Warnungen über null-bytes angezeigt. Sie können ignoriert werden."
# echo "(Diese Warnungen erscheinen u.A., wenn die Metadaten eines Pdfs keinen Titel enthalten.)"
echo
cd "$basedir/Sorted"
for f in *; do mkdir -p ../IndividualRotated/"$f"; pushd "$f" > /dev/null; 
	#echo "Rotating Student: $f"
	for i in *.pdf; do 
		pdfinfooutput=$(pdfinfo "$i"|tr -d '\0') # removing \0s with tr to avoid constant warnings about ignoring null bytes.
		page_width=$(echo "$pdfinfooutput" | sed -n 's/^Page size:[[:space:]]*\([0-9.]*\) x [0-9.]* pts.*/\1/p')
		page_height=$(echo "$pdfinfooutput" | sed -n 's/^Page size:[[:space:]]*[0-9.]* x \([0-9.]*\) pts.*/\1/p')
		page_rot=$(echo "$pdfinfooutput" | sed -n 's/^Page rot:[[:space:]]*\([0-9]*\)$/\1/p')
		if [[ "$page_rot" -eq 90 || "$page_rot" -eq 270 ]]; then PdfWidth=$page_height; PdfHeight=$page_width; else PdfWidth=$page_width; PdfHeight=$page_height; fi
		# to compare height and width, we need to use bc rather than bash, because
		# bash can only handle integers...
		HeightGreaterEqWidth=$((`echo "$PdfHeight >= $PdfWidth"| bc`))
		NumberOfPagesThisFile=$NumberOfPagesPerAssignment;
		if [ $HeightGreaterEqWidth -eq 1 ]; then 
			while ! pdftk "$i" cat 1-$NumberOfPagesThisFile output ../../IndividualRotated/"$f"/"$i"; do echo "$i by $f: Document has less than $NumberOfPagesThisFile pages. Trying again with $((NumberOfPagesThisFile-1)) pages"; NumberOfPagesThisFile=$((NumberOfPagesThisFile-1)); if ! ((NumberOfPagesThisFile>0)); then break; fi; done
		else 
			while ! pdftk "$i" cat 1-${NumberOfPagesPerAssignment}left output ../../IndividualRotated/"$f"/"$i"; do echo "$i by $f: Document has less than $NumberOfPagesPerAssignment pages. Trying again with $((NumberOfPagesPerAssignment-1)) pages"; NumberOfPagesPerAssignment=$((NumberOfPagesPerAssignment-1)); if ! ((NumberOfPagesPerAssignment>0)); then break; fi; done
		fi; 
	done; 
	popd > /dev/null;
done
# echo -e "\n(Evtl. wurden gerade viele Warnungen über null-bytes angezeigt. Sie können ignoriert werden.)\n"
echo -e "\nFertig!\n\n\n"

echo -e "=============================================================================\n"
echo "Konvertiere Alle Seiten auf A5-Format. Die Ergebnisse kommen in den Ordner \"A5FinalPages\""
cd "$basedir/IndividualRotated"
for f in *; do mkdir -p ../A5FinalPages/"$f"; pushd "$f" > /dev/null; for i in *.pdf; do gs -q -o  ../../A5FinalPages/"$f"/"$i" -sDEVICE=pdfwrite -dDEVICEWIDTHPOINTS=421 -dDEVICEHEIGHTPOINTS=595 -dAutoRotatePages=/None -dPDFFitPage -dBATCH -dSAFER "$i"; done; popd > /dev/null; done
# for f in *; do mkdir ../A5FinalPages/$f; pushd $f; for i in *.pdf; do gs -o  ../../A5FinalPages/$f/$i -sDEVICE=pdfwrite -dDEVICEWIDTHPOINTS=421 -dDEVICEHEIGHTPOINTS=595 -dFIXEDMEDIA -dAutoRotatePages=/None -dPDFFitPage -dBATCH -dSAFER $i; done; popd; done
echo -e "\nFertig!\n\n"
echo "Füge die einzelnen Seiten zusammen. Die Ergebnisse kommen in den Ordner \"FinalBooklets\""
echo
cd "$basedir/A5FinalPages"
for d in *; do pdftk "$d"/*.pdf cat output ../FinalBooklets/"$d".pdf; done
echo -e "FERTIG!\n"
echo -e "Die Ergebnisse finden Sie im Ordner \"FinalBooklets\"."
