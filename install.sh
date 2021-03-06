#!/bin/sh

# Exits if an error occurs.
set -e

if [ ! -d /opt/meow ]; then
  echo "Installing Meow."
  echo "Copying meow into /opt/meow"

  cp -a `pwd` /opt/meow

  echo "***IMPORTANT***"
  echo "Add 'export PATH=\$PATH:/opt/meow/executable' to your shell's profile then reload your shell and the installation will be complete."
  echo "If you have verified the installation you can remove the repository you have just cloned."
else
  echo "*** Meow already installed at /opt/meow"
  echo "If you need to update, run: meow update"
  echo "If you need to remove the old installation, run: meow uninstall"
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
