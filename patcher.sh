#!/bin/bash

HEAD_NOW=''
HEAD_PREV=''

#<check internet>
#
#</check internet>

#<fetch updates> from github and show
function fetch_updates() {
UPDATES=$(git fetch && \
          comm --nocheck-order -3 \
          <(git log --all --pretty="%H")\
          <(git log --pretty="%H"))
git show -s --format=%B $UPDATES
}

fetch_updates



