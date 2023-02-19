set -a

TERM=xterm-256color
COLORTERM=truecolor
PATH=
LANG=C
PATH=/usr/lib64/ccache:/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin

function echofail() {
	echo
	echo "FAILED: $1"
	echo
	exit 1
}
