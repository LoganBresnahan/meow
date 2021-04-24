# #!/bin/sh

# Enable jobs control.
set -m

# https://stackoverflow.com/questions/2172352/in-bash-how-can-i-check-if-a-string-begins-with-some-value#answer-18558871
gnomelinebeginswith() { case $2 in "$1"*) true;; *) false;; esac; }

gnome_trap() {
  GNOME_LINE_NUMBER=0

  # Reading the pids.txt file.
  while read -r gnome_pid; do
    # If the process is still alive then kill it.
    if ps -p $gnome_pid > /dev/null; then
      echo "$GNOME_LINE_NUMBER. Killing  Process: $gnome_pid";
      kill $gnome_pid;
    else
      echo "$GNOME_LINE_NUMBER. Process Already Dead: $gnome_pid";
    fi

    GNOME_LINE_NUMBER=$((GNOME_LINE_NUMBER+1))
  done < $GNOME_RELATIVE_DIRECTORY/meow-pids-$GNOME_GROUP.txt

  # Erase the meow-pids-N.txt file.
  truncate -s 0 $GNOME_RELATIVE_DIRECTORY/meow-pids-$GNOME_GROUP.txt

  echo "Process cleanup done for meow-pids-${GNOME_GROUP}.txt"
}

trap gnome_trap EXIT

GNOME_GROUP=0
GNOME_FILE_INDEX=0
GNOME_RELATIVE_DIRECTORY=""

while read gnome_file_line_command; do
  if [ "$GNOME_FILE_INDEX" = 0 ]; then
    GNOME_RELATIVE_DIRECTORY=$gnome_file_line_command
  elif [ "$GNOME_FILE_INDEX" = 1 ]; then
    GNOME_GROUP=$gnome_file_line_command
  elif [ "$GNOME_FILE_INDEX" -gt 2 ]; then
    if gnomelinebeginswith "cd" $gnome_file_line_command; then
      # Do nothing here.
      echo $gnome_file_line_command > /dev/null
    else
      eval "${gnome_file_line_command} &"
    fi
  fi

  GNOME_FILE_INDEX=$((GNOME_FILE_INDEX + 1))
done <<EOT
    $(echo "$@" | sed -n 1'p' | tr '|' '\n')
EOT

jobs -p >>$GNOME_RELATIVE_DIRECTORY/meow-pids-${GNOME_GROUP}.txt
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
