LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR

find ./ -type d -name '*' | xargs rm -rf > /dev/null 2>&1
rm -rf ./*.bak
rm -rf ./*.jar
