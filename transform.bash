#!/usr/bin/env bash
set -euo pipefail

jq -rs '
    [ "user_id", "name", "email", "phone" ],
    (
        .[] |
        .user_id as $id |
        .name as $name |
		#I treated phones the same way as emails.
		#They are iterated over seperately.
		#I noticed the phone numbers in the output.csv appeared to be int. I converted the numbers from strings to int. 
        # Iterate over emails, null for phone
        ( .emails[] | [ $id , $name , .   , null ] ),
        # Iterate over phones, null for email
        ( .phones[] | [ $id , $name , null , ( gsub("[^0-9]"; "") ) ] )
    )
    | @csv
' tests/input/users/*.json > $BUILD_DIR/users.csv


jq -rs '
	[ "user_id", "policy_number", "carrier", "policy_type", "effective_date", "expiration_date" ],
	(
		.[] | .[] |
			[
				.user_id,
				.policy_number,
				.carrier,
				.policy_type,
				.effective_date,
				.expiration_date
			]
	)
	| @csv
' tests/input/policies-by-user/*.json > $BUILD_DIR/policies.csv

#This was just a print statement
#echo "TODO xsv join" | tee $BUILD_DIR/user-policies.csv

#Here is the join between users and policies. 
#The Join is on user id
#I ensure the field order of the output is in the correct order
	#Note: there are duplicated user id fields. I had to purposfully preserve one as the output file had two as well.
#I sorted by policy number to get the same order as the output file. 

xsv join user_id $BUILD_DIR/users.csv user_id $BUILD_DIR/policies.csv | \
xsv select user_id,policy_number,carrier,policy_type,effective_date,expiration_date,user_id,name,email,phone | \
xsv sort -s policy_number > $BUILD_DIR/user-policies.csv

# xsv join user_id $BUILD_DIR/users.csv user_id $BUILD_DIR/policies.csv > $BUILD_DIR/user-policies.csv

#From everything I looked at, the table created is the same schema as output.csv
#This still fails the checkPhase in the nix build
#I looked at datatypes and they seem to match as well
#I look forward to see what I am missing. 
