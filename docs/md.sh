#!/bin/bash
#
cd ${0%\/*}

[ $# -ne 1 ] && exit 1

cp "UNI/Practica1-B/${1}" .
#rm -fr UNI
sed -i s'/..\/..\/_resources/_resources/g' "${1}"

#get rid of the jopin export header
sed -i '1,8d' "${1}"
#generate the toc
pandoc -s --toc --toc-depth=5 "${1}" -o out.md

mv out.md "${1}"
#get rid of #{balalalla} stuff on header
sed -i 's/{#.*}//g' "${1}"

#mkdir docs
