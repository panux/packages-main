sed -e '1   s/^/{"/' \
-e     's/$/",/' \
-e '2,$ s/^/"/'  \
-e   '$ d'       \
-i libmath.h

sed -e '$ s/$/0}/' \
-i libmath.h
