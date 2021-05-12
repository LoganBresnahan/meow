# Meow

Watch a demo here: https://loganbresnahan.github.io/

Meow is a small program created to help spawn and manage multiple foreground and background processes when developing. It should be Posix compliant and meant for Unix type systems. Meow was originally created to help with web development. Imagine the need to start a back-end, front-end, and cache server. Meow should make that easier.

Meow's main features:
1. Allow a single command to spawn and kill as many processes as desired.
2. Allow the user to spawn groups of processes in multiple other terminal tabs automatically.
3. Allow the user to give meow command line arguments to distinguish groups of processes that they would like to start.
4. Manage the spawned processes and terminal tabs so that you can have dependent processes expire when the lead process or group terminates.

Mentioned above, Meow should be Posix compliant so it should work on most Unix type systems. However, one of Meow's best features is the ability to spawn your processes in another terminal tab automatically. Supported terminal emulators for this functionality include,

- Apple Terminal
- iTerm2
- Gnome Terminal

If you're having trouble with Meow check out the Common Gotchas section below or open an issue.

<br>

## Installation
1. Clone the stable branch with the following command.

```sh
git clone --single-branch --branch stable git@github.com:LoganBresnahan/meow.git
```

2. Change directories into the newly cloned repository. You must do this for the install script to execute correctly.
```sh
cd meow/
```

3. As the root user execute the `install.sh` script.

```sh
sudo sh install.sh
```
3. Add Meow to your shell's PATH in your shell's profile file.
```sh
export PATH=$PATH:/opt/meow/executable
```

4. Reload your shell's profile and check the install.

```
meow --help
```

5. If the install was successful you can remove the repository that was just cloned.

<br>

## Usage
Inside of your desired directory you can use Meow's generate command to create a `meow-config.txt` file. This will copy the provided template and create the file at the root of your current directory. If you don't want the templated version you can create the file manually.
```sh
meow generate
```

Meow's `meow-config.txt` file is where you store all of the configuration and commands for Meow to run.

```
# Hi I'm a comment. I must start at the beginning of a line.

--start-config

writable-relative-directory=tmp
auto-check-updates=true
apple-tab-spawn-delay=0.75
unix-shell=bash
kill-signal=15

--end-config


--start-commands

bundle exec rails server
yarn start:dev

--new-tab-expire

-cd $HOME/my_project_two
mix run --no-halt
npx webpack --mode=development --watch=true

--new-tab-endure

redis-server

--end-commands

```

To execute Meow and run the commands listed in the `meow-config.txt`, just type:

```sh
meow
```

In this example we are using Meow to start five processes in total and in three different terminal tabs. These three tabs are treated as three distinct groups to Meow. In the first tab, in which we are executing Meow, we start a Rails server and a webpack server using Yarn. The Rails server becomes the **boss process** for Meow. The boss process will always be the first process listed in the `meow-config.txt` file and is the process that exists in the foreground of your terminal tab. When the boss process dies all of the following processes in its group will die.

After the boss group, we have another group distinguished by `--new-tab-expire` and another after that distiguished with `--new-tab-endure`. Processes in the tab configured to "expire" will die with the boss process AND the tab will close automatically. Processes in the tab configured with "endure" will continue to live even after the boss process has been terminated. When you terminate the tab set to endure it will manage cleaning up its processes. Likewise, for any tab set to expire, if you decide to terminate it early, it will manage cleaning up its processes as well. In the first new tab we see a `-cd` configuration. This tells Meow to change to the directory that you've provided. Note the use of `$HOME`, it's okay to use variables in the path but **DO NOT** use `~`. The tilda will not work. Finally, just like the boss group, the first command listed in your new tab will come to the foreground of your new tab and the rest will run in the background.

### Meow's Config Section for the meow-config.txt

Below are all of Meow's configuration options. If you are happy with the defaults you can remove the config section from your `meow-config.txt` if desired.

- `writable-relative-directory`: Defaults to `tmp`. A relative directory for Meow to temporarily create Meow pid files. If the directory doesn't exist, Meow will create it for you. If the directory is empty after Meow terminates, Meow will delete the directory.
- `auto-check-updates`: Defaults to `true`. When set to true, Meow will silently check for updates after Meow's boss group terminates.
- `apple-tab-spawn-delay`: Defaults to `0.75`. A short delay in seconds for Apple users so that Apple's osascript doesn't get confused when tabs are spawned concurrently. 0.75 should be read as three quarters of a second. Keep in mind, if the value is too short, you may see odd behavior when spawning multiple tabs.
- `unix-shell`: Defaults to `bash`. Your Unix shell. Used as an option when spawning your tabs in the Gnome Terminal emulator.
- `kill-signal`: Defaults to `15`. The signal to send the `kill` command that will kill your processes. 15 is the code for SIGTERM, generally treated as the default kill command on most systems.


### Command Line

We showed that you can execute the Meow program from the command line with:

```sh
meow
```

You can also specify which groups from the `meow-config.txt` file you would like to start. The following example will only start the first group. In keeping with a programmers paradigm, everything starts at 0.

```sh
meow 0
```

Here is an example showing we can skip a group as well. The command below will start the first group and the third group listed in your `meow-config.txt` file.

```sh
meow 0 2
```

You can also start groups without the boss group.
```sh
meow 1 2
```

<br>

## Uninstall
Execute the meow uninstall command.

```sh
meow uninstall
```

<br>

## Update
By default, Meow is configured to run a silent update check that will prompt you if there is an update available after Meow's boss group terminates. This is configurable in your `meow-config.txt` file. If you would like to check for an update manually, run the update command.

```sh
meow update
```

<br>

## Common Gotchas

- Meow utilizes GNU's `jobs`, `fg`, and `bg`. If your process can't be set to the background then it won't work with Meow.
- If your process exits for it's own reason, not caused by Meow, and you have its group set to expire it may look like the terminal tab closed too early. Make sure your commands are ready to be executed on your system before executing meow.
- Don't use a tilda `~` in the path when telling Meow to change directories for a new tab. It won't work.
- If you're using a Mac and your spawned tabs are not executing your commands correctly, try increasing the default `apple-tab-spawn-delay` option in the config section of your `meow-config.txt` file.

<br>
<br>

Copyright 2021 Logan Bresnahan

This file is part of Meow.

Meow is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Meow is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Meow. If not, see <https://www.gnu.org/licenses/>.
