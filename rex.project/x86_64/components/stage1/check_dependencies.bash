#!/bin/bash
# Simple script to list version numbers of critical development tools
export LC_ALL=C

echo
echo "Checking bash..."
bash --version | head -n1 | cut -d" " -f2-4

echo
echo "Checking /bin/sh path"
MYSH=$(readlink -f /bin/sh)
echo "/bin/sh -> $MYSH"
echo $MYSH | grep -q bash || echofail "/bin/sh does not point to bash"
unset MYSH

echo
echo "Checking binutils..."
echo -n "Binutils: "; ld --version | head -n1 | cut -d" " -f3-
bison --version | head -n1

echo
echo "Checking yacc..."
if [ -h /usr/bin/yacc ]; then
  echo "/usr/bin/yacc -> `readlink -f /usr/bin/yacc`";
elif [ -x /usr/bin/yacc ]; then
cat > /usr/bin/yacc << "EOF"
#!/bin/sh
# Begin /usr/bin/yacc

/usr/bin/bison -y $*

# End /usr/bin/yacc
EOF
chmod 755 /usr/bin/yacc
else
  echofail "yacc not found"
fi



echo
echo -n "Coreutils: "; chown --version | head -n1 | cut -d")" -f2
diff --version | head -n1
find --version | head -n1
gawk --version | head -n1

if [ -h /usr/bin/awk ]; then
  echo "/usr/bin/awk -> `readlink -f /usr/bin/awk`";
elif [ -x /usr/bin/awk ]; then
  echo awk is `/usr/bin/awk --version | head -n1`
else
  echofail "awk not found"
fi

echo
echo "Checking GCC..."
gcc --version | head -n1

echo
echo "Checking G++..."
g++ --version | head -n1

echo
echo "Checking grep..."
grep --version | head -n1

echo
echo "Checking gzip..."
gzip --version | head -n1

echo
echo "Checking /proc/version..."
cat /proc/version

echo
echo "Checking m4..."
m4 --version | head -n1

echo
echo "Checking make..."
make --version | head -n1

echo
echo "Checking patch..."
patch --version | head -n1

echo
echo "Checking perl..."
echo Perl `perl -V:version`

echo
echo "Checking python..."
python3 --version

echo
echo "Checking sed..."
sed --version | head -n1

echo
echo "Checking tar..."
tar --version | head -n1

echo
echo "Checking makeinfo..."
makeinfo --version | head -n1
retVal=${PIPESTATUS[0]}

if [ $retVal -ne 0 ]; then
	echofail "Could not check makeinfo version...(yum -y install texinfo)"
fi

echo
echo "Checking xz..."
xz --version | head -n1


pushd /tmp
rm -fv dummy*
echo
echo "Testing compiler..."
echo 'int main(){}' > dummy.c || echofail "failed to generate /tmp/dummy.c"
g++ -o dummy dummy.c || echofail "failed to compile /tmp/dummy.c"
./dummy || echofail "could not execute test program"

if [ -x dummy ];  then 
	rm -fv dummy*
	echo "g++ compilation OK"
else
	rm -fv dummy*
	echofail "g++ compilation failed"
fi


echo

