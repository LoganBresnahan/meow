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
                echo "$KILL_LINE_NUMBER. Killing  Process: $pid"
                kill -$CONFIG_KILL_SIGNAL $pid
              else
                echo "$KILL_LINE_NUMBER. Process Already Dead: $pid"
              fi

              KILL_LINE_NUMBER=$((KILL_LINE_NUMBER + 1))
            done < $CONFIG_RELATIVE_DIRECTORY/meow-pids-$PREVIOUS_SAVED_TAB_GROUP_LINE.txt

            # Delete the meow-pids-N.txt file.
            rm $CONFIG_RELATIVE_DIRECTORY/meow-pids-$PREVIOUS_SAVED_TAB_GROUP_LINE.txt &>/dev/null

            echo "Process cleanup done for meow-pids-${PREVIOUS_SAVED_TAB_GROUP_LINE}.txt"
          fi
        fi

        SAVED_TAB_GROUP_LINE_INDEX=$((SAVED_TAB_GROUP_LINE_INDEX + 1))
      done <<EOT
        `echo "$saved_tab_group" | sed 's/<meow-c>/\n/g'`
EOT
    done <<EOT
      `echo "$TAB_GROUPS" | sed 's/<meow-g>/\n/g'`
EOT

    rmdir $CONFIG_RELATIVE_DIRECTORY &>/dev/null

    if [ "$CONFIG_AUTO_CHECK_UPDATES" = true ]; then
      sh /opt/meow/update.sh
    fi
  fi
}

trap kill_started_processes EXIT

# For Mac's default Terminal application.
apple_terminal() {
  if [ "$TERM_PROGRAM" = "Apple_Terminal" ]; then
    APPLE_COMMAND_INDEX=0
    APPLE_SHOULD_EXIT=""
    APPLE_WORKING_DIRECTORY=`pwd`

    while read apple_line_command; do
      if [ "$APPLE_COMMAND_INDEX" = 1 ]; then
        if [ "$apple_line_command" = "expire" ]; then
          APPLE_SHOULD_EXIT="exit"
        else
          APPLE_SHOULD_EXIT="true"
        fi
      elif [ "$APPLE_COMMAND_INDEX" -gt 1 ]; then
        if linebeginswith "-cd" $apple_line_command; then
          APPLE_WORKING_DIRECTORY="${apple_line_command##*cd}"
          # Nothing else to do with this while loop so break.
          break
        fi
      fi

      APPLE_COMMAND_INDEX=$((APPLE_COMMAND_INDEX + 1))
    done <<EOT
      `echo "$@" | sed 's/<meow-c>/\n/g'`
EOT

    APPLE_ARGS="${CONFIG_RELATIVE_DIRECTORY}<meow-c>${CONFIG_KILL_SIGNAL}<meow-c>${@}"

    osascript &>/dev/null <<EOF
      tell application "System Events" to keystroke "t" using {command down}
      tell application "Terminal" to do script "cd $APPLE_WORKING_DIRECTORY" in front window
      tell application "Terminal" to do script "sh /opt/meow/apple_tab.sh '${APPLE_ARGS}'" in front window
      tell application "Terminal" to do script "$APPLE_SHOULD_EXIT" in front window
EOF
  else
    false
  fi
}

