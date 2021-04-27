# Meow
Meow is a small program created to help spawn multiple processes when developing. It is Bourne shell compliant and meant for Unix type systems. Meow was originally created to help with web development. Imagine the need to start a back-end, front-end, and cache server. Meow should make that easier.

<br>

### Need common gotcha section
- won't work for repl's. (things waiting for input)
- if your process exits for it's own reason and you have it set to expire it may look like it didn't work.

## Installation
1. Clone the stable branch with the following command.

```sh
git clone --single-branch --branch stable git@github.com:LoganBresnahan/meow.git
```

2. As the root user execute the `install.sh` script.

```sh
sudo ./meow/install.sh
```

3. Check the install.

```sh
meow --help
```

4. If the meow command is not executing try reseting your shell.

```sh
reset && meow --help
```

## Uninstall
Execute the meow uninstall command.

```sh
meow uninstall
```

## Usage
Meow reads from a `meow.txt` file that you have created within a specified directory. The structure and ordering of the lines added to the `meow.txt` file are important. Here is an example file with an explanation following.

```
bundle exec rails server
redis-server

cd ~/path/to/another/project
npx webpack serve
redis-server --port 4000
```

To have this `meow.txt` executed, run the following from within the same directory:

```sh
meow
```

In the example we are using Meow to start three processes in total and in two different terminal tabs. In the first tab we start a Rails server and a Redis server. The Rails server becomes the **boss process** for Meow. The boss process will always be the first process listed in the `meow.txt` file and is the process that exists in the foreground of your terminal tab. When the boss process dies all of the following processes will die and tabs opened by Meow will close unless configured not to (explained in more examples below). After the Rails and Redis commands we find a newline. A newline in the `meow.txt` file tells Meow that the next set of commands after the newline need to be run in a new terminal tab. In our example, the first line after the newline is `cd ~/path/to/another/project` this is telling Meow to change the working directory in the new tab and then run the listed commands. The first command in the new tab becomes the mini-boss of it's group which exists in the foreground of its new tab. If you kill this process then the following processes in its group will die (unless specified).

<br>

Next are some examples showing how we can keep specified processes alive using the `meow.txt` file. Further down are command line examples.

```
bundle exec rails server
redis-server

meow-live
cd ~/path/to/another/project
npx webpack serve
redis-server --port 4000
```
We've added `meow-live` to the top of the commands that run in a new tab. Now when the boss process, `bundle exec rails server` dies it won't kill anything in the 2nd tab.

<br>

Here is an even more detailed example for keeping individual processes alive.

```
bundle exec rails server
meow-live redis-server

meow-live
cd ~/path/to/another/project
npx webpack serve
meow-live redis-server --port 4000
```

In this scenario, when the user kills the boss process the second process in its group, `redis-server` will live because we've added `meow-live` infront of the command. As in the example before, we have `meow-live` as the first line for the second group so we know the boss process won't kill them. We have also added a `meow-live` to the second command in the group which means that when the mini-boss, `npx webpack serve` is killed it won't kill `redis-server --port 4000`.

## Command Line

We showed that you can execute the Meow program from the command line with:

```sh
meow
```

You can also specify which groups from the `meow.txt` file you would like to start. The following example will only start the first group.

```sh
meow 1
```

You can also specify from the command line groups you would like to start that won't get killed by the boss process. Note that if you add `live` to the first group `1` it will be ignored.

```sh
meow 1 2live
```

Finally, if you execute say only the 2nd group and tell it to `live` it will keep the terminal tab open after you kill the mini-boss.

```sh
meow 2live
```

## Cleanup

For each group listed in the `meow.txt` file we create a `meow-pids-N.txt` file. When boss and mini-boss processes are killed we read from the corresponding pid file and kill the listed processes which are denoted by their ID's. Sometimes when dealing with system processes we can get ourselves into trouble with ghost processes. If you're having issues when your commands execute, try running the cleanup process manually.

```sh
meow clean
```

This will go through all the `meow-pids-N.txt` files and attempt to kill the listed pids.

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
