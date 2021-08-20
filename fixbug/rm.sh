LOCALDIR=`cd "$( dirname ${BASH_SOURCE[0]} )" && pwd`
cd $LOCALDIR

find ./ -type f -name '*.bak' | xargs rm -rf
find ./ -type d -name 'services.jar.out' | xargs rm -rf
