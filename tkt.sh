#/bin/sh
# saner programming env: these switches turn some bugs into errors
# found at https://stackoverflow.com/a/29754866
set -o errexit -o pipefail -o noclobber -o nounset

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# default args
TKTDIR="/tickets"

# make sure the ticketing directories exist
if [ ! -d "$TKTDIR" ]; then
	mkdir "$TKTDIR"
	mkdir "$TKTDIR/open"
	mkdir "$TKTDIR/closed"
fi

update=false
num_print=10
name=""
sev=""
desc=""
tnum=""

usage() {
	echo "$0 - make tickets with ease!"
	echo ""
	echo "Usage: $0 [OPTIONS]"
	echo ""
	echo "Options:"
	echo "  -o, --opened              display number of open tickets and exit"
	echo "  -c, --closed              display number of closed tickets and exit"
	echo "  -p, --print-open[=n]      print the n oldest open tickets and exit"
	echo "                                    Defaults to 10"
	echo "  -u, --update=TICKET_NUM   update a ticket instead of creating a new one."
	echo "                                    This will allow you to change the name,"
	echo "                                    severity, or append a description."
	echo "                                    If the ticket is closed, it will be reopened"
	echo "  -n, --name=NAME           create a ticket titled NAME"
	echo "  -s, --sev=SEV-LEVEL       create a ticket with SEV-LEVEL"
	echo "  -d, --desc=DESC           create a ticket with DESC"
	echo "  -x, --close=TICKET_NUM    close ticket TICKET_NUM then exit"
	echo "  -h, --help                display this message then exit"
	echo ""
}

num_open() {
	num="$(ls -l $TKTDIR/open/ | wc -l)"
	# minus one because of the "total" line in ls
	echo -e "${RED}$((num - 1))${NC} open tickets"
}

num_closed() {
	num="$(ls -l $TKTDIR/closed/ | wc -l)"
	# minus one because of the "total" line in ls
	echo -e "${GREEN}$((num - 1))${NC} closed tickets"
}

print_open() {
	num_open
	files=$(ls $TKTDIR/open/ | sort -n | head -$1)
	if [ -z "$files" ]; then
		echo "No open tickets. Yay!"
		exit
	fi
	for fl in $files
	do
		printf "${RED}$fl\n"
		printf '%.s-' {1..70}
		printf "\n${NC}"
		while IFS= read -r line; do 
			echo -e "\t$line"
		done < "$TKTDIR/open/$fl"
	done
}

# -p and --print-open are slightly different because getopt doesn't handle
# optional arguments for the short version for some reason
LONG=help,opened,closed,print-open::,name:,desc:,sev:,close:,update:
SHORT=hocpn:d:s:x:u:


# Again from https://stackoverflow.com/a/29754866
# -regarding ! and PIPESTATUS see above
# -temporarily store output to be able to check for errors
# -activate quoting/enhanced mode (e.g. by writing out “--options”)
# -pass arguments only via   -- "$@"   to separate them correctly
! PARSED=$(getopt --options=$SHORT --longoptions=$LONG --name "$0" -- "$@")
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
    # e.g. return value is 1
    #  then getopt has complained about wrong arguments to stdout
    exit 2
fi
eval set -- "$PARSED"

while true; do
	case "$1" in
		-h|--help)
			usage
			exit
			;;
		-o|--opened)
			num_open
			exit
			;;
		-c|--closed)
			num_closed
			exit
			;;
		# -p and --print-open slightly different because of getopt weirdness
		-p)
			print_open $num_print
			exit
			;;
		--print-open)
			# Default
			if [ -z "$2" ]; then
				shift
			else
				num_print="$2"
				shift 2
			fi
			print_open $num_print
			exit
			;;
		-n|--name)
			name="$2"
			shift 2
			;;
		-d|--desc)
			desc="$2"
			shift 2
			;;
		-s|--sev)
			sev="$2"
			shift 2
			;;
		-x|--close)
			toclose="$2"
			if [ ! -f "$TKTDIR/open/$toclose" ]; then
				if [ -f "$TKTDIR/closed/$toclose" ]; then
					echo "Ticket '$toclose' has already been closed"
				else
					echo "Ticket '$toclose' does not exist" 
				fi
			else
				mv "$TKTDIR/open/$toclose" "$TKTDIR/closed/$toclose"
				echo "Ticket '$toclose' has been closed"
			fi
			exit
			;;
		-u|--update)
			update=true
			tnum="$2"
			shift 2
			;;
		\?*)
			echo "Invalid option: $1" 1>&2
			usage
			exit 1
			;;
		# no more cases. break out of loop
		--)
			shift
			break
			;;
		*)
			echo "Internal error"
			exit 2
			;;
	esac
done


if [ "$update" = true ]; then
	# We're updating a ticket. Handled differently
	if [ ! -f "$TKTDIR/open/$tnum" ]; then
		if [ ! -f "$TKTDIR/closed/$tnum" ]; then
			echo "Ticket '$tnum' does not exist" 
			exit 1
		else
			# we assume since the user is updating a closed ticket, that they
			# want to reopen the ticket.
			mv "$TKTDIR/closed/$tnum" "$TKTDIR/open/$tnum"
			echo -e "Ticket $tnum is ${GREEN}reopened${NC}"
		fi
	fi
	# Handled the cases where it's closed or doesn't exist, carry on.
	filename="$TKTDIR/open/$tnum"
	[ ! -z "$name" ] && sed -i "1s/.*/$name/" $filename
	[ ! -z "$sev" ] && sed -i "2s/.*/$sev/" $filename
	[ ! -z "$desc" ] && echo "$desc" >> "$filename"
	echo "Ticket $tnum has been modified"
else
	# We're not updating a ticket, we're creating it.
	opened=$(($(ls -l "$TKTDIR/open/" | wc -l) - 1))
	tnum=$(($(ls -l "$TKTDIR/closed/" | wc -l) + opened))
	if [ -z "$name" ]; then
		# No name given, we must have a name
		echo -e "${RED}A ticket must have a name${NC}"
		echo ""
		usage
		exit 1
	fi
	filename="$TKTDIR/open/$tnum"
	touch "$filename"

	echo "$name" >> "$filename"
	# we want sev to be there, even if it's blank, mostly because of the
	# update option
	echo "$sev" >> "$filename"
	[ ! -z "$desc" ] && echo "$desc" >> "$filename"

	echo "Your ticket has been opened and is number $tnum"
fi

