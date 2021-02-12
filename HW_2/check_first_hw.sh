#!/bin/bash
RED="\e[31m"
GREEN="\e[32m"
CYAN="\e[96m"
RESET="\e[0m"

GIT_DIR=/tmp/linux_bc
NAME=unknown
SONAME=unknown
SYSTEM=unknown
USERNAME=unknown
GITHUB_NAME=unknown
TELEGRAM_NAME=unknown
EMAIL=unknown@unknown
BRANCH_NAME=unknown
TEST_FAILED=0
DEBUG_FILE=/tmp/hw_debug
TOKEN='ZjA0MDcwN2NmYjUwZWZiYzJhMjI5YzVhYzk4MjEzNDZlNzUyMjRhNQo='

SCORE=0

p_green() {
	format="$1"
	shift
	printf "${GREEN}${format}${RESET}" $@
}

p_red() {
	format="$1"
	shift
	printf "${RED}${format}${RESET}" $@
}

p_cyan() {
	format="$1"
	shift
	printf "${CYAN}${format}${RESET}" $@
}

get_info() {
	local correct
	local info

	while :; do
		printf "Please, enter your %s: " "$1"
		read info
		printf "Your %s is %s. Is it correct?(y/n): " "$1" "$info"
		read correct
		[ "$correct" = "y" ] && break
	done
	eval "$2=$info"
}

print_info() {
	date
	echo "Name:     $NAME"
	echo "Soname:   $SONAME"
	echo "System:   $SYSTEM"
	echo "Username: $USERNAME"
	echo "GITHUB:   $GITHUB_NAME"
	echo "TELEGRAM: $TELEGRAM_NAME"
	echo "BRANCH:   $BRANCH_NAME"
}

check_linux() {
	local system=$(uname)

	[ "$system" = "Linux" ] && return 0
	p_red "You should run this script on the Linux system!\n"
	TEST_FAILED=1
	return 1
}

check_ubuntu() {
	SYSTEM=$(uname -a | grep -o "[^~]*Ubuntu")

	[ "$SYSTEM" != "${SYSTEM/Ubuntu/}" ] && return 0
	p_red "This script is written for Ubuntu system! In case of any issues email to anatolii.tytarenko@globallogic.com\n"
	return 0
}

check_username() {
	local should_be=${NAME:0:1}

	USERNAME=$(whoami)
	should_be=${should_be,,*}
	should_be="${should_be}${SONAME,,*}"

	[ "$USERNAME" = "$should_be" ] && return 0
	p_red "Your username should be: %s!\n" $should_be
	return 1
}

check_sudo() {
	local groups=$(groups $(whoami))

	[ "$groups" != "${groups/ sudo/}" ] && return 0
	p_red "Your user doesn't have root privileges!\n"
	return 1
}

check_vim() {
	which vim > /dev/null && return 0
	p_red "You hadn't installed Vim to your system!\n"
	return 1
}

check_git() {
	which git > /dev/null && return 0
	p_red "You hadn't installed git to your system!\n"
	TEST_FAILED=1
	return 1
}

check_terminator() {
	which terminator > /dev/null && return 0
	p_red "You hadn't installed terminator to your system!\n"
	return 1
}

check_homedir() {
	local homedir="/home/$USERNAME"

	[ "$homedir" = "$(pwd)" ] && return 0
	p_red "Your current directory ($(pwd)) is not your home directory!\n"
	return 1
}

