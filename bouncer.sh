#!/bin/bash
MAILDIR_BASE="/home/misp-bounce/Maildir"
MAILDIR_NEW="$MAILDIR_BASE/new"
MAILDIR_ARCHIVE="$MAILDIR_BASE/archive"

function isEmailValid() {
        regex="^(([A-Za-z0-9]+((\.|\-|\_|\+)?[A-Za-z0-9]?)*[A-Za-z0-9]+)|[A-Za-z0-9]+)@(([A-Za-z0-9]+)+((\.|\-|\_)?([A-Za-z0-9]+)+)*)+\.([A-Za-z]{2,})+$"
        [[ "${1}" =~ $regex ]]
}


for mail in `ls $MAILDIR_NEW`
do
        echo $mail:
        BOUNCE_ADDRESS_CANDIDATE=`cat $MAILDIR_NEW/$mail|grep Original-Recipient`
	CONTENT=`cat $MAILDIR_NEW/$mail`
        if [[ ! $BOUNCE_ADDRESS_CANDIDATE ]]
        then
                BOUNCE_ADDRESS_CANDIDATE=`cat $MAILDIR_NEW/$mail|grep Final-Recipient`
        fi
        BOUNCED=`echo $BOUNCE_ADDRESS_CANDIDATE| cut -d ";" -f 2`
        if isEmailValid "$BOUNCED"
        then
		if grep -L "$BOUNCED" /home/rommelfs/misp-bounce/bounced.txt
		then
                	echo "Disabling email address: $BOUNCED"
			/home/rommelfs/misp-bounce/bulk_modify_users.sh -d "$BOUNCED"
			if [[ $? -eq 0 ]]
			then
				echo -e "$BOUNCED got email delivery disabled in MISP after receiving the following bounce:\n$CONTENT" | mail -s "MISP bounce caught: $BOUNCED" info@circl.lu
			elif [[ $? -eq 1 ]]
			then
				echo -e "The following mail to $BOUNCED bounced:\n$CONTENT" | mail -s "Bounce caught: $BOUNCED" info@circl.lu
			fi
			echo "$BOUNCED" >> /home/rommelfs/misp-bounce/bounced.txt
        	else
                	echo "Nothing to be done - notification previously sent to RT"
        	fi
	fi
        echo "moving $mail to archive"
	mv "$MAILDIR_NEW/$mail" "$MAILDIR_ARCHIVE"
done
