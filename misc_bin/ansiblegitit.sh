#!/bin/sh -x

if [ "$#" -lt 1 ]
then
    echo
    echo "USAGE: ansiblegitit.sh -b|--branch <BRANCH NAME> -d|--directory <TARGET DIRECTORY>"
    echo
    exit 1
fi
while [ $# -gt 0 ]; do
    case $1 in
        -b | --branch )         shift
                                BRANCH="$1"
				shift
                                ;;
        -d | --directory )      shift 
                                DIRECTORY="$1"
				shift
                                ;;
    esac
done

git clone git@bitbucket.org:lyonsconsultinggroup/ansible.git $DIRECTORY
cd $DIRECTORY
git fetch && git checkout $BRANCH
git status
