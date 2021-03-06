#!/bin/sh

# Enable jobs control.
set -m

# Open file descriptor 9 read and write.
exec 9<> /dev/tty

# https://stackoverflow.com/questions/2172352/in-bash-how-can-i-check-if-a-string-begins-with-some-value#answer-18558871
applelinebeginswith() { case $2 in "$1"*) true;; *) false;; esac; }

apple_trap() {
  if [ -f "$APPLE_RELATIVE_DIRECTORY/meow-pids-$APPLE_GROUP.txt" ]; then
    APPLE_LINE_NUMBER=0

    while read -r apple_pid; do
      # If the process is still alive then kill it.
      if ps -p $apple_pid > /dev/null; then
        echo "$APPLE_LINE_NUMBER. Killing  Process: $apple_pid"
        kill -$APPLE_KILL_SIGNAL $apple_pid
      else
        echo "$APPLE_LINE_NUMBER. Process Already Dead: $apple_pid"
      fi

      APPLE_LINE_NUMBER=$((APPLE_LINE_NUMBER + 1))
    done < $APPLE_RELATIVE_DIRECTORY/meow-pids-$APPLE_GROUP.txt

    # Delete the meow-pids-N.txt file.
    rm $APPLE_RELATIVE_DIRECTORY/meow-pids-$APPLE_GROUP.txt &>/dev/null
    rmdir $APPLE_RELATIVE_DIRECTORY &>/dev/null

    echo "Process cleanup done for meow-pids-${APPLE_GROUP}.txt"
  fi

  # Close file descriptor 9.
  exec 9>&-
}

trap apple_trap EXIT

APPLE_GROUP=0
APPLE_FILE_INDEX=0
APPLE_RELATIVE_DIRECTORY=""
APPLE_KILL_SIGNAL=0

# dir,kill-signal,group-#,endure/expire,commands...
while read apple_file_line_command <&9; do
  if [ "$APPLE_FILE_INDEX" = 0 ]; then
    APPLE_RELATIVE_DIRECTORY=$apple_file_line_command
  elif [ "$APPLE_FILE_INDEX" = 1 ]; then
    APPLE_KILL_SIGNAL=$apple_file_line_command
  elif [ "$APPLE_FILE_INDEX" = 2 ]; then
    APPLE_GROUP=$apple_file_line_command
  elif [ "$APPLE_FILE_INDEX" -gt 3 ]; then
    if applelinebeginswith "-cd" $apple_file_line_command; then
      # Do nothing here.
      echo $apple_file_line_command > /dev/null
    else
      eval "${apple_file_line_command} &"
    fi
  fi

  APPLE_FILE_INDEX=$((APPLE_FILE_INDEX + 1))
done 9<<EOT
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
