#!/bin/bash
# -*- Mode:sh; indent-tabs-mode:nil; tab-width:4 -*-
#
# Copyright (C) 2015 Canonical Ltd
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 3 as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

set -e

run_test_plan(){
    TEST_PLAN=$1

    if [ -z "$SNAPCRAFT" ]; then
        export SNAPCRAFT=snapcraft
    fi

    # Create a temporary directory so that we can run 'manage.py develop' and
    # create the .provider file there
    temp_dir=$(mktemp -d)
    # Develop the provider, this will let us run tests on it
    ./manage.py develop -d $temp_dir
    # Set PROVIDERPATH (see plainbox(1)) so that we can see the provider
    # without installing it.
    export PROVIDERPATH=$PROVIDERPATH:$temp_dir
    # Run the test plan
    plainbox run \
             -T 2015.com.canonical.snapcraft::"$TEST_PLAN" \
             -f json -o $temp_dir/result.json
    # Analyze the result and fail if there are any failures
    python3 - << __PYTHON__
import json
with open("$temp_dir/result.json", "rt", encoding="utf-8") as stream:
    results = json.load(stream)
failed = False
for test_id, result in sorted(results['result_map'].items()):
    print('{0}: {1}'.format(test_id, result['outcome']))
    if result['outcome'] != 'pass':
        failed = True
print("Overall: {0}".format("fail" if failed else "pass"))
raise SystemExit(failed)
__PYTHON__
}

if [ -z "$1" ]; then
    echo "need test plan as first argument"
    exit 1
fi

run_test_plan "$@"
