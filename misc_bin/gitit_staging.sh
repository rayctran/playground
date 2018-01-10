#!/bin/sh -x

git clone git@bitbucket.org:lyonsconsultinggroup/ansible.git ~/ansible/dev/staging
cd ~/ansible/dev/staging
git fetch && git checkout staging
git status