# For Mac's iTerm2.
iterm_terminal() {
  if [ "$TERM_PROGRAM" = "iTerm.app" ]; then
    ITERM_COMMAND_INDEX=0
    ITERM_SHOULD_EXIT=""
    ITERM_WORKING_DIRECTORY=`pwd`

    while read iterm_line_command; do
      if [ "$ITERM_COMMAND_INDEX" = 1 ]; then
        if [ "$iterm_line_command" = "expire" ]; then
          ITERM_SHOULD_EXIT="exit"
        else
          ITERM_SHOULD_EXIT="true"
        fi
      elif [ "$ITERM_COMMAND_INDEX" -gt 1 ]; then
        if linebeginswith "-cd" $iterm_line_command; then
          ITERM_WORKING_DIRECTORY="${iterm_line_command##*cd}"
          # Nothing else to do with this while loop so break.
          break
        fi
      fi

      ITERM_COMMAND_INDEX=$((ITERM_COMMAND_INDEX + 1))
    done <<EOT
      `echo "$@" | sed 's/<meow-c>/\n/g'`
EOT

    ITERM_ARGS="${CONFIG_RELATIVE_DIRECTORY}<meow-c>${CONFIG_KILL_SIGNAL}<meow-c>${@}"

    osascript &>/dev/null <<EOF
      tell application "iTerm"
        activate
        tell current window to set tb to create tab with default profile
        tell current session of current window to write text "cd $ITERM_WORKING_DIRECTORY"
        tell current session of current window to write text "sh /opt/meow/apple_tab.sh '${ITERM_ARGS}'"
        tell current session of current window to write text "$ITERM_SHOULD_EXIT"
      end tell
EOF
  else
    false
  fi
}

# For Linux's Gnome Terminal.
gnome_terminal() {
  if [ ! -z "$GNOME_TERMINAL_SERVICE" ]; then
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
        if linebeginswith "-cd" $gnome_line_command; then
          GNOME_WORKING_DIRECTORY="${gnome_line_command##*cd}"
          # Nothing else to do with this while loop so break.
          break
        fi
      fi

      GNOME_COMMAND_INDEX=$((GNOME_COMMAND_INDEX + 1))
    done <<EOT
      `echo "$@" | sed 's/<meow-c>/\n/g'`
EOT

    GNOME_ARGS="${CONFIG_RELATIVE_DIRECTORY}<meow-c>${CONFIG_KILL_SIGNAL}<meow-c>${@}"
    GNOME_WORKING_DIRECTORY=`eval "echo $GNOME_WORKING_DIRECTORY"`

    gnome-terminal --tab --title $GNOME_WORKING_DIRECTORY --working-directory $GNOME_WORKING_DIRECTORY -- $CONFIG_UNIX_SHELL -ic "$GNOME_SHOULD_EXIT /opt/meow/gnome_tab.sh '${GNOME_ARGS}'; exec $CONFIG_UNIX_SHELL"
  else
    echo "No supported terminal found for spawning new tabs. The options include; Apple Terminal, iTerm2, and Gnome Terminal."
    false
  fi
}

