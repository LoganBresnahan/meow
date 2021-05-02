# #!/bin/sh

# Enable jobs control.
set -m

# https://stackoverflow.com/questions/2172352/in-bash-how-can-i-check-if-a-string-begins-with-some-value#answer-18558871
applelinebeginswith() { case $2 in "$1"*) true;; *) false;; esac; }

apple_trap() {
  # When the Boss process kills the expire new tab processes we get a race condition.
  # It does not alter the functionality and error output is swallowed by /dev/null
  APPLE_LINE_NUMBER=0

  while read -r apple_pid; do
    # If the process is still alive then kill it.
    if ps -p $apple_pid > /dev/null; then
      echo "$APPLE_LINE_NUMBER. Killing  Process: $apple_pid"
      kill $apple_pid
    else
      echo "$APPLE_LINE_NUMBER. Process Already Dead: $apple_pid"
    fi

    APPLE_LINE_NUMBER=$((APPLE_LINE_NUMBER + 1))
  done < $APPLE_RELATIVE_DIRECTORY/meow-pids-$APPLE_GROUP.txt

  # Delete the meow-pids-N.txt file.
  rm $APPLE_RELATIVE_DIRECTORY/meow-pids-$APPLE_GROUP.txt &>/dev/null
  rmdir $APPLE_RELATIVE_DIRECTORY &>/dev/null

  echo "Process cleanup done for meow-pids-${APPLE_GROUP}.txt" && exit
}

trap apple_trap EXIT

APPLE_GROUP=0
APPLE_FILE_INDEX=0
APPLE_RELATIVE_DIRECTORY=""

while read apple_file_line_command; do
  if [ "$APPLE_FILE_INDEX" = 0 ]; then
    APPLE_RELATIVE_DIRECTORY=$apple_file_line_command
  elif [ "$APPLE_FILE_INDEX" = 1 ]; then
    APPLE_GROUP=$apple_file_line_command
  elif [ "$APPLE_FILE_INDEX" -gt 2 ]; then
    if applelinebeginswith "-cd" $apple_file_line_command; then
      # Do nothing here.
      echo $apple_file_line_command > /dev/null
    else
      eval "${apple_file_line_command} &"
    fi
  fi

  APPLE_FILE_INDEX=$((APPLE_FILE_INDEX + 1))
done <<EOT
  `echo "$@" | sed 's/<meow-c>/\n/g'`
EOT

jobs -p >>$APPLE_RELATIVE_DIRECTORY/meow-pids-${APPLE_GROUP}.txt
fg %1

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
