#!/bin/sh

dbg() { printf '%s\n' "$*" >&2; }

printf 'ARGS:'
printf ' [%s]' "$@"
printf '\n'

# TODO tests
# TODO don't parse "-N123" as "-123" if "-N" is unknown?

parseopts() {
	arg=${arg#-}
	while [ "$arg" ]; do
		value=${arg#?} a=${arg%"$value"} opt_state=
		value=${value:-$opt}
		case "$a" in
			v) verbosity=$((verbosity+1)) ;;
			h) help=1 ;;
			n) number=$value; break ;;
			d) delim=$value; break ;;
			f) field=$value; break ;;
			[0-9]*) number=$arg; break ;;
			# *) echo "Unknown option $a!" >&2; exit 1; break ;; # TODO
		esac
		arg=$value
	done
}

parsevalue() { [ "$value" = "$arg" ] && value=$opt opt_state=skip; }

opt_state=
for arg; do
	shift
	[ "$opt_state" = end ] && { set -- "$@" "$arg"; continue; }

	value=${arg#*=} opt=$1
	case "$arg" in
		# end of options
		--) opt_state=end ;;
		# long args
		--help) help=1 ;;
		# long args with values
		--name*) parsevalue; name=$value ;;
		--age*) parsevalue; age=$value ;;
		# short args
		-?*) parseopts ;;
		*) [ "$opt_state" = skip ] || set -- "$@" "$arg"; opt_state= ;;
	esac
done

printf 'PARSED:'
printf ' [%s]' "$@"
printf '\n'

echo "help=$help"
echo "name=$name"
echo "age=$age"
echo "verbosity=$verbosity"
echo "number=$number"
echo "delimiter=$delim"
echo "field=$field"