check_github() {
	local github_res=$(curl https://github.com/$GITHUB_NAME 2> /dev/null)

	[ "$github_res" != "Not Found" ] && return 0
	p_red "$GITHUB_NAME account cannot be found at github.com\n"
	p_red "Please, create your own accaunt at github.com. You need it to commit your future homework.\n"
	TEST_FAILED=1
	return 1
}

check_permissions() {
	local file_prev=$(ls -l $0 | cut -d' ' -f1)

	[ "$file_prev" = "-r-x------" ] && return 0
	p_red "This file should has only read and execute permissions for this user.\n"
	return 1
}

question_1() {
	local answer

	printf "\nWhat command may be used to determine current working directory?: "
	read answer
	[ "$answer" = "pwd" ] && return 0
	return 1
}

question_2() {
	local answer

	printf "\nWhat command may be used to change working directory?: "
	read answer
	[ "$answer" = "cd" ] && return 0
	return 1
}

question_3() {
	local answer

	printf "\nWhat command may be used to get current user name?: "
	read answer
	[ "$answer" = "whoami" ] && return 0
	return 1
}

question_4() {
	local answer

	printf "\nWhat command is used to change file permissions?: "
	read answer
	[ "$answer" = "chmod" ] && return 0
	return 1
}

question_5() {
	local answer

	printf "\nWhat command is used to change file ownership?: "
	read answer
	[ "$answer" = "chown" ] && return 0
	return 1
}

question_6() {
	local answer

	printf "\nWhat argument should be used, to get usage for most Linux commands?: "
	read answer
	[ "$answer" = "--help" ] && return 0
	return 1
}

TESTS="check_linux check_ubuntu check_username check_sudo check_vim \
       check_git check_terminator check_homedir check_github check_permissions \
       question_1 question_2 question_3 question_4 question_5 question_6"

p_cyan "Starting to check your homework #1!\n"
printf "Note: You could stop this script at any moment by pressing Ctrl+c\n"

get_info name NAME
get_info soname SONAME
get_info 'telegram name' TELEGRAM_NAME
get_info 'github nickname' GITHUB_NAME
get_info 'email' EMAIL
BRANCH_NAME=${NAME,,*}.${SONAME,,*}
echo Nice to meet you $NAME $SONAME

nbr=0
for test in $TESTS; do
	nbr=$(($nbr + 1))
	printf "Running Test #%2d [%20s]: " $nbr $test
	eval "$test"
	if [ $? -eq 0 ]; then
		p_green "Passed\n"
		SCORE=$(($SCORE + 1))
	else
		p_red "Test #%d is failed!\n" $nbr
	fi
	sleep 1
	[ $TEST_FAILED -eq 1 ] && {
		p_red "You've failed test, fix your mistakes and try again!\n"
		exit
	}
done

p_cyan "Your evaluation is finished! You\'ve got %d from %d points.\n" $SCORE $nbr
p_cyan "Please, check the following information and try one more time if something is incorrect:\n"
print_info
printf "Would you like to commit information about yourself and your results?(y/n): "
read answer
[ "$answer" != "y" ] && p_red "Exiting. Goodbye, dear $NAME $SONAME!\n" && exit

#This tokken provides admin access to repository. Please, don't use it for any purposes.
git clone https://anatolii-tytarenko:$(echo $TOKEN | openssl enc -base64 -d)@github.com/anatolii-tytarenko/Linux_basecamp.git $GIT_DIR
[ -d $GIT_DIR ] || {
	p_red "Error while cloning repository! Check your Internet access and repository.\n"
	exit 1
}

cd $GIT_DIR


git checkout $BRANCH_NAME 2> /dev/null || {
	git branch $BRANCH_NAME
	git checkout $BRANCH_NAME
}

print_info > student_profile
mkdir HW_1 2> /dev/null
echo "Score: $SCORE from $nbr" > ./HW_1/results
{
	pwd
	ls -l
	git status
} &> $DEBUG_FILE
git_uname=$(git config user.name)
[ -z "$git_uname" ] && git config --global user.name "$NAME $SONAME"
git_email=$(git config user.email)
[ -z "$git_email" ] && git config --global user.email "$EMAIL"

git add * || p_red "Error while adding changed files to commit\n"
git status &>> $DEBUG_FILE
git commit -m "$NAME $SONAME: Homework #1" &>> $DEBUG_FILE || p_red "Error while commiting\n"
git branch &>> $DEBUG_FILE
git log &>> $DEBUG_FILE
git push origin $BRANCH_NAME &>> $DEBUG_FILE

if [ $? -eq 0 ]; then
	p_green "Your information has been successfully pushed to your personal branch $BRANCH_NAME in the following repository:\n"
	p_green "https://github.com/anatolii-tytarenko/Linux_basecamp.git\n"
else
	p_red "Something went wrong...\n"
fi
cd ~
rm -rf $GIT_DIR
