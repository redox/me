#!/bin/sh

PARNAME="11_BLOG"
if [ "x$1" != "x" ]; then
	PARNAME=$1
fi

DRIVE=~/gopath/bin/gdrive
PARID=`$DRIVE list -q "name = \"${PARNAME}\"" | grep -v ^Id | cut -d " " -f 1`

echo "PARID: $PARID"

$DRIVE list -q "'$PARID' in parents" | cat -n

echo "Enter ID of doc to convert:"
read ID

BASENAME=`$DRIVE info $ID | grep ^Name: | cut -d " " -f 2-`

(
	rm -rf _
	mkdir -p _
	cd _
	$DRIVE export $ID --mime application/vnd.openxmlformats-officedocument.wordprocessingml.document --force
	mv *.docx ../_.docx
	$DRIVE export $ID --mime text/plain --force
	mv *.txt ../_.txt
	cd ..
	rm -rf _
)

pandoc --track-changes=accept _.docx -o _.md

(mkdir -p _.r && cd _.r && unzip ../_.docx)
mkdir $BASENAME
mv _.r/word/media/* ${BASENAME}/
sed -i "" "s,media/image,${BASENAME}/image,g" _.md

sed -i "" 's,\\~,~,g' _.md	# unbackslash stuff
sed -i "" 's,\\',',g' _.md	# remove \`
sed -i "" 's,\[\*,\[,g' _.md	# [* -> [
sed -i "" 's,\*\],\],g' _.md	# *] -> ]
sed -i "" 's,```,\~\~\~,g' _.md	# my confusion
sed -i "" 's,gt;,>,g' _.md
sed -i "" 's,lt;,<,g' _.md

TITLE_CUR=`head -1 _.txt`
echo "Enter title [${TITLE_CUR}] <ENTER/custom title>"
read TITLE_ANSWER
if [ "x${TITLE_ANSWER}" = "x" ]; then
	TITLE=${TITLE_CUR}
	echo "# Empty date, assuming '${TITLE}'"
else
	echo "Give custom title:"
	read TITLE
fi


DATE_CUR=`date +%Y-%m-%d`
echo "Enter date: [${DATE_CUR}]"
read DATE_ANSWER

if [ "x${DATE_ANSWER}" = "x" ]; then
	DATE=${DATE_CUR}
	echo "# Empty date, assuming ${DATE}"
else
	echo "Give custom date"
	read DATE
fi


echo "Tags [a/b] a:"
read TAGS_ANSWER

TAGS="article"
if [ "x$TAGS_ANSWER" = "xb" ]; then
	TAGS="books"
fi

(
	echo "---"
	echo "title:	'$TITLE'"
	echo "tags:	$TAGS"
	echo "read:	$DATE"
	echo "published: true"
	echo "layout:	layout_book"
	echo "ads:"
	echo "- "
	echo "---"
	echo
	echo
	echo
	cat _.md
) > _.ready

if [ -f ${BASENAME} ]; then
	mv -f ${BASENAME}.md \
		${BASENAME}.md.bak.`head /dev/urandom | md5` 2>&1 >/dev/null
fi
mv -i _.ready ${BASENAME}.md

echo "# to edit"
echo
echo vim ${BASENAME}.md
echo
echo "# to move:"
echo
echo "mv ${BASENAME}.md ../source/blog/"
echo "mv ${BASENAME} ../source/img/"
