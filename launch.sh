#!/bin/bash
# Launch created by @Jarriz, @Josepdal and @iicc1
tgcli_version=1222
LOGFILE_MAXSIZE=10000 # Size max of bot/log.txt in KB
CACHE_FOLDER_MAXSIZE=100000 # Size max of bot/data/* in KB
dbteam_dir="DBTeamV2"
config_lines=(
'default_profile = "dbteam";'
''
'dbteam = {'
'	config_directory = "../'${dbteam_dir}'/bot";'
'	test = false;'
'	msg_num = true;'
'	lua_script = "bot.lua";'
'	log_level = 2;'
'	logname = "log.txt";'
'	verbosity = 100;'
'	wait_dialog_list = true;'
'}'
)

lualibs=(
'luasec'
'lbase64 20120807-3'
'luafilesystem'
'lub'
'luaexpat'
'redis-lua'
'lua-cjson'
'fakeredis'
'xml'
'feedparser'
'serpent'
)

function download_libs_lua() {
    today=`date +%F`
    if [[ ! -d "logs" ]]; then mkdir logs; fi
    if [[ -f "logs/logluarocks_${today}.txt" ]]; then rm logs/logluarocks_${today}.txt; fi
    local i file
    for i in ${!lualibs[@]}; do
        printf "\rDBTeam: downloading libs... [${i}/${#lualibs[@]}]\t${lualibs[i]}                  "
        ./.luarocks/bin/luarocks install ${lualibs[$i]} &>> logs/logluarocks_${today}.txt
    done
    sleep 0.2
    printf "\rDBTeam: downloading libs... [11/11]"
    printf "\nLogfile created: `pwd`/logs/logluarocks_${today}.txt\nDone\n"
    rm -rf luarocks-2.2.2*
}

function install() {
    install_libs_lua
    if [ -d /mnt/c/Windows ]; then
        echo "Patching bot.lua for Windows 10 support..."
        sed -i '5d' bot/bot.lua
        sed -i '5d' bot/bot.lua
        sed -i '5i\require("bot/utils")' bot/bot.lua
        sed -i '6i\require("bot/permissions")' bot/bot.lua
        sed -i '7i\--File patched to support W10' bot/bot.lua
    fi
}

function do_file() {
    local lines
    for i in ${!config_lines[@]}; do
        lines+=${config_lines[$i]}"\n"
    done
	if [[ ! -d ~/.telegram-cli ]]; then mkdir ~/.telegram-cli; fi
    echo -e $lines > ~/.telegram-cli/${1}
}

function character() {
    string=`echo "$2"`
    echo ${string:${letter}:1}
}

function update() {
    git checkout .
    git pull
}

function configure() {
    dir=`pwd`
    wget http://luarocks.org/releases/luarocks-2.2.2.tar.gz
    tar zxpf luarocks-2.2.2.tar.gz
    cd luarocks-2.2.2
    ./configure --prefix=$dir/.luarocks --sysconfdir=$dir/.luarocks/luarocks --force-config; make bootstrap; cd ..; rm -rf luarocks*
    if [[ ${1} != "--no-download" ]]; then
		download_libs_lua
        printf "Downloading telegram-cli v${tgcli_version}... [0%%]"
        wget https://valtman.name/files/telegram-cli-${tgcli_version} &>/dev/null
        printf "\r                                                    "
        if [ ! -d "bin" ]; then mkdir bin; fi
        mv telegram-cli-${tgcli_version} ./bin/telegram-cli; chmod +x ./bin/telegram-cli
    fi
    for i in 25 50 75 100; do
        printf "\rConfiguring... [%i%%]" $i
        sleep 0.5
    done
    printf "\nDone\n"
    do_file config
}

function start_bot() {
    if [[ $1 == "--"* ]]; then
        ./bin/telegram-cli --${1:2}
        exit
    elif [[ $1 == "-"* ]]; then
        ./bin/telegram-cli -${1:1}
        exit
    else
        ./bin/telegram-cli
    fi
}

function show_logo_slowly() {
    declare -A logo
    seconds="0.008"
    logo[1]="____  ____ ______"
    logo[2]="|    \|  _ )_   _|___ ____   __  __"
    logo[3]="| |_  )  _ \ | |/ .__|  _ \_|  \/  |"
    logo[4]="|____/|____/ |_|\____/\_____|_/\/\_|  v2"
    printf "\033[38;5;208m\t"
    for i in ${!logo[@]}; do
        for x in `seq 0 ${#logo[$i]}`; do
            printf "${logo[$i]:$x:1}"
            sleep $seconds
        done
        printf "\n\t"
    done
    printf "\n"
}

function show_logo() {
    #Adding some color. By @iicc1 :D
    echo -e "\033[38;5;208m"
    echo -e "\t____  ____ ______"
    echo -e "\t|    \|  _ )_   _|___ ____   __  __"
    echo -e "\t| |_  )  _ \ | |/ .__|  _ \_|  \/  |"
    echo -e "\t|____/|____/ |_|\____/\_____|_/\/\_|  v2"
    echo -e "\n\e[36m"
}

function delete_log() {
    LOG_FILE="bot/log.txt"
    if [ -f "$LOG_FILE" ]; then
        LOG_FILE_SIZE=`echo $(du -s $LOG_FILE)`
        VV=`echo ${LOG_FILE_SIZE//[a-Z\ \/.]/}`
        if [[ `echo $LOG_FILE_SIZE | grep -E "^[0-9]+"` ]]; then
            if [[ $VV -gt $LOGFILE_MAXSIZE ]]; then
                rm -rf $LOG_FILE
                echo -e "\033[1;36mLogfile (`pwd`/bot/log.txt) is greater than ${LOGFILE_MAXSIZE}K (${VV}K), deleted.\033[0m"
            fi
        fi
    fi
}

function delete_cache() {
    CACHE_FOLDER="bot/data"
    if [ -d "${CACHE_FOLDER}" ]; then
        CACHE_SIZE=`echo $(du -s $CACHE_FOLDER)`
        VV=`echo ${CACHE_SIZE//[a-Z\ \/.]/}`
        if [[ `echo $CACHE_SIZE | grep -E "^[0-9]+"` ]]; then
            if [[ $VV -gt $CACHE_FOLDER_MAXSIZE ]]; then
                list_dir=( `ls -1 -d bot/data/*/` )
                for ((i=0; i<${#list_dir[@]}; i++)); do
                    rm -rf ${list_dir[$i]}
                done
                echo -e "\033[1;36mCache folder (`pwd`/bot/data) is greater than ${CACHE_FOLDER_MAXSIZE}K (${VV}K), deleted.\033[0m"
            fi
        fi
    fi
}
delete_log
delete_cache

case $1 in
    install)
    show_logo_slowly
    configure ${2}
    exit ;;
    update)
    show_logo
    update
    exit ;;
esac
if [[ $1 == "-"* ]]; then
    show_logo
    start_bot $1
    exit
fi
show_logo
start_bot
exit
