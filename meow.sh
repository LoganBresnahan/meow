# #!/bin/sh

# Enable jobs control.
set -m

# if [ "$1" = "clean" ]; then
#   kill_started_processes
# elif [ "$1" = "all" ]; then
#   # An argument of "all" will spawn c3po.
#   bundle exec rails s -p 5000 -e remote_development &
#   yarn run start:dev &
#   apple_terminal || iterm || gnome &
#   jobs -p >>tmp/pids.txt &&
#   fg bundle exec rails s -p 5000 -e remote_development
# else
#   bundle exec rails s -p 5000 -e remote_development &
#   yarn run start:dev &
#   jobs -p >>tmp/pids.txt &&
#   fg bundle exec rails s -p 5000 -e remote_development
# fi

# https://stackoverflow.com/questions/2172352/in-bash-how-can-i-check-if-a-string-begins-with-some-value#answer-18558871
linebeginswith() { case $2 in "$1"*) true;; *) false;; esac; }

kill_started_processes() {
  if [ "$TRAP_EXIT" = true ]; then
    while read saved_pid_groups; do
      KILL_LINE_NUMBER=0

      while read -r pid; do
        # If the process is still alive then kill it.
        if ps -p $pid > /dev/null; then
          echo "$KILL_LINE_NUMBER. Killing  Process: $pid";
          kill $pid;
        else
          echo "$KILL_LINE_NUMBER. Process Already Dead: $pid";
        fi

        KILL_LINE_NUMBER=$((KILL_LINE_NUMBER+1))
      done < $CONFIG_RELATIVE_DIRECTORY/meow-pids-$saved_pid_groups.txt

      # Erase the meow-pids-N.txt file.
      truncate -s 0 $CONFIG_RELATIVE_DIRECTORY/meow-pids-$saved_pid_groups.txt
      echo "Process cleanup done from meow.sh"
    done <<EOT
      $(echo "$PIDS_TO_KILL" | sed -n 1'p' | tr '|' '\n')
EOT
  fi
}

# Listens for CTRL-C input and calls kill_started_processes.
trap kill_started_processes EXIT

# For Mac's default Terminal application.
apple_terminal() {
  if [ "$TERM_PROGRAM" = "Apple_Terminal" ]; then
    false
#   osascript &>/dev/null <<EOF
#     tell application "System Events" to keystroke "t" using {command down}
#     tell application "Terminal" to do script "cd ~/code/c3po" in front window
#     tell application "Terminal" to do script "bundle exec rails server -p 3000 -e remote_development &" in front window
#     tell application "Terminal" to do script "yarn run start:dev &" in front window
#     tell application "Terminal" to do script "jobs -p >>~/code/membership_service/tmp/pids.txt &&" in front window
#     tell application "Terminal" to do script "fg bundle exec rails s -p 3000 -e remote_development && exit" in front window
# EOF
  else
    false
  fi
}

# For Mac's iTerm2.
iterm() {
  if [ "$TERM_PROGRAM" = "iTerm.app" ]; then
    false
#   osascript &>/dev/null <<EOF
#     tell application "iTerm"
#       activate
#       tell current window to set tb to create tab with default profile
#       tell current session of current window to write text "cd ~/code/c3po"
#       tell current session of current window to write text "bundle exec rails server -p 3000 -e remote_development &"
#       tell current session of current window to write text "yarn run start:dev &"
#       tell current session of current window to write text "jobs -p >>~/code/membership_service/tmp/pids.txt &&"
#       tell current session of current window to write text "fg bundle exec rails s -p 3000 -e remote_development && exit"
#     end tell
# EOF
  else
    false
  fi
}

# For Linux's Gnome Terminal.
gnome() {
  GNOME_COMMAND_INDEX=0
  GNOME_SHOULD_EXIT=""
  GNOME_WORKING_DIRECTORY=`pwd`

  while read gnome_line_command; do
    if [ "$GNOME_COMMAND_INDEX" = 1 ]; then
      if [ "$gnome_line_command" = "expire" ]; then
        GNOME_SHOULD_EXIT="exit"
      else
        GNOME_SHOULD_EXIT="echo 'endure' > /dev/null"
      fi
    elif [ "$GNOME_COMMAND_INDEX" -gt 1 ]; then
      if linebeginswith "cd" $gnome_line_command; then
        GNOME_WORKING_DIRECTORY="${gnome_line_command##*cd}"
        # Nothing else to do with this while loop so break.
        break
      fi
    fi

    GNOME_COMMAND_INDEX=$((GNOME_COMMAND_INDEX + 1))
  done <<EOT
    $(echo "$@" | sed -n 1'p' | tr '|' '\n')
EOT

  GNOME_ARGS="${CONFIG_RELATIVE_DIRECTORY}|${@}"
  GNOME_WORKING_DIRECTORY=`eval "echo $GNOME_WORKING_DIRECTORY"`

  # Check if Gnome Terminal is in use.
  if [ ! -z "$GNOME_TERMINAL_SERVICE" ]; then
    gnome-terminal --tab --working-directory $GNOME_WORKING_DIRECTORY -- $CONFIG_LINUX_SHELL -ic "sh /opt/meow/gnome.sh '${GNOME_ARGS}' && $GNOME_SHOULD_EXIT; exec $CONFIG_LINUX_SHELL"
    # gnome-terminal --tab --working-directory ~/code/c3po -- bash -ic 'bundle exec rails server -p 3000 -e remote_development & yarn run start:dev & jobs -p >>~/code/membership_service/tmp/pids.txt && fg bundle exec rails s -p 3000 -e remote_development && exit; exec bash'
  else
    false
  fi
}

