
./lame-$1-$2/frontend/lame --quiet ./test.mp3 out.mp3
rc=$?
rm out.mp3;
exit $rc;

