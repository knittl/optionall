#!/bin/sh

printf 'ARGS:'
printf ' [%s]' "$@"
printf '\n'

# TODO tests
# TODO dynamic code gen to be eval'd?
# TODO static code gen?
# TODO let users handle end of options via callback?

is_function() {
	case "$(type -- "$1" 2>/dev/null)" in
		*function*) return 0 ;;
		*) return 1 ;;
	esac
}

is_function argument || argument() {
	arg=$1 value=$2 opt=$3 orig=$4
	printf '[%s] ' "a=$arg" "v=$value" "opt=$opt" "orig=$orig"
	printf '\n'
	case "$arg" in
		--name) name=$value; return 1 ;;
		--age) age=$value; return 1 ;;
		--help|-h) help=1; return 0 ;;
		-v) verbosity=$((verbosity+1)); return 0 ;;
		-d)
			case "$value" in
				?) delim=$value ;;
				*) echo 'delimiter must be a single char' ; exit 1 ;;
			esac
			return 1 ;;
		-f) field=$value; return 1 ;;
		-n) number=$value; return 1 ;;
		-[0-9]*) number=$value; return 0 ;;
		-?) echo "Invalid option $arg"; exit 1 ;;
		--*) echo "Invalid option $arg"; exit 1 ;;
		# *) return 1 ;;
	esac
}

parselong() {
	argument_handler=$1
	value=${arg#*=}
	case "$value" in
		"$arg") value=$next opt_state=skip ;;
	esac
	argname=${arg%%=*}
	opt=${arg#"$argname"}
	"$argument_handler" "$argname" "$value" "$arg" "${opt#=}" "$arg"
	case "$?" in
		0) opt_state= ;;
		*) ;;
	esac
}

parse_num() {
	# TODO support negative numbers?
	num=
	while [ "$1" ]; do
		tail=${1#?} head=${1%"$tail"}
		case "$head" in
			[0-9]) num=$num$head ;;
			*) break ;;
		esac
		set -- "$tail"
	done
}

parseshort() {
	argument_handler=$1
	orig=$arg
	arg=${arg#-}
	while [ "$arg" ]; do
		case "$arg" in
			[0-9]*)
				parse_num "$arg"
				value=$num a=$num opt=
				set -- "${arg#"$value"}"
				;;
			*)
				value=${arg#?} a=${arg%"$value"} opt=$value
				set -- "$value"
				test "$value" || value=$next opt_state=skip
				;;
		esac
		"$argument_handler" "-$a" "$value" "$opt" "$orig"
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

	case "$opt_state" in
		end) set -- "$@" "$arg"; continue ;;
		skip) opt_state=; continue ;;
	esac

	next=$1
	case "$arg" in
		# end of options
		--) opt_state=end ;;
		# long args (with values)
		--?*) parselong argument ;;
		# short args
		-?*) parseshort argument ;;
		# non-args
		*) set -- "$@" "$arg" ;;
	esac
done

optionall_parse() {
	parsed=$1
	unparsed=${2:-set}
	shift 2

	opt_state=
	for arg; do
		shift

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

alias optionall="eval '"'
opt_state=
for arg; do
	shift

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
'"'"

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
