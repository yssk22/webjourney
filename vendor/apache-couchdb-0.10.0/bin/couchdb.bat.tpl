@echo off
rem Licensed under the Apache License, Version 2.0 (the "License"); you may not
rem use this file except in compliance with the License. You may obtain a copy
rem of the License at
rem
rem   http://www.apache.org/licenses/LICENSE-2.0
rem
rem Unless required by applicable law or agreed to in writing, software
rem distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
rem WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
rem License for the specific language governing permissions and limitations
rem under the License.

setlocal
rem First change to the erlang bin directory
cd %~dp0

rem Allow a different erlang executable (eg, werl) to be used.
if "%ERL%x" == "x" set ERL=erl.exe

echo CouchDB %version% - prepare to relax...
%ERL% -smp auto -sasl errlog_type error ^
      -eval "application:load(crypto)" ^
      -eval "application:load(couch)" ^
      -eval "crypto:start()" ^
      -eval "couch_server:start([""../etc/couchdb/default.ini"", ""../etc/couchdb/local.ini""]), receive done -> done end."