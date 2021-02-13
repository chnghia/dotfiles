#!/bin/sh

# Credits: http://stackoverflow.com/a/750191

git filter-branch -f --env-filter "
    GIT_AUTHOR_NAME='NghiaVFA'
    GIT_AUTHOR_EMAIL='vfa.nghiach@gmail.com'
    GIT_COMMITTER_NAME='nghiach'
    GIT_COMMITTER_EMAIL='chnghia@gmail.com'
  " HEAD
