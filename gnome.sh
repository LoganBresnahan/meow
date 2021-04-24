# #!/bin/sh

# Enable jobs control.
set -m

GNOME_FILE_GROUP=0
GNOME_LIVE_OR_DIE=""
# echo $1
# echo $@
# echo $CONFIG_RELATIVE_DIRECTORY

# GET THE RELATIVE DIRECTORY FROM THE INCOMING ARGS AND THE EXPIRE OR ENDURE
# IF ENDURE THEN OUR TRAP HERE WILL KILL THE PROCESSES

# gnome_trap() {
#   # If we told this to originally live by the Boss process then we need to handle killing the processes in our meow-pids-N.txt file.
#   if [[ "$GNOME_LIVE_OR_DIE" = "live" ]]; then
#     LINE_NUMBER=0

#     # Reading the pids.txt file.
#     while read -r pid; do
#       # If the process is still alive then kill it.
#       if ps -p $pid > /dev/null; then
#         echo "$LINE_NUMBER. Killing  Process: $pid";
#         kill $pid;
#       else
#         echo "$LINE_NUMBER. Process Already Dead: $pid";
#       fi

#       LINE_NUMBER=$((LINE_NUMBER+1))
#     done < meow-pids-1.txt

#     # Erase the meow-pids-N.txt file.
#     truncate -s 0 meow-pids-1.txt
#   fi

#   echo "Process cleanup done from gnome.sh"
# }

# trap gnome_trap EXIT;

# GNOME_FILE_COMMAND_INDEX=0

# while read gnome_file_line_command; do
#   if [[ "$GNOME_FILE_COMMAND_INDEX" = 0 ]]; then
#     GNOME_FILE_GROUP=$gnome_file_line_command
#   elif [[ "$GNOME_FILE_COMMAND_INDEX" = 1 ]]; then
#     GNOME_LIVE_OR_DIE=$gnome_file_line_command
#   elif [[ "$GNOME_FILE_COMMAND_INDEX" = 2 ]]; then
#     if [[ "$gnome_file_line_command" = "cd "* ]]; then
#       # eval "${gnome_file_line_command}"
#       echo "${gnome_file_line_command}"
#     else
#       # eval "${gnome_file_line_command} &"
#       echo "${gnome_file_line_command} &"
#     fi
#   else
#     # eval "${gnome_file_line_command} &"
#     echo "${gnome_file_line_command} &"
#   fi

#   GNOME_FILE_COMMAND_INDEX=$((GNOME_FILE_COMMAND_INDEX + 1))
# done <<EOT
#     $(echo "$@" | sed -n 1'p' | tr '|' '\n')
# EOT


# echo meow-pids-${GNOME_FILE_GROUP}.txt
# I need to save the original directory and write this file to that
# jobs -p >>meow-pids-${GNOME_FILE_GROUP}.txt
# fg %1

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