# IF WE DO TAKE IN COMMAND LINE ARGS THEN WE CAN MATCH THEM TO THE GROUP NUMBER
read_meow_txt_file() {
  # maybe clear the meow.txt file of spaces on the left and right
  # cat meow.txt | awk '{$1=$1};1'
  # echo $@
  START_OF_CONFIG=false
  START_OF_COMMANDS=false
  FIRST_COMMAND=false
  GROUP_NUMBER=0

  while read -r line; do
    if linebeginswith "--comment" $line || [ -z "$line" ]; then
      # Ignore comments and empty lines.
      continue
    fi

    if linebeginswith "--start-config" $line; then
      START_OF_CONFIG=true && START_OF_COMMANDS=false && continue
    fi

    if linebeginswith "--start-commands" $line; then
      START_OF_COMMANDS=true && FIRST_COMMAND=true && START_OF_CONFIG=false && continue
    fi

    if [ "$START_OF_CONFIG" = true ]; then
      if linebeginswith "--end-config" $line; then
        START_OF_CONFIG=false
      elif linebeginswith "relative-directory=" $line; then
        CONFIG_RELATIVE_DIRECTORY="${line##*=}"

        if [ ! -d "$CONFIG_RELATIVE_DIRECTORY" ]; then
          mkdir $CONFIG_RELATIVE_DIRECTORY
        fi

        CONFIG_RELATIVE_DIRECTORY=`pwd`/$CONFIG_RELATIVE_DIRECTORY
      elif linebeginswith "linux-shell=" $line; then
        # Variable is used in the gnome function.
        CONFIG_LINUX_SHELL="${line##*=}"
      # else
      #   # I think I need this continue if someone writes some random string because scripting won't just return nil if a condition is not met I think.
      #   continue
      fi

      continue
    fi
    # SHOULD I ADD THE DIRECTORY AND LINUX SHELL TO THE GROUP STRING? THEN COMMANDS DO NEED TO BE BELOW CONFIG AND BREAK FROM --end-commands
    if [ "$START_OF_COMMANDS" = true ]; then
      if linebeginswith "--end-commands" $line; then
        START_OF_COMMANDS=false
        # We have reached the end of the commands. Use "break" to stop evaluating.
        # break
      elif [ "$FIRST_COMMAND" = true ]; then
        # This condition signifies we have reached the first command.
        TAB_GROUPS="${GROUP_NUMBER}|expire|${line}"
        PIDS_TO_KILL="${GROUP_NUMBER}"
        FIRST_COMMAND=false
      elif linebeginswith "--new-tab" $line; then
        GROUP_NUMBER=$((GROUP_NUMBER + 1))

        if linebeginswith "--new-tab-endure" $line; then
          TAB_GROUPS="${TAB_GROUPS};${GROUP_NUMBER}|endure"
        else
          TAB_GROUPS="${TAB_GROUPS};${GROUP_NUMBER}|expire"
          PIDS_TO_KILL="${PIDS_TO_KILL}|${GROUP_NUMBER}"
        fi
      else
        TAB_GROUPS="${TAB_GROUPS}|${line}"
      fi

      continue
    fi

  done < meow.txt
  echo $TAB_GROUPS
}

eval_commands() {
  GROUP_INDEX=0

  while read group; do
    if [ "$GROUP_INDEX" = 0 ]; then
      LINE_COMMAND_INDEX=0

      while read line_command; do
        # All we need to do here is evaluate commands that occur after the "expire" argument for group 0.
        if [ "$LINE_COMMAND_INDEX" -gt 1 ]; then
          eval "${line_command} &"
        fi

        LINE_COMMAND_INDEX=$((LINE_COMMAND_INDEX + 1))
      done <<EOT
      $(echo "$group" | sed -n 1'p' | tr '|' '\n')
EOT
      # This should always make meow-pids-0.txt
      jobs -p >>$CONFIG_RELATIVE_DIRECTORY/meow-pids-$GROUP_INDEX.txt
    else
      apple_terminal $group || iterm $group || gnome $group &
    fi

  GROUP_INDEX=$((GROUP_INDEX + 1))
# https://stackoverflow.com/questions/7718307/how-to-split-a-list-by-comma-not-space#answer-7718447
# https://stackoverflow.com/questions/16854280/a-variable-modified-inside-a-while-loop-is-not-remembered#answer-16855194
  done <<EOT
  $(echo "$TAB_GROUPS" | sed -n 1'p' | tr ';' '\n')
EOT

  # Tell the first command to come to the foreground.
  fg %1
}

# meow-live at top of group means that i should write the pids to a new file
# meow-live in front of a line means I should put something in front of the pid in the file but this is probably not possible and I won't do it.
# the clean process should ignore this and just kill the pid

# send ctrl-c process to the new tab as well
# think about memory mode to just pass command line commands.
# test current ctrl-c trap in membership_service

# meow command to generate a meow.txt file


#open a new tab and run script with arguments for if we need to kill all at once.

if [ "$1" = "--help" ]; then
  cat /opt/meow/help.txt
elif [ "$1" = "clean" ]; then
  kill_started_processes
elif [ "$1" = "generate" ]; then
  echo "Create meow.txt"
elif [ "$1" = "update" ]; then
  echo "Update"
elif [ "$1" = "uninstall" ]; then
  sudo sh /opt/meow/uninstall.sh
else
  CONFIG_RELATIVE_DIRECTORY=tmp &&
  CONFIG_LINUX_SHELL=bash &&
  TRAP_EXIT=true &&
  TAB_GROUPS="" &&
  PIDS_TO_KILL="" &&
  read_meow_txt_file && #$@
  eval_commands
fi



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
