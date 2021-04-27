# #!/bin/sh

# Enable jobs control.
set -m

# https://stackoverflow.com/questions/2172352/in-bash-how-can-i-check-if-a-string-begins-with-some-value#answer-18558871
linebeginswith() { case $2 in "$1"*) true;; *) false;; esac; }

# https://unix.stackexchange.com/questions/598036/how-to-check-if-variable-is-integer-avoid-problem-with-spaces-around-in-posix#answer-598047
is_integer () {
  case "${1#[+-]}" in
    (*[!0123456789]*) false ;;
    ('')              false ;;
    (*)               true ;;
  esac
}

kill_started_processes() {
  if [ "$TRAP_EXIT" = true ]; then
    while read saved_tab_group; do
      SAVED_TAB_GROUP_LINE_INDEX=0

      while read saved_tab_group_line; do
        if [ "$SAVED_TAB_GROUP_LINE_INDEX" = 0 ]; then
          PREVIOUS_SAVED_TAB_GROUP_LINE=$saved_tab_group_line
        elif [ "$SAVED_TAB_GROUP_LINE_INDEX" = 1 ]; then
          if [ "$saved_tab_group_line" = "expire" ] && [ -f "$CONFIG_RELATIVE_DIRECTORY/meow-pids-$PREVIOUS_SAVED_TAB_GROUP_LINE.txt" ]; then
            KILL_LINE_NUMBER=0

            while read -r pid; do
              # If the process is still alive then kill it.
              if ps -p $pid > /dev/null; then
                echo "$KILL_LINE_NUMBER. Killing  Process: $pid";
                kill $pid;
              else
                echo "$KILL_LINE_NUMBER. Process Already Dead: $pid";
              fi

              KILL_LINE_NUMBER=$((KILL_LINE_NUMBER + 1))
            done < $CONFIG_RELATIVE_DIRECTORY/meow-pids-$PREVIOUS_SAVED_TAB_GROUP_LINE.txt

            # Delete the meow-pids-N.txt file.
            rm $CONFIG_RELATIVE_DIRECTORY/meow-pids-$PREVIOUS_SAVED_TAB_GROUP_LINE.txt
            # truncate -s 0 $CONFIG_RELATIVE_DIRECTORY/meow-pids-$PREVIOUS_SAVED_TAB_GROUP_LINE.txt
            echo "Process cleanup done for meow-pids-${PREVIOUS_SAVED_TAB_GROUP_LINE}.txt"
          fi
        fi

        SAVED_TAB_GROUP_LINE_INDEX=$((SAVED_TAB_GROUP_LINE_INDEX + 1))
      done <<EOT
        `echo "$saved_tab_group" | sed -n 1'p' | tr '|' '\n'`
EOT
    done <<EOT
      `echo "$TAB_GROUPS" | sed -n 1'p' | tr ';' '\n'`
EOT
  fi

  if [ "$CONFIG_AUTO_CHECK_UPDATES" = true ]; then
    sh /opt/meow/update.sh
  fi
}

# Listens for CTRL-C input and calls kill_started_processes.
trap kill_started_processes EXIT

# For Mac's default Terminal application.
apple_terminal() {
  if [ "$TERM_PROGRAM" = "Apple_Terminal" ]; then
    echo "HI"
    osascript &>/dev/null <<EOF
      tell application "System Events" to keystroke "t" using {command down}
      tell application "Terminal" to do script "sh /opt/meow/apple_terminal.sh && exit" in front window
EOF
  else
    false
  fi
}

