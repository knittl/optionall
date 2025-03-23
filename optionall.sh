#!/bin/sh

dbg() { printf '{%s} ' "$@" >&2; printf '\n'; }

printf 'ARGS:'
printf ' [%s]' "$@"
printf '\n'

# TODO tests
# TODO don't parse "-N123" as "-123" if "-N" is unknown?
# TODO dynamic code gen to be eval'd?
# TODO static code gen?
# TODO let users handle end of options via callback?

is_function() {
	case "$(type -- "$1" 2>/dev/null)" in
		*function*) return 0 ;;
		*) return 1 ;;
	esac
}

if ! is_function argument; then
argument() {
	arg=$1 value=$2 orig=$3
	dbg argument "arg=$arg" "val=$value" "orig=$orig"
	case "$arg" in
		--name) name=$value; return 1 ;;
		--age) age=$value; return 1 ;;
		--help|-h) help=1; return 0 ;;
		-v) verbosity=$((verbosity+1)); return 0 ;;
		-d) delim=$value; return 1 ;;
		-f) field=$value; return 1 ;;
		-n) number=$value; return 1 ;;
		-[0-9]*) number=${orig#-}; return 0 ;;
		-?) echo "Invalid option $arg"; exit 1 ;;
		--*) echo "Invalid option $arg"; exit 1 ;;
		# *) return 1 ;;
	esac
}
fi

parselong() {
	dbg parselong
	value=${arg#*=}
	if [ "$value" = "$arg" ]; then
		value=$next opt_state=skip
	fi
	argument "${arg%%=*}" "$value" "$arg"
	case "$?" in
		0) opt_state= ;;
		*) ;;
	esac
}

parseshort() {
	dbg parseshort
	fullarg=$arg
	arg=${arg#-}
	while [ "$arg" ]; do
		value=${arg#?}
		set -- "$value"
		a=-${arg%"$value"}
		if ! [ "$value" ]; then
			dbg emptyvalue
			value=$next opt_state=skip
		fi
		argument "$a" "$value" "$fullarg"
		case "$?" in
			0) opt_state= ;;
			*) break ;;
		esac
		arg=$1
	done
}

opt_state=
for arg; do
	shift
	dbg "handling" "$arg"

	case "$opt_state" in
		end) set -- "$@" "$arg"; continue ;;
		skip) opt_state=; continue ;;
	esac

	next=$1
	case "$arg" in
		# end of options
		--) opt_state=end ;;
		# long args (with values)
		--?*) parselong ;;
		# short args
		-?*) parseshort ;;
		# non-args
		*) set -- "$@" "$arg" ;;
	esac
done

optionall_parse() {
	parsed=$1
	unparsed=${2:-set}
	shift 2

	optionall_init
	for arg; do
		shift
		# [ "$opt_state" = end ] && { set -- "$@" "$arg"; continue; }
		if [ "$opt_state" = end ]; then
			set -- "$@" "$arg";
			"$unparsed" "$arg";
			continue;
		fi
		if [ "$opt_state" = skip ]; then
			dbg "skipping $arg"
			opt_state=
			continue
		fi

		value=${arg#*=} next=$1
		case "$arg" in
			# end of options
			--) opt_state=end ;;
			# long args (with values)
			--?*) parselong "$@" ;;
			# short args
			-?*) parseshort "$@" ;;
			# non-args
			# *) set -- "$@" "$arg"; opt_state= ;;
			# TODO which parameters to pass to unparsed? allow to pass "set"?
			# TODO implement special handling for "set"?
			# TODO how to handle "end of options" ('--')?
			# *) "$unparsed" -- "$@" "$arg"; opt_state= ;;
			*)
				set -- "$@" "$arg"; opt_state=
				"$unparsed" "$arg" ;;
		esac
	done
}

printf 'PARSED:'
printf ' [%s]' "$@"
printf '\n'

echo "help=$help"
echo "name=$name"
echo "age=$age"
echo "verbosity=$verbosity"
echo "number=$number"
echo "delimiter=$delim"
echo "delimiter='$delim'"
echo "field=$field"
