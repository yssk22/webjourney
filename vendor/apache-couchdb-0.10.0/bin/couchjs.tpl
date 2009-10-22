#! /bin/sh -e

# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.

SCRIPT_OK=0
SCRIPT_ERROR=1

DEFAULT_VERSION=170

basename=`basename $0`

display_version () {
    cat << EOF
$basename - %package_name% %version%

Licensed under the Apache License, Version 2.0 (the "License"); you may not use
this file except in compliance with the License. You may obtain a copy of the
License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied. See the License for the
specific language governing permissions and limitations under the License.
EOF
}

display_help () {
    cat << EOF
Usage: $basename [FILE]

The $basename command runs the %package_name% JavaScript interpreter.

The exit status is 0 for success or 1 for failure.

Options:

  -h  display a short help message and exit
  -V  display version information and exit

Report bugs at <%bug_uri%>.
EOF
}

display_error () {
    if test -n "$1"; then
        echo $1 >&2
    fi
    echo >&2
    echo "Try \`"$basename" -h' for more information." >&2
    exit $SCRIPT_ERROR
}

run_couchjs () {
    exec %locallibbindir%/%couchjs_command_name% $@
}

parse_script_option_list () {
    set +e
    options=`getopt hV $@`
    if test ! $? -eq 0; then
        display_error
    fi
    set -e
    eval set -- $options
    while [ $# -gt 0 ]; do
        case "$1" in
            -h) shift; display_help; exit $SCRIPT_OK;;
            -V) shift; display_version; exit $SCRIPT_OK;;
            --) shift; break;;
            *) break;;
        esac
    done
    option_list=`echo $@ | sed 's/--//'`
    if test -z "$option_list"; then
        display_error "You must specify a FILE."
    fi
    run_couchjs $option_list
}

parse_script_option_list $@
