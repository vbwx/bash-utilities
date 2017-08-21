function println {
	printf "%s\n" "$*"
}

function print {
	printf "%s" "$*"
}

function die {
	println "$script: $1" >&2
	exit 1
}

function warn {
	printf "\n%s!\n" "$*" >&2
}

function exist {
	type -t "$1" > /dev/null
}

function inshare {
	[[ -e "/usr/share/$1" || -e "$prefix/share/$1" || -e "$HOME/.local/share/$1" ]]
}

function islocal {
	local bin="$(type -P "$1" 2> /dev/null)"
	exist "$1" && [[ ${bin#*$prefix} != $bin ]]
}

function inhome {
	[[ -e "$HOME/$1" || -e "$HOME/.local/$1" ]]
}

function clone {
	[[ -e "${@:(-1)}" ]] || git clone --recursive "$@"
}

function download {
	[[ ${2-} ]] || set - "$1" "$TMPDIR/$(basename "$1")"
	[[ -e $2 ]] && return
	curl --create-dirs -fsSLo "$2" "$1" && downloaded="$2"
}

function copy {
	local i dest
	if [[ ${1-} && ${2-}]]; then
		dest="${@:(-1)}"
		i=$[$#-2]
		[[ ${dest:(-1)} == '/' ]] && set - "${@:1:$i}" "$dest$(basename "$1")"
		makedir "$(dirname "$dest")"
		[[ -e "$dest" ]] || cp -Rv "$@"
	fi
}

function difcopy {
	if [[ ${1-} && ${2-} ]]; then
		[[ ${2:(-1)} == '/' ]] && set - "$1" "$2$(basename "$1")"
		makedir "$(dirname "$2")"
		diff "$1" "$2" &> /dev/null || cp -v "$1" "$2"
	fi
}

function move {
	local i dest
	if [[ ${1-} && ${2-} ]]; then
		i=$[$#-2]
		dest="${@:(-1)}"
		[[ ${dest:(-1)} == '/' ]] && set - "${@:1:$i}" "$dest$(basename "$1")"
		makedir "$(dirname "$dest")"
		[[ -e "$dest" ]] || mv -v "$@"
	fi
}

function link {
	local i dest
	if [[ ${1-} ]]; then
		if [[ ${2-} ]]; then
			i=$[$#-2]
			dest="${@:(-1)}"
			if [[ ${dest:(-1)} == '/' ]]; then
				makedir "$dest"
			else
				makedir "$(dirname "$dest")"
			fi
		fi
		[[ -e "$dest" ]] || ln -vs "$@"
	fi
}

function makedir {
	if [[ ${1-} ]]; then
		[[ -d $1 ]] || mkdir -vp "$@"
	fi
}

function trim {
	local str
	for str in "$@"; do
		str="${str#"${str%%[![:space:]]*}"}"
		str="${str%"${str##*[![:space:]]}"}"
		if [[ $str ]]; then
			if [[ $# -eq 1 ]]; then
				print "$str"
			else
				println "$str"
			fi
		fi
	done
}

function explode {
	[[ $# -eq 0 ]] && return
	local items
	if [[ ${2-} ]]; then
		if [[ ${2:0:1} == '+' ]]; then
			items=(${1//${2:1}/$'\n'})
		else
			items=(${1/${2:1}/$'\n'})
		fi
	else
		items=(${1//:/$'\n'})
	fi
	print "$(trim "${items[@]}")"
}

function escape {
	print "$1" | LC_ALL=C sed 's/[]\\\\/.$&*{}|+?()[^]/\\&/g'
}

function quote {
	local first=1
	for str in "$@"; do
		[[ $first -eq 0 ]] && print " "
		first=0
		print "\"$(print "$str" | LC_ALL=C sed -e \
			's/[^a-zA-Z0-9,._+@%/-]/\\&/g; 1{$s/^$/""/}; 1!s/^/"/; $!s/$/"/' \
			)\""
	done
}

function modify {
	local os="$(uname)"
	if [[ ${os,,} == 'linux' ]]; then
		if [[ ${2-} ]]; then
			sed -i"${3-\~}" -r "$1" "$2"
		else
			sed -r "$1"
		fi
	else
		if [[ ${2-} ]]; then
			sed -E -i "${3-\~}" "$1" "$2"
		else
			sed -E "$1"
		fi
	fi
}

function isroot {
	[[ -w /etc ]]
}

function runasroot {
	exec -c sudo bash "$(readlink -f "$0")" "$@"
}

function usage {
	local script="$(basename "$0")"
	println "usage: $script arguments..." >&2
	if [[ $# -eq 0 ]]; then
		println "   or  $script --version"
	else
		println "Try '$script --help' for more information." >&2
		exit $1
	fi
	println
}

function help {
	usage 2>&1
	cat <<-EOF
	Description

	Options
	...
EOF
	exit
}
