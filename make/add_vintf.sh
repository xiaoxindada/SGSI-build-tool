
LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR

cat ./manifest >> $LOCALDIR/../manifest_custom
