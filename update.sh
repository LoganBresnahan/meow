#!/bin/sh

# Exits if an error occurs.
set -e

if [ "$1" = "user_initiated" ]; then
  echo "Checking for an update."
fi

(cd /opt/meow/;
  CURRENT_BRANCH=`git rev-parse --abbrev-ref HEAD`

  if [ "$CURRENT_BRANCH" = "stable" ]; then
    git fetch origin stable &>/dev/null
    CURRENT_MEOW_VERSION=`git rev-parse HEAD`
    LATEST_MEOW_VERSION=`git rev-parse origin/stable`

    if [ "$CURRENT_MEOW_VERSION" != "$LATEST_MEOW_VERSION" ]; then
      while true; do
        read -p "New version of Meow found. Do you want to update? Yy|Nn > " yes_or_no
        case $yes_or_no in
          [Yy]* ) git fetch origin stable && git reset --hard FETCH_HEAD && git clean -df && echo "Update complete. See the latest release for potential breaking changes: https://github.com/LoganBresnahan/meow/releases" && break;;
          [Nn]* ) echo "Update cancelled." && break;;
          * ) echo "Yy|Nn";;
        esac
      done
    else
      if [ "$1" = "user_initiated" ]; then
        echo "You are already up-to-date."
      fi
    fi
  else
    echo "*** Cannot check for an update. You are not on the stable branch. Navigate to /opt/meow and run: git checkout stable && meow update"
  fi
)

# Copyright 2021 Logan Bresnahan

# This file is part of Meow.

# Meow is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# Meow is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with Meow. If not, see <https://www.gnu.org/licenses/>.
