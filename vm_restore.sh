#!/bin/bash

# Colors for terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
LIGHTGRAY='\033[0;37m'
GRAY='\033[0;90m'
LIGHTRED='\033[0;91m'
LIGHTGREEN='\033[0;92m'
LIGHTYELLOW='\033[0;93m'
LIGHTBLUE='\033[0;94m'
LIGHTMAGENTA='\033[0;95m'
LIGHTCYAN='\033[0;96m'
WHITE='\033[0;97m'

RESET='\033[0m'
BOLD='\033[1m'
FAINT='\033[2m'
ITALICS='\033[3m'
UNDERLINE='\033[4m'



# Backup folder
PATH_BACKUP_FOLDER="/mnt/user/backups/vm-backups"
PATH_BACKUP_FOLDER_LEN=`echo $PATH_BACKUP_FOLDER |awk '{print length}'`
PATH_BACKUP_FOLDER_LEN=$((PATH_BACKUP_FOLDER_LEN+2))

# VM folder
PATH_VM_FOLDER="/mnt/ssd/domains"

check_yes() {
	local _cont=$1

	while true; do
		read -r -p "Are You Sure? [Y/n] " input
		case $input in
		[yY][eE][sS] | [yY])
			eval $_cont=1
			break
			;;
		[nN][oO] | [nN])
			printf "Operation cancelled\n\n"
			eval $_cont=0
			break
			;;
		*)
			printf 'Invalid input...\n'
			;;
		esac
	done
}

print_separator() {
	read myrows mycols < <(stty size)
	printf "\n"
	for i in $(seq 1 $mycols); do
		printf "#"
	done
	printf "\n"
}

