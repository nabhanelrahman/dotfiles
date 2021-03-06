#
# vim:ft=sh:fenc=UTF-8:ts=4:sts=4:sw=4:expandtab:foldmethod=marker:foldlevel=0:
#
# Some functions are taken from
#       http://phraktured.net/config/
#       http://www.downgra.de/dotfiles/

# isTrue()#{{{
function isTrue() {
    case "${1}" in
        [Tt][Rr][Uu][Ee])
            return 0
        ;;
        [Tt])
            return 0
        ;;
        [Yy][Ee][Ss])
            return 0
        ;;
        [Yy])
            return 0
        ;;
        1)
            return 0
        ;;
    esac
    return 1
}
#}}}
# isFalse()#{{{
function isFalse() {
    case "${1}" in
        [Ff][Aa][Ll][Ss][Ee])
            return 0
        ;;
        [Ff])
            return 0
        ;;
        [Nn][Oo])
            return 0
        ;;
        [Nn])
            return 0
        ;;
        0)
            return 0
        ;;
    esac
    return 1
}
#}}}
# isNumber()#{{{
function isNumber() {
    [ "${#}" -lt "1" ] && return 1

    case "${1}" in
        [0-9]*)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}
#}}}
# inArray()#{{{
function inArray()
{
    local i
    [[ "${#}" -lt "2" ]] && return 1
    needle="${1}"
    shift
    haystack=(${@})
    for i in ${haystack[@]}; do
        [[ "${needle}" = "${i}" ]] && return 0
    done
    return 1
}
#}}}
# print_info()#{{{
# print_info(printlevel, print [, newline [, prefixline ] ])
function print_info() {
    local NEWLINE='1'
    local PREFIXLINE='1'
    local STR=''
    local PREFIXTEXT=''

    # NOT ENOUGH ARGS
    if [ "${#}" -lt '2' ] ; then return 1; fi

    # WRONG printlevel
    if [ "${1}" -lt "0" ]; then
        print_error 1 "printlevel must be above or equal 0"
        return 1
    fi

    # If printlevel is 0, the text must be bolded
    if [ "${1}" -eq "0" ]; then
        PREFIXTEXT="${FG_WHITE_B}"
    fi

    # IF 3 OR MORE ARGS, CHECK IF WE WANT A NEWLINE AFTER PRINT
    if [ "${#}" -gt '2' ]
    then
        if isTrue "${3}"
        then
            NEWLINE='1';
        else
            NEWLINE='0';
        fi
    fi

    # IF 4 OR MORE ARGS, CHECK IF WE WANT TO PREFIX WITH A *
    if [ "${#}" -gt '3' ]
    then
        if isTrue "${4}"
        then
            PREFIXLINE='1'
        else
            PREFIXLINE='0'
        fi
    fi

    # STRUCTURE printlevel
    if [ "${1}" -gt "1" ]; then
        PRINTLEVEL="$(for i in $(seq 1 ${1}); do echo -ne "  "; done)"
    else
        PRINTLEVEL=" "
    fi

    # STRUCTURE DATA TO BE OUTPUT TO SCREEN, AND OUTPUT IT
    if [ "${PREFIXLINE}" = '1' ]
    then
        STR="${GOOD}*${FG_CLEAR}${PRINTLEVEL}${PREFIXTEXT}${2}${FG_CLEAR}"
    else
        STR="${PREFIXTEXT}${2}${FG_CLEAR}"
    fi

    if [ "${NEWLINE}" = '0' ]
    then
        echo -ne "${STR}"
    else
        echo -e "${STR}"
    fi

    return 0
}
#}}}
# print_error()#{{{
function print_error()
{
    GOOD=${ERROR} print_info "${@}" >&2
}
#}}}
# print_warning()#{{{
function print_warning()
{
    GOOD=${WARN} print_info "${@}"
}
#}}}
# print_coloumn()#{{{
function print_coloumn()
{
    [ "${#}" -lt "2" ] && return 1
    local coloumn="${1}"
    shift
    local text="${@}"
    print_info 1 "\033[$((${coloumn}))G${text}" false false
}
#}}}
# check_root()#{{{
function check_root()
{
    if [ "$(id -u)" != "0" ]; then
        return 1
    else
        return 0
    fi
}
#}}}
# need_root()#{{{
function need_root()
{
    if ! check_root; then
        print_warning 0 "Re-Running the script under root."
        if [ -x "$(/usr/bin/which sudo 2> /dev/null)" ]; then
            if yes 'NOPASS' | sudo -S -l 2> /dev/null | grep -q "NOPASSWD"; then
                sudo "${0}" ${@}
            else
                # We need the user to put a password.
                print_info 1 "You must enter the password for '${USER}' to open a root session."
                sudo "${0}" ${@}
            fi
        else
            local PreserveEnvironment=""

            # There is no sudo command, we have to use 'su'.
            print_info 1 "You must enter the password for 'root' to open a root session."

            # Try to preserve the environment, if possible, on linux
            # it is possible, but on FreeBSD-like system it is not, unless
            # the caller has uid 0 (a.k.a root) which isn't the case.
            #
            # Enable it by default it on Linux, and disable it in case
            # it's a FreeBSD and for everything else...
            if [ "$( uname )" = "Linux" ]; then
                PreserveEnvironment="-p"
            fi

            # the actual su command
            su -l root ${PreserveEnvironment} -c "export HOME=${HOME}; ${0} ${@}"
        fi
        exit "${?}"
    else
        return 0
    fi
}
#}}}
# needNet()#{{{
function needNet()
{
    # is it a sticky application ?{{{
    if [ "${1}" = "-k" ]; then
        KEEP=true
        shift
    else
        KEEP=false
    fi
    #}}}
    # Sanity checks{{{
    if [ "${#}" -lt 1 ]; then
        print_error 0 "Usage: needNet <command> [args...]"
        return 1
    fi
    #}}}
    # Global Variables{{{
    COMMAND="${1}"
    shift
    ARGS=${@}
    #}}}
    # Launch the application.#{{{
    # This loop will wait untill a connection is available
    # and then launch the program.
    (
        while true; do
            if ping -c 1 google.com &> /dev/null; then
                "${COMMAND}" ${ARGS}
                if isTrue ${KEEP}; then
                    continue
                else
                    break
                fi
            else #* We couldn't connect, print a warning and sleep for 5 mins... *#
                print_warning 0 "I couldn't ping google.com, retrying to launch ${COMMAND} in 30 seconds..."
                sleep 30
            fi
        done
    ) &
    #}}}

    unset COMMAND
    unset ARGS
    unset KEEP

}
#}}}
# not_root()#{{{
function not_root()
{
    if check_root; then
        print_error 0 "For security reasons, you should not run this script as root!"
        exit 1
    fi
}
#}}}
# c()#{{{
function c() {
    local cmd flags archive files answer
    if [ "${#}" -gt "1" ]; then
        archive="${1}"
        shift
        files="${@}"
        if [ -f "${archive}" ]; then
            print_info 1 "The destination file '${archive}' already exists, overwride [y/n] " false
            read answer; echo
            if isTrue "${answer}"; then
                rm -f -- "${archive}"
            else
                print_warning 0 "Aborting..."
                return 1
            fi
        fi

        case "${archive}" in
            *.tar.bz2)
                cmd="tar"
                flags="cjf"
                ;;
            *.tar.gz)
                cmd="tar"
                flags="czf"
                ;;
            *.bz2)
                cmd="bzip2"
                flags=""
                archive="" # Bzip2 takes one Argument
                ;;
            *.rar)
                cmd="rar"
                flags="c"
                ;;
            *.gz)
                cmd="gzip"
                flags=""
                archive="" # gzip takes one Argument
                ;;
            *.tar)
                cmd="tar"
                flags="cf"
                ;;
            *.jar)
                cmd="jar cf"
                flags="cf"
                ;;
            *.tbz2)
                cmd="tar"
                flags="cjf"
                ;;
            *.tgz)
                cmd="tar"
                flags="czf"
                ;;
            *.zip|*.xpi)
                cmd="zip"
                flags="-r"
                ;;
                # TODO .Z and .7z formats
                *)
                print_error 0 "'${archive}' is not a valid archive type i am aware of."
                return 1
                ;;
        esac
        # Ok extract it now but first let's see if the progam can be used
        if ! type "${cmd}" &>/dev/null; then
            print_error 0 "I couldn't find the program '${cmd}', Please make sure it is installed."
            return 1
        fi
        ${cmd} ${flags} ${archive} ${files}
        if [ "${?}" -ne "0" ]; then
            print_error 0 "Oops an error occured..."
            return 1
        else
            print_info 0 'Archive has been successfully Created!'
        fi
    else
        print_error 0 "USAGE: c <Archive name> <Files and/or folders>"
        return 1
    fi
}
#}}}
# spwgen()#{{{
function spwgen()
{
    if [[ "${1}" == "-h" ]]; then
        print_error 0 "Usage: ${0} <pwlen> <passwords>"
    else
        local pl="${1}"
        local np="${2}"
        test -z "${pl}" && pl="12"
        test -z "${np}" && np="10"
        perl <<EOPERL
my @a = ("a".."z","A".."Z","0".."9",(split //, q{#@,.<>$%&()*^}));
for (1.."$np") {
    print join "", map { \$a[rand @a] } (1.."$pl");
    print qq{\n}
}
EOPERL
    fi
}
#}}}
# sapg()#{{{
# generate passwords with apg
function sapg()
{
    if [[ -f $(which apg) ]]; then
        if [[ "${1}" == "-h" ]]; then
            print_error 0 "usage: ${0} <pwlen> <number of passwords>"
        else
            if [[ "${1}" -le "2" ]]; then
                print_error 0 "password too small!"
                return 1
            fi
            apg -x "${1}" -m "${1}" -n "${2}" -t -M NCL
        fi
    else
        print_error 0 "apg not installed... aborting."
        return 1
    fi
}
#}}}
# plocale()#{{{
# print current settings of LC_*
function plocale()
{
    print_info 0 "Current settings of LC_*"
    print_info 2 "LANG=${LANG}"
    print_info 2 "LC_ALL=${LC_ALL}"
    print_info 2 "LC_CTYPE=${LC_CTYPE}"
    print_info 2 "LC_NUMERIC=${LC_NUMERIC}"
    print_info 2 "LC_TIME=${LC_TIME}"
    print_info 2 "LC_COLLATE=${LC_COLLATE}"
    print_info 2 "LC_MONETARY=${LC_MONETARY}"
    print_info 2 "LC_MESSAGES=${LC_MESSAGES}"
    print_info 2 "LC_PAPER=${LC_PAPER}"
    print_info 2 "LC_NAME=${LC_NAME}"
    print_info 2 "LC_ADDRESS=${LC_ADDRESS}"
    print_info 2 "LC_TELEPHONE=${LC_TELEPHONE}"
    print_info 2 "LC_MEASUREMENT=${LC_MEASUREMENT}"
    print_info 2 "LC_IDENTIFICATION=${LC_IDENTIFICATION}"
}
#}}}
# kernel()#{{{
# kernel related functionality
function kernel() {
    local ks="http://www.kernel.org";
    local kver="$2"
    local kmaj=$(echo "$kver" | awk -F"." '{print $1"."$2}')
    case "$1" in
        "help" | "-h" | "--help")
            echo "kernel help | -h | --help   - show this help"
            echo "kernel [info]               - show latestet kernel versions"
            echo "kernel get <ver>            - download kernel version x.x.x.x bz2 and sign file"
            echo "kernel changelog | cl <ver> - show changelog form kernel version x.x.x.x"
            echo
            ;;
        "info" | "")
            echo "latest kernel versions:"
            wget -qO - "$ks/kdist/finger_banner"
            echo
            ;;
        "get")
            case "${2}" in
                "latest" | "lat" | "l")
                    local l=$(wget -qO - "${ks}/kdist/finger_banner" | grep "latest stable" | \
                        awk -F":" '{sub(/^ *| *$/, "", $2); print $2}')
                    test -n "${l}" && echo "found latest kernel: ${l}" && kernel get "${l}"
                    ;;
                *)
                    test -z "${kver}" && \
                        kver=$(wget -qO - "${ks}/kdist/finger_banner" | head -n 1 | awk -F':' '{gsub(/^ */, "", $2); print $2}')
                    echo "get kernel: ${kver}"
                    # get kernel sign key
                    gpg --keyserver wwwkeys.pgp.net --recv-keys 0x517D0F0E
                    if [[ -z $(echo "${kver}" | grep -i "rc") ]]; then
                        local file="${ks}/pub/linux/kernel/v$kmaj/linux-$kver.tar.bz2"
                    else
                        local file="${ks}/pub/linux/kernel/v$kmaj/testing/linux-$kver.tar.bz2"
                    fi
                    wget -c "${file}"
                    wget -c "${file}"".sign"
                    echo "check signature ..."
                    test -f "linux-${kver}.tar.bz2" -a -f "linux-${kver}.tar.bz2.sign"  && \
                        gpg --verify linux-${kver}.tar.bz2.sign linux-${kver}.tar.bz2 2>&1
                        #| \
                        #    egrep -i "Unterschrift|good signature"
                    ;;
            esac
            ;;
        "changelog" | "cl")
            case "${2}" in
                "latest" | "lat" | "l")
                    local l=$(wget -qO - "${ks}/kdist/finger_banner" | grep "latest stable" | \
                        awk -F":" '{sub(/^ *| *$/, "", $2); print $2}')
                    test -n "${l}" && echo "found latest kernel: ${l}" && kernel changelog "${l}"
                    ;;
                *)
                   if [[ -z $(echo "${kver}" | grep -i "rc") ]]; then
                        local file="${ks}/pub/linux/kernel/v${kmaj}/ChangeLog-${kver}"
                    else
                        local file="${ks}/pub/linux/kernel/v${kmaj}/testing/ChangeLog-${kver}"
                    fi
                    echo "changelog topics for ${kver}:"
                    wget -qO - "${file}" | grep ".*\[.*\].*" | sed 's/^[ \t]*/  /'
                    ;;
            esac
            ;;
        esac
}
#}}}
# scprsa()#{{{
function scprsa()
{
    if [[ -z "$1" ]]; then
        print_error 0 "!! You need to enter a hostname in order to send your public key !!"
    else
        print_info 0 "Copying SSH public key to server..."
        ssh ${1} "mkdir -p ~/.ssh && touch ~/.ssh/authorized_keys && cat - >> ~/.ssh/authorized_keys" < "${HOME}/.ssh/id_rsa.pub"
        print_info 0 "All done!"
    fi
}
#}}}
# least()#{{{
# Wrapper around PAGER.
# if lines paged fit on a screen they will be dumped to STDOUT, otherwise they
# are paged through your pager.
#
# From Bart Trojanowski
# http://www.jukie.net/~bart/scripts/least/bashrc.least
function least()
{
    declare -a lines

    if ! [ -z "$@" ] ; then
        cat $@ | least
        return 0
    fi

    if [ -z "$LINES" ] || ! ( echo $LINES | grep -q '^[0-9]\+$' ) ; then
        LINES=20
    fi

    # dump_array()#{{{
    function dump_array () {
        for n in `seq 1 "${#lines[@]}"` ; do
            echo "${lines[$n]}"
        done
    }
    #}}}

    while read x ; do
        lines[((${#lines[@]}+1))]="$x"

        if [ "${#lines[@]}" -ge $LINES ] ; then
            ( dump_array ; cat ) | $LEAST_PAGER
            return 0
        fi
    done

    dump_array
}
#}}}
# stats()#{{{
function stats() {
  history | awk '{CMD[$4]++;count++;}END { for (a in CMD)print CMD[a] " " CMD[a]/count*100 "% " a;}' | grep -v "./" | column -c3 -s " " -t | sort -nr | nl |  head -n20
}
#}}}
# scs()#{{{
function scs() {
  if [[ "${#}" -ne 1 ]]; then
    print_error 0 "Usage: scs <session>"
    return 1
  fi

  session="${1}"

  # U=utf8, R=reattach, q=quiet, x=multiplex
  screen_cmd="screen -x -q -U -R ${session} -t ${session}"

  if [[ -f "${HOME}/.screen/sessions/${session}" ]]; then
    screen_cmd="${screen_cmd} -c '${HOME}/.screen/sessions/${session}'"
  fi

  eval "${screen_cmd}"
}
#}}}
# zssh()#{{{
function zssh() {
    local user_host_port=${1}
    local SSH=/usr/bin/ssh
    local REMOTE_SSH_USER=""
    local DESTZDOTDIR=""
    local controlmaster_running=""

    # fail-fast if no user/host/port were given
    if [[ -z "${user_host_port}" ]]; then
        print_error 0 "Usage zssh <[user@]host[:port]>"
        return 1
    fi

    # let's get the user ssh'ing into the host
    REMOTE_SSH_USER="$(echo $user_host_port | grep @ | cut -d@ -f1)"
    REMOTE_SSH_USER="${REMOTE_SSH_USER:-$USER}"

    # The private home folder
    DESTZDOTDIR="/tmp/${USER}.zdotdir.${REMOTE_SSH_USER}"

    if [[ "$($SSH -O check ${user_host_port} &>/dev/null; echo $?)" -eq "0" ]]; then
        controlmaster_running="true"
    else
        controlmaster_running="false"
    fi

    if isFalse ${controlmaster_running}; then
        # start the controlmaster
        $SSH ${user_host_port} /bin/true
        # Transfer what we need to the server
        rm -rf $DESTZDOTDIR && mkdir -p $DESTZDOTDIR
        cp -RL ${HOME}/.{zsh,zshrc,zshrc.google,tmux.conf} $DESTZDOTDIR/
        infocmp > "$DESTZDOTDIR/${TERM}.info"
        rsync -auz --delete $DESTZDOTDIR/ ${user_host_port}:$DESTZDOTDIR/
        $SSH ${user_host_port} "chmod 700 $DESTZDOTDIR; tic $DESTZDOTDIR/${TERM}.info"
    fi

    $SSH -tt ${user_host_port} ZDOTDIR=${DESTZDOTDIR} TMUXDOTDIR=${DESTZDOTDIR} zsh -i
}
#}}}
# pathmunge()#{{{
function pathmunge() {
    if ! [[ $PATH =~ (^|:)$1($|:) ]]; then
       if [ "$2" = "after" ] ; then
          PATH=$PATH:$1
       else
          PATH=$1:$PATH
       fi
    fi
}
#}}}
# nse()#{{{
function nse (){
    docker exec -it $1 bash
}
#}}}
# devnfs() #{{{
function devnfs() {
  docker-machine ssh dev '\
  export IP="$(netstat -rn | grep eth1 | awk "{print $1}" | cut -d. -f1-3).1" \
  && sudo umount /Users \
  && sudo /usr/local/etc/init.d/nfs-client start >/dev/null \
  && sudo mount $IP:/Users /Users -o rw,async,noatime,rsize=32768,wsize=32768,proto=tcp \
  && echo "Mounted /Users over NFS"'
}
#}}}
# sp() #{{{
function sp() {
    profiles=()
    for wpf in ${HOME}/.zsh/profiles/*.zsh; do
        f="`basename "${wpf}"`"
        profiles=(${profiles[@]} ${f%%.zsh})
    done
    if [ "${#}" -eq "0" -o "${1}" = "ls" ]; then
        for wpf in ${profiles[@]}; do
            if [[ "x${wpf}" = "x${ACTIVE_PROFILE}" ]]; then
                echo "${FG_GREEN}*${FG_CLEAR} ${wpf}"
            else
                echo "  ${wpf}"
            fi
        done
    elif [[ "${1}" = "kill" ]]; then
        if [[ -n "${ACTIVE_PROFILE}" ]]; then
            source "${HOME}/.zsh/profiles/${ACTIVE_PROFILE}.zsh"
            pdeactivate
            unset ACTIVE_PROFILE SSH_AGENT_PID SSH_AUTH_SOCK SSH_AGENT_NAME
            eval `ssh-agents $SHELL`
        fi
    else
        if [[ ! -e "${HOME}/.zsh/profiles/${1}.zsh" ]]; then
            echo "profile ${1} not found."
            return 1
        fi

        sp kill
        source "${HOME}/.zsh/profiles/${1}.zsh"
        pactivate
        export ACTIVE_PROFILE="${1}"
        export SSH_AGENT_NAME="${1}"
        unset SSH_AGENT_PID SSH_AUTH_SOCK
        eval `ssh-agents $SHELL`
    fi
}
#}}}
# xmlpp() #{{{
function xmlpp() {
    if [[ "${#}" -eq 0 ]]; then
        xmllint --format -
    else
        input_file="${1}"
        if [[ "${#}" -eq 2 ]]; then
            output_file="${2}"
        else
            output_file="`mktemp /tmp/xmlpp.XXXXXXXX`"
        fi

        xmllint --format --output "${output_file}" "${input_file}" || return
        mv "${output_file}" "${input_file}"
    fi
}
#}}}
# jsonpp() #{{{
function jsonpp() {
    if [[ "${#}" -eq 0 ]]; then
        python -m json.tool | pygmentize -l javascript
    else
        input_file="${1}"
        if [[ "${#}" -eq 2 ]]; then
            output_file="${2}"
        else
            output_file="`mktemp /tmp/xmlpp.XXXXXXXX`"
        fi

        python -m json.tool < "${input_file}" > "${output_file}" || return
        mv "${output_file}" "${input_file}"
    fi
}
#}}}
# tmx() #{{{
function tmx() {
    local ap="${ACTIVE_PROFILE}"
    local sess="${1}"

    if [ "x${sess}" = "xls" ]; then
        tmux -f "${TMUXDOTDIR:-$HOME}/.tmux.conf" ls
        return 0
    fi

    if [ "x${sess}" = "x" ]; then
        # session name cannot contain a dot or a column
        # https://github.com/tmux/tmux/blob/76688d204071b76fd3388e46e944e4b917c09625/session.c#L232
        sess="$( echo `basename ${PWD}` | sed -e 's#\.##g' -e 's#:##g' )"
    fi

    tmux -f "${TMUXDOTDIR:-$HOME}/.tmux.conf" attach -t "${sess}" || \
        tmux -f "${TMUXDOTDIR:-$HOME}/.tmux.conf" new -s "${sess}" \; \
            set-environment ACTIVE_PROFILE "$ap" \; \
            set-environment SSH_AGENT_NAME "$ap" \; \
            new-window \; \
            kill-window -t :0 \; \
            new-window -t :0 'zsh -i -c vim' \;

    return $?
}
#}}}
# machdev() #{{{
function machdev() {
    if [[ -x `which docker-machine 2>/dev/null` ]]; then
      eval `docker-machine env dev`
      export DOCKER_MACHINE_DEV_IP="`docker-machine ip dev`"
    fi
}
#}}}
# machzeus() #{{{
function machzeus() {
    if [[ -x `which docker-machine 2>/dev/null` ]]; then
      eval `docker-machine env zeus`
      export DOCKER_MACHINE_ZEUS_IP="`docker-machine ip zeus`"
    fi
}
#}}}
# calc() #{{{
# Taken from https://github.com/mathiasbynens/dotfiles/blob/master/.functions
function calc() {
	local result="";
	result="$(printf "scale=10;$*\n" | bc --mathlib | tr -d '\\\n')";
	#                       └─ default (when `--mathlib` is used) is 20
	#
	if [[ "$result" == *.* ]]; then
		# improve the output for decimal numbers
		printf "$result" |
		sed -e 's/^\./0./'        `# add "0" for cases like ".5"` \
		    -e 's/^-\./-0./'      `# add "0" for cases like "-.5"`\
		    -e 's/0*$//;s/\.$//';  # remove trailing zeros
	else
		printf "$result";
	fi;
	printf "\n";
}
# }}}
# mkd() {{{
# Taken from https://github.com/mathiasbynens/dotfiles/blob/master/.functions
function mkd() {
    mkdir -p "$@" && cd "$_";
}
# }}}
# pled() {{{
function pled() {
    plutil -convert xml1 ${1}
    ${EDITOR} ${1}
    plutil -convert binary1 ${1}
}
# }}}
# cdc() {{{
function cdc() {
    cd "${GOPATH}/src/${@}"
}
# }}}
