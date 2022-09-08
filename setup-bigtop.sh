#!/bin/bash
#
# setup-bigtop.sh downloads and prepares Bigtop build environment for Opensuse Leap 15
#

BT=bigtop-3.1.1
TDIR=/home/dist

#-------------------------------------------------------------------------------------

BTREL=${BT%.*} # bigtop-3.1
PATCH1=setup-${BTREL}-patch.diff
PATCH2=setup-${BT}-patch.diff
PATCH3=patch11-${BTREL}-ambari-vg.diff
PATCH4=patch11-${BTREL}-hadoop-tirpc-vg.diff
PDIR=$(pwd)

F=${BT}-project.tar.gz
URL=https://dlcdn.apache.org/bigtop/$BT/$F

echo "Download and prepare $BT ..."

echo -n "Enter target directory (default: $TDIR) : "
x="" # read x
[[ "$x" != "" ]] && TDIR=$x

export PATH=$PATH:/opt/puppetlabs/bin
which git > /dev/null 2>&1
[[ "$?" == "1" ]] && echo "Installing git ..." && sudo zypper in git

cd $TDIR
rm -rf ${BT} ${F}

wget -q $URL
[[ ! -f $F ]] && echo "ERROR: problems downloading $F : check URL : $URL" && exit 1

echo ">>> download complete, extracting/patching $BT ..."

tar xfz $F
D=$(echo $F | awk -F- '{print $1"-"$2}')
[[ ! -d $TDIR/$D ]] && echo "ERROR: problems unzipping $F" && exit 1

cd $TDIR/$D
[[ ! -f $PDIR/$PATCH1 ]] && PDIR=$(dirname $0)
for p in $(echo $PATCH1 $PATCH3 $PATCH4) ; do
  [[ ! -f $PDIR/$p ]] && echo "ERROR: patch $PDIR/$p not found" && exit 1
done

git apply $PDIR/$PATCH1
[[ -f $PDIR/$PATCH2 ]] && git apply $PDIR/$PATCH2
cp -a $PDIR/$PATCH3 ./bigtop-packages/src/common/ambari/
cp -a $PDIR/$PATCH4 ./bigtop-packages/src/common/hadoop/

which puppet > /dev/null 2>&1
[[ "$?" == "1" ]] && echo ">>> running puppetize ..." && sudo bigtop_toolchain/bin/puppetize.sh

echo -n ">>> Please ensure this returns NO RED MESSAGES! " #; read x
sudo puppet apply --modulepath=$TDIR/$D -e "include bigtop_toolchain::installer"

echo -n ">>> Please ensure this returns NO RED MESSAGES! " #; read x
sudo puppet apply --modulepath=$TDIR/$D -e "include bigtop_toolchain::development_tools"

echo "$BT prep is done."