restore_backup() {
	clear
	print_separator
	printf "${RED}Make sure the informations is correct this script does not check errors.${RESET}\n\n"
	printf "${RED}Please check this before continuing.${RESET}\n" sur le dashboard
	printf "${RED}1) On the dashboard, delete your VM if it still exists ('Remove VM & Disks)'${RESET}\n"
	printf "${RED}2) Make sure all VMs are shut down'${RESET}\n"
	printf "${RED}3) Make sure your VMs Manager is turned ON before launching this operation.${RESET}\n"
	printf "${RED}   (settings => VM Manager => Enable VMs: Yes)${RESET}"
	print_separator
	printf "\n"

	printf "List of vm folders\n" 
	if [ -d $PATH_BACKUP_FOLDER ]; then
		for d in $PATH_BACKUP_FOLDER/*/ ; do
			if [[ $d != *"logs"* && $d != *"Unraid-VM-Backup-Plugin-Restoration-Script"* ]]; then
				DV=`echo "$d" | cut -c$PATH_BACKUP_FOLDER_LEN- | rev | cut -c2- | rev`
			    	printf "${CYAN}$DV ${RESET}\n"
				DV=""
			fi
		done
	fi

	print_separator
	printf "\n${BOLD}Enter name of virtual machine${RESET}\n\n"
	read -p "Name of vm folder: " VM_NAME
	PATH_BACKUP_VM_FOLDER=$PATH_BACKUP_FOLDER/$VM_NAME
	PATH_BACKUP_VM_FOLDER_LEN=`echo $PATH_BACKUP_VM_FOLDER |awk '{print length}'`
	PATH_BACKUP_VM_FOLDER_LEN=$((PATH_BACKUP_VM_FOLDER_LEN+1))

	print_separator
	printf "\nList of vdisk1 backups for $VM_NAME at $PATH_BACKUP_VM_FOLDER\n" 
	if [ -d $PATH_BACKUP_VM_FOLDER ]; then
		for d in $(ls -r $PATH_BACKUP_VM_FOLDER/*vdisk1.img*); do
			DV=`echo "${d:$PATH_BACKUP_VM_FOLDER_LEN:13}"`
		    	printf "${CYAN}$DV ${RESET}\n"
		done
	fi

	printf "\n${BOLD}Enter date of backup${RESET}\n\n"
	read -p "Date of backup: " BACKUP_DATE

	print_separator
	printf "\n${BOLD}Checking information :${RESET}\n"
	printf "Your backup path is: ${CYAN}$PATH_BACKUP_FOLDER${RESET}\n"
	printf "Your vm name is: ${GREEN}$VM_NAME${RESET}\n"
	printf "Your backup date is: ${YELLOW}$BACKUP_DATE${RESET}\n\n"

	for BACKUP_FILE in $(ls $PATH_BACKUP_FOLDER/$VM_NAME/${BACKUP_DATE}_vdisk*.img.*); do
		printf "Disk: $BACKUP_FILE\n"
	done
	printf "\n"
	check_yes result

	if [ $result == "0" ]; then
		echo "Stop"
		exit 1
	fi

	clear

	printf "\n"

	printf "${BOLD}Creation VM folder in domains directory${RESET}\n"
	printf "mkdir $PATH_VM_FOLDER/$VM_NAME\n\n"
	mkdir $PATH_VM_FOLDER/$VM_NAME > /dev/null 2>&1

	#20220627_0243_vdisk2.img.zst

	for BACKUP_FILE in $(ls $PATH_BACKUP_FOLDER/$VM_NAME/${BACKUP_DATE}_vdisk*.img.*); do

		VDISK_FILE=$(echo $BACKUP_FILE | cut -d '_' -f 3)
		VDISK_NAME=$(echo $VDISK_FILE | cut -d '.' -f 1)
		VDISK_EXT=$(echo $VDISK_FILE | cut -d '.' -f2)

		VDISK_FILENAME=$(echo $VDISK_NAME.$VDISK_EXT)
		VDISK_FULL_PATH=$(echo $PATH_VM_FOLDER/$VM_NAME/$VDISK_FILENAME)

		read -p "Restore vdisk: $BACKUP_FILE to $VDISK_FULL_PATH? (y/n):" CONT

		CONT=$(echo "$CONT" | awk '{print tolower($0)}')

		if [[ $CONT == "y" ]]; then

			if [[ "$BACKUP_FILE" == *".zst" ]]; then
				printf "${BOLD}Extracting backup file${RESET}\n"
				printf "VM Folder: $PATH_VM_FOLDER\n"
				printf "VM Name: $VM_NAME\n"
				printf "VM Disk: $VDISK_FILENAME\n"
				printf "VM Disk fullpath: $VDISK_FULL_PATH\n\n"
				printf "unzstd -C $BACKUP_FILE\n"
				unzstd -d -C --no-check $BACKUP_FILE -o $VDISK_FULL_PATH
				printf "${GREEN}!! Extraction finished !!${RESET}\n\n"
			fi

			if [[ "$BACKUP_FILE" == *".img" ]]; then
				printf "${BOLD}Copy backup file to domains folder${RESET}\n"
				printf "cp $BACKUP_FILE $PATH_VM_FOLDER/$VM_NAME/\n"
				cp $BACKUP_FILE $PATH_VM_FOLDER/$VM_NAME/

				printf "${GREEN}!! Copy finished !!${RESET}\n\n"
			fi
		else
			printf "${RED}!!! Skipping vdisk: $BACKUP_FILE !!!${RESET}\n\a"
		fi
	done

	printf "${BOLD}Copy .xml file${RESET}\n"
	BACKUP_FILE=$(echo $PATH_BACKUP_FOLDER/$VM_NAME/${BACKUP_DATE}_${VM_NAME}.xml)
	printf "cp $BACKUP_FILE /etc/libvirt/qemu/$VM_NAME.xml\n"
	cp $BACKUP_FILE /etc/libvirt/qemu/$VM_NAME.xml
	printf "${GREEN}!! Copy finished !!${RESET}\n\n"

	printf "${BOLD}Copy _VARS-pure-efi.fd file${RESET}\n"
	BACKUP_FILE=$(echo $PATH_BACKUP_FOLDER/$VM_NAME/${BACKUP_DATE}*_VARS-pure-efi.fd)
	CLEAN_BACKUP_FILE=${BACKUP_FILE:${#PATH_BACKUP_FOLDER}+${#VM_NAME}+${#BACKUP_DATE}+3}
	# +3 because there are two / and one _ in the file name
	printf "cp $BACKUP_FILE /etc/libvirt/qemu/nvram/$CLEAN_BACKUP_FILE\n"
	cp $BACKUP_FILE /etc/libvirt/qemu/nvram/$CLEAN_BACKUP_FILE
	printf "${GREEN}!! Copy finished !!${RESET}\n\n"
}

###
# Main
###

get_informations
restore_backup

print_separator
printf "${GREEN}Now turn off your Array and turn it back on.${RESET}\n"
printf "${GREEN}Your VM is restored${RESET}"
print_separator
