#!/bin/sh

# Exits if an error occurs.
set -e

echo "Uninstalling Meow."
echo "Removing meow from /opt/meow"

rm -rf /opt/meow

echo "***IMPORTANT***"
echo "Meow uninstall complete. You can remove 'export PATH=\$PATH:/opt/meow/executable' from your shell's profile if you added it during Meow's installation."

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