read_meow_txt_file() {
  START_OF_CONFIG=false
  START_OF_COMMANDS=false
  FIRST_COMMAND=false
  GROUP_NUMBER=0

  while read -r line; do
    if linebeginswith "#" $line || [ -z "$line" ]; then
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
      elif linebeginswith "writable-relative-directory=" $line; then
        CONFIG_RELATIVE_DIRECTORY="${line##*=}"

        if [ ! -d "$CONFIG_RELATIVE_DIRECTORY" ]; then
          mkdir $CONFIG_RELATIVE_DIRECTORY
        fi

        CONFIG_RELATIVE_DIRECTORY=`pwd`/$CONFIG_RELATIVE_DIRECTORY
      elif linebeginswith "unix-shell=" $line; then
        # Variable is used in the gnome_terminal function.
        CONFIG_UNIX_SHELL="${line##*=}"
      elif linebeginswith "auto-check-updates=" $line; then
        CONFIG_AUTO_CHECK_UPDATES="${line##*=}"
      elif linebeginswith "apple-tab-spawn-delay=" $line; then
        CONFIG_APPLE_TAB_SPAWN_DELAY="${line##*=}"
      elif linebeginswith "kill-signal=" $line; then
        CONFIG_KILL_SIGNAL="${line##*=}"
      else
        echo "Invalid config line: ${line}"
        cat /opt/meow/help.txt
        TRAP_EXIT=false
        exit 1
      fi

      continue
    fi

    if [ "$START_OF_COMMANDS" = true ]; then
      if linebeginswith "--end-commands" $line; then
        START_OF_COMMANDS=false
      elif [ "$FIRST_COMMAND" = true ]; then
        # This condition signifies we have reached the first command.
        TAB_GROUPS="${GROUP_NUMBER}<meow-c>expire<meow-c>${line}"
        FIRST_COMMAND=false
      elif linebeginswith "--new-tab" $line; then
        GROUP_NUMBER=$((GROUP_NUMBER + 1))

        if linebeginswith "--new-tab-endure" $line; then
          TAB_GROUPS="${TAB_GROUPS}<meow-g>${GROUP_NUMBER}<meow-c>endure"
        else
          TAB_GROUPS="${TAB_GROUPS}<meow-g>${GROUP_NUMBER}<meow-c>expire"
        fi
      else
        TAB_GROUPS="${TAB_GROUPS}<meow-c>${line}"
      fi

      continue
    fi

  done < meow-config.txt
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
                NEW_TAB_GROUPS="${NEW_TAB_GROUPS}<meow-g>${prepared_group}"
              fi
            fi
          fi

          PREPARED_GROUP_LINE_INDEX=$((PREPARED_GROUP_LINE_INDEX + 1))
        done <<EOT
          `echo "$prepared_group" | sed 's/<meow-c>/\n/g'`
EOT
      done <<EOT
        `echo "$TAB_GROUPS" | sed 's/<meow-g>/\n/g'`
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
          if linebeginswith "-cd" $line_command; then
            echo "*** Cannot change directories for the boss group."
          else
            eval "${line_command} &"
          fi
        fi
      fi

      LINE_COMMAND_INDEX=$((LINE_COMMAND_INDEX + 1))
    done <<EOT
      `echo "$group" | sed 's/<meow-c>/\n/g'`
EOT

    if [ "$CURRENT_GROUP_IS_BOSS_GROUP" = true ]; then
      # This should always make meow-pids-0.txt
      jobs -p >>$CONFIG_RELATIVE_DIRECTORY/meow-pids-0.txt
    fi

    if [ "$CURRENT_GROUP_IS_BOSS_GROUP" = false ]; then
      apple_terminal $group || iterm_terminal $group || gnome_terminal $group &

      if [ "$TERM_PROGRAM" = "Apple_Terminal" ] || [ "$TERM_PROGRAM" = "iTerm.app" ]; then
        # This sleep is needed for the apple terminal. It gets confused when you run the osascript concurrently.
        sleep $CONFIG_APPLE_TAB_SPAWN_DELAY
      elif [ ! -z "$GNOME_TERMINAL_SERVICE" ]; then
        # This sleep keeps the tabs opening in the expected order.
        sleep 0.1
      fi
    fi

# https://stackoverflow.com/questions/7718307/how-to-split-a-list-by-comma-not-space#answer-7718447
# https://stackoverflow.com/questions/16854280/a-variable-modified-inside-a-while-loop-is-not-remembered#answer-16855194
  done <<EOT
    `echo "$TAB_GROUPS" | sed 's/<meow-g>/\n/g'`
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
elif [ "$1" = "generate" ] || [ "$1" = "gen" ]; then
  sh /opt/meow/generate.sh `pwd`
elif [ "$1" = "update" ]; then
  sh /opt/meow/update.sh "user_initiated"
elif [ "$1" = "uninstall" ]; then
  sudo sh /opt/meow/uninstall.sh
else
  CONFIG_RELATIVE_DIRECTORY=`pwd`/tmp &&
  CONFIG_UNIX_SHELL=bash &&
  CONFIG_AUTO_CHECK_UPDATES=true &&
  CONFIG_APPLE_TAB_SPAWN_DELAY=0.75 &&
  CONFIG_KILL_SIGNAL=15 &&
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
