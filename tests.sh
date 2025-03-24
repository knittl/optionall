#!/bin/sh

. ../format.sh/format.sh

assert_equals() {
	expected=$1
	actual=$2
	msg=$3
	if [ "$expected" != "$actual" ]; then
		failed=1
		echo "$(fmt red "✘ FAILED: $msg") -- '$expected' != '$actual'"
	else
		echo "$(fmt green ✔) SUCCESS: $msg"
	fi
}

assert_contains() {
	expected=$1
	actual=$output
	grep -Fx "$expected" <<-EOF >/dev/null
	$actual
	EOF
	if [ "$?" -ne 0 ]; then
		failed=1
		# printf '%s\n"*%s*"\n!=\n%s\n' "$(fmt red "✘ FAILED")" "$expected" "$actual"
		printf '%s: does not contain "%s"\n' "$(fmt red "✘ FAILED")" "$expected"
	fi

	# case "$actual" in
	# 	*$expected*) ;; #echo "$(fmt green ✔) SUCCESS: contains $expected" ;;
	# 	*)
	# 		failed=1
	# 		printf '%s\n"*%s*"\n!=\n%s\n' "$(fmt red "✘ FAILED")" "$expected" "$actual"
	# 		;;
	# esac
}

testing() {
	printf '%s ' "$(fmt bold "Testing $@")"
	testname=$@
	output=$(set -- "$@"; . ./optionall.sh 2>/dev/null)
}

tested() {
	if [ "$failed" ]; then
		echo "$(fmt red "✘ FAILED: $testname")"
	else
		echo "$(fmt green "✔ SUCCESS")"
	fi
}

(
	testing --name linus --age 42
	assert_contains 'name=linus'
	assert_contains 'age=42'
	tested
)

(
	testing --name linus --age=42
	assert_contains 'name=linus'
	assert_contains 'age=42'
	tested
)

(
	testing --name=linus --age 42
	assert_contains 'name=linus'
	assert_contains 'age=42'
	tested
)

(
	testing --name=linus --age=42
	assert_contains 'name=linus'
	assert_contains 'age=42'
	tested
)

(
	testing --help --name linus
	assert_contains 'help=1'
	assert_contains 'name=linus'
	tested
)

(
	testing -d: -f1,2
	assert_contains 'delimiter=:'
	assert_contains 'field=1,2'
	tested
)

(
	testing -v -vvv -vv
	assert_contains 'verbosity=6'
	tested
)

(
	testing -n5
	assert_contains 'number=5'
	tested
)

(
	testing -n 5
	assert_contains 'number=5'
	tested
)

(
	testing -n-5
	assert_contains 'number=-5'
	tested
)

(
	testing -n -5
	assert_contains 'number=-5'
	tested
)

(
	testing -1 2
	assert_contains 'number=1'
	tested
)

(
	testing -12 3
	assert_contains 'number=12'
	tested
)

(
	testing -1 --name=linus
	assert_contains 'number=1'
	assert_contains 'name=linus'
	tested
)

(
	argument() {
		case "$1" in --cool) echo 'awesome!' ;; esac
	}
	testing --cool 3>&1
	assert_contains 'awesome!'
	tested
)

(
	argument() {
		case "$1" in
			--cool) echo 'awesome!'; opt_state=;; # TODO
			--lame) echo 'oh no :(';;
		esac
	}
	testing --cool --lame 3>&1
	assert_contains 'awesome!'
	assert_contains 'oh no :('
	tested
)

(
	testing -13vv
	assert_contains 'number=13'
	assert_contains 'verbosity=2'
	tested
)

(
	testing -13 -vv
	assert_contains 'number=13'
	assert_contains 'verbosity=2'
	tested
)

(
	testing -n13vv
	assert_contains 'number=13vv'
	assert_contains 'verbosity='
	tested
)

(
	testing -n13 -vv
	assert_contains 'number=13'
	assert_contains 'verbosity=2'
	tested
)

(
	testing -n-13vv
	assert_contains 'number=-13vv'
	assert_contains 'verbosity='
	tested
)

(
	testing -n-13 -vv
	assert_contains 'number=-13'
	assert_contains 'verbosity=2'
	tested
)