# For Mac's iTerm2.
iterm_terminal() {
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
gnome_terminal() {
  GNOME_COMMAND_INDEX=0
  GNOME_SHOULD_EXIT=""
  GNOME_WORKING_DIRECTORY=`pwd`

  while read gnome_line_command; do
    if [ "$GNOME_COMMAND_INDEX" = 1 ]; then
      if [ "$gnome_line_command" = "expire" ]; then
        GNOME_SHOULD_EXIT="exec"
      else
        GNOME_SHOULD_EXIT="sh"
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
    `echo "$@" | sed -n 1'p' | tr '|' '\n'`
EOT

  GNOME_ARGS="${CONFIG_RELATIVE_DIRECTORY}|${@}"
  GNOME_WORKING_DIRECTORY=`eval "echo $GNOME_WORKING_DIRECTORY"`

  # Check if Gnome Terminal is in use.
  if [ ! -z "$GNOME_TERMINAL_SERVICE" ]; then
    gnome-terminal --tab --title $GNOME_WORKING_DIRECTORY --working-directory $GNOME_WORKING_DIRECTORY -- $CONFIG_LINUX_SHELL -ic "$GNOME_SHOULD_EXIT /opt/meow/gnome_terminal.sh '${GNOME_ARGS}'; exec $CONFIG_LINUX_SHELL"
  else
    false
  fi
}

read_meow_txt_file() {
  # maybe clear the meow.txt file of spaces on the left and right
  # cat meow.txt | awk '{$1=$1};1'
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
      elif linebeginswith "auto-check-updates=" $line; then
        CONFIG_AUTO_CHECK_UPDATES="${line##*=}"
      # else
      #   # I think I need this continue if someone writes some random string because scripting won't just return nil if a condition is not met I think.
      #   continue
      fi

      continue
    fi

    if [ "$START_OF_COMMANDS" = true ]; then
      if linebeginswith "--end-commands" $line; then
        START_OF_COMMANDS=false
      elif [ "$FIRST_COMMAND" = true ]; then
        # This condition signifies we have reached the first command.
        TAB_GROUPS="${GROUP_NUMBER}|expire|${line}"
        FIRST_COMMAND=false
      elif linebeginswith "--new-tab" $line; then
        GROUP_NUMBER=$((GROUP_NUMBER + 1))

        if linebeginswith "--new-tab-endure" $line; then
          TAB_GROUPS="${TAB_GROUPS};${GROUP_NUMBER}|endure"
        else
          TAB_GROUPS="${TAB_GROUPS};${GROUP_NUMBER}|expire"
        fi
      else
        TAB_GROUPS="${TAB_GROUPS}|${line}"
      fi

      continue
    fi

  done < meow.txt
}

handle_command_line_args() {
  NEW_TAB_GROUPS=""
  SORTED_ARGS=`
    for i in $@; do
      if is_integer $1; then
        echo $i
      else
        continue
      fi
    done | sort -nu
  `

  if [ ! -z "$SORTED_ARGS" ]; then
    for command_line_arg in `eval echo $SORTED_ARGS`; do
      while read prepared_group; do
        PREPARED_GROUP_LINE_INDEX=0

        while read prepared_group_line; do
          # Index 0 represents the position of the original group number.
          if [ "$PREPARED_GROUP_LINE_INDEX" = 0 ]; then
            if [ "$prepared_group_line" = "$command_line_arg" ]; then
              if [ "$NEW_TAB_GROUPS" = "" ]; then
                NEW_TAB_GROUPS="${prepared_group}"
              else
                NEW_TAB_GROUPS="${NEW_TAB_GROUPS};${prepared_group}"
              fi
            fi
          fi

          PREPARED_GROUP_LINE_INDEX=$((PREPARED_GROUP_LINE_INDEX + 1))
        done <<EOT
          `echo "$prepared_group" | sed -n 1'p' | tr '|' '\n'`
EOT
      done <<EOT
        `echo "$TAB_GROUPS" | sed -n 1'p' | tr ';' '\n'`
EOT
    done

    TAB_GROUPS=$NEW_TAB_GROUPS
  else
    echo "*** Bad command line arguments: ${@}"
    echo ""
    cat /opt/meow/help.txt
    TRAP_EXIT=false
    exit 1
  fi
}

eval_commands() {
  BOSS_GROUP_STARTED=false

  while read group; do
    LINE_COMMAND_INDEX=0
    CURRENT_GROUP_IS_BOSS_GROUP=false

    while read line_command; do
      if [ "$LINE_COMMAND_INDEX" = 0 ] && [ "$line_command" = 0 ]; then
        BOSS_GROUP_STARTED=true
        CURRENT_GROUP_IS_BOSS_GROUP=true
      fi
      # All we need to do here is evaluate commands that occur after the "expire" argument for group 0.
      if [ "$CURRENT_GROUP_IS_BOSS_GROUP" = true ]; then
        if [ "$LINE_COMMAND_INDEX" -gt 1 ]; then
          # check for cd command and echo you can't do that.
          eval "${line_command} &"
        fi
      fi

      LINE_COMMAND_INDEX=$((LINE_COMMAND_INDEX + 1))
    done <<EOT
      `echo "$group" | sed -n 1'p' | tr '|' '\n'`
EOT

    if [ "$CURRENT_GROUP_IS_BOSS_GROUP" = true ]; then
      # This should always make meow-pids-0.txt
      jobs -p >>$CONFIG_RELATIVE_DIRECTORY/meow-pids-0.txt
    fi

    if [ "$CURRENT_GROUP_IS_BOSS_GROUP" = false ]; then
      apple_terminal $group || iterm_terminal $group || gnome_terminal $group &
    fi

# https://stackoverflow.com/questions/7718307/how-to-split-a-list-by-comma-not-space#answer-7718447
# https://stackoverflow.com/questions/16854280/a-variable-modified-inside-a-while-loop-is-not-remembered#answer-16855194
  done <<EOT
    `echo "$TAB_GROUPS" | sed -n 1'p' | tr ';' '\n'`
EOT

  # Tell the first command to come to the foreground.
  if [ "$BOSS_GROUP_STARTED" = true ]; then
    fg %1
  else
    TRAP_EXIT=false
  fi
}

if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
  cat /opt/meow/help.txt
elif [ "$1" = "clean" ]; then
  kill_started_processes
elif [ "$1" = "generate" ] || [ "$1" = "gen" ]; then
  sh /opt/meow/generate.sh `pwd`
elif [ "$1" = "update" ]; then
  sh /opt/meow/update.sh "user_initiated"
elif [ "$1" = "uninstall" ]; then
  sudo sh /opt/meow/uninstall.sh
else
  CONFIG_RELATIVE_DIRECTORY=`pwd`/tmp &&
  CONFIG_LINUX_SHELL=bash &&
  CONFIG_AUTO_CHECK_UPDATES=true &&
  TRAP_EXIT=true &&
  TAB_GROUPS="" &&
  read_meow_txt_file &&
  if [ ! $# -eq 0 ]; then
    handle_command_line_args $@
  else
    true
  fi &&
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
