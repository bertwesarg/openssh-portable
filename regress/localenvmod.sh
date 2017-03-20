#	Placed in the Public Domain.

tid="localenvmod"

cp $OBJ/ssh_proxy $OBJ/ssh_proxy_bak
echo 'PermitLocalCommand yes' >>$OBJ/ssh_proxy_bak

cat <<EOI | sed -e 's/<SP>/ /g' >input
FOO=foo
FOO=<SP>foo
FOO<SP>=foo
FOO<SP>=<SP>foo
FOO=foo<SP>
FOO=<SP>foo<SP>
FOO<SP>=foo<SP>
FOO<SP>=<SP>foo<SP>
FOO="<SP>foo<SP>"
FOO=<SP>"<SP>foo<SP>"
FOO<SP>="<SP>foo<SP>"
FOO<SP>=<SP>"<SP>foo<SP>"
FOO="<SP>foo<SP>"<SP>
FOO=<SP>"<SP>foo<SP>"<SP>
FOO<SP>="<SP>foo<SP>"<SP>
FOO<SP>=<SP>"<SP>foo<SP>"
EOI

tid="localenvmod quoting"

cat <<EOE | sed -e 's/<SP>/ /g' >expect
foo
foo
foo
foo
foo
foo
foo
foo
<SP>foo<SP>
<SP>foo<SP>
<SP>foo<SP>
<SP>foo<SP>
<SP>foo<SP>
<SP>foo<SP>
<SP>foo<SP>
<SP>foo<SP>
EOE

verbose "test $tid"
exec 4>actual
while IFS= read mod; do
	trace "test $tid: <$mod>"
	(
		cat $OBJ/ssh_proxy_bak
		printf 'LocalCommand printf "%%%%s\\n" "$FOO"\n'
		printf "LocalEnvMod %s\n" "$mod"
	) >$OBJ/ssh_proxy
	${SSH} -n -F $OBJ/ssh_proxy somehost true >&4 || fail "$tid: <$mod>"
done <input
exec 4>&-

diff expect actual || fail "$tid"

cat >input <<EOI
FOO += foo
FOO %= foo
FOO +:= foo
FOO %:= foo
FOO + = foo
FOO % = foo
EOI

tid="localenvmod set (preset: unset)"

cat >expect <<EOE
foo
foo
foo
foo
foo
foo
EOE

verbose "test $tid"
exec 4>actual
while IFS= read mod; do
	trace "test $tid: <$mod>"
	(
		cat $OBJ/ssh_proxy_bak
		printf 'LocalCommand printf "%%%%s\\n" "$FOO"\n'
		printf "LocalEnvMod %s\n" "$mod"
	) >$OBJ/ssh_proxy
	${SSH} -n -F $OBJ/ssh_proxy somehost true >&4 || fail "$tid: <$mod>"
done <input
exec 4>&-

diff expect actual || fail "$tid"

tid="localenvmod set (preset: '')"

cat >expect <<EOE
foo
foo
foo
foo
foo
foo
EOE

verbose "test $tid"
exec 4>actual
while IFS= read mod; do
	trace "test $tid: <$mod>"
	(
		cat $OBJ/ssh_proxy_bak
		printf 'LocalCommand printf "%%%%s\\n" "$FOO"\n'
		printf "LocalEnvMod %s\n" "$mod"
	) >$OBJ/ssh_proxy
	FOO="" ${SSH} -n -F $OBJ/ssh_proxy somehost true >&4 || fail "$tid: <$mod>"
done <input
exec 4>&-

diff expect actual || fail "$tid"

tid="localenvmod set (preset: 'bar')"

cat >expect <<EOE
bar,foo
foo,bar
bar:foo
foo:bar
bar foo
foo bar
EOE

verbose "test $tid"
exec 4>actual
while IFS= read mod; do
	trace "test $tid: <$mod>"
	(
		cat $OBJ/ssh_proxy_bak
		printf 'LocalCommand printf "%%%%s\\n" "$FOO"\n'
		printf "LocalEnvMod %s\n" "$mod"
	) >$OBJ/ssh_proxy
	FOO=bar ${SSH} -n -F $OBJ/ssh_proxy somehost true >&4 || fail "$tid: <$mod>"
done <input
exec 4>&-

diff expect actual || fail "$tid"

tid="localenvmod unset"

cat >input <<EOI
FOO=
FOO=""
EOI

cat >expect <<EOE
true
true
EOE

verbose "test $tid"
exec 4>actual
while IFS= read mod; do
	trace "test $tid: <$mod>"
	(
		cat $OBJ/ssh_proxy_bak
		printf 'LocalCommand test "${FOO:+set}" = set || echo true\n'
		printf "LocalEnvMod %s\n" "$mod"
	) >$OBJ/ssh_proxy
	FOO=bar ${SSH} -n -F $OBJ/ssh_proxy somehost true >&4 || fail "$tid: <$mod>"
done <input
exec 4>&-

diff expect actual || fail "$tid"

tid="localenvmod commandline overwrites config file (change)"

cat >expect <<EOE
foo
EOE

verbose "test $tid"
(
	cat $OBJ/ssh_proxy_bak
	printf 'LocalCommand printf "%%%%s\\n" "$FOO"\n'
	printf "LocalEnvMod FOO=bar\n" "$mod"
) >$OBJ/ssh_proxy
${SSH} -n -F $OBJ/ssh_proxy -o"LocalEnvMod=FOO=foo" somehost true >actual || fail "$tid"

diff expect actual || fail "$tid"

tid="localenvmod commandline overwrites config file (unset)"

cat >expect <<EOE
true
EOE

verbose "test $tid"
(
	cat $OBJ/ssh_proxy_bak
	printf 'LocalCommand test "${FOO:+set}" = set || echo true\n'
	printf "LocalEnvMod FOO=bar\n" "$mod"
) >$OBJ/ssh_proxy
${SSH} -n -F $OBJ/ssh_proxy -o"LocalEnvMod=FOO=" somehost true >actual || fail "$tid"

diff expect actual || fail "$tid"

# reset tid
tid="localenvmod"
