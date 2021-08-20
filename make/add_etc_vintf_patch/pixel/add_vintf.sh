
LOCALDIR=`cd "$( dirname ${BASH_SOURCE[0]} )" && pwd`
cd $LOCALDIR

cat ./manifest >> $LOCALDIR/../manifest_custom
