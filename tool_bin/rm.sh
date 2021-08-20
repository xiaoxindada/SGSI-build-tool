LOCALDIR=`cd "$( dirname ${BASH_SOURCE[0]} )" && pwd`
cd $LOCALDIR

for i in $(ls $LOCALDIR);do
  [ ! -d $LOCALDIR/$i ] && continue
  if [ -f $LOCALDIR/$i/rm.sh ];then
    $LOCALDIR/$i/rm.sh
  fi
done

