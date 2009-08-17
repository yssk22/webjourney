% Licensed under the Apache License, Version 2.0 (the "License"); you may not
% use this file except in compliance with the License.  You may obtain a copy of
% the License at
%
%   http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
% WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
% License for the specific language governing permissions and limitations under
% the License.

-module(couch_os_process).
-behaviour(gen_server).

-export([start_link/1, start_link/2, start_link/3, stop/1]).
-export([set_timeout/2, write/2, read/1, prompt/2, async/3]).
-export([writeline/2, readline/1, writejson/2, readjson/1]).
-export([init/1, terminate/2, handle_call/3, handle_cast/2, handle_info/2, code_change/3]).

-include("couch_db.hrl").

-define(PORT_OPTIONS, [stream, {line, 1024}, binary, exit_status, hide]).

-record(os_proc,
    {command,
     port,
     writer,
     reader,
     timeout
    }).

start_link(Command) ->
    start_link(Command, []).
start_link(Command, Options) ->
    start_link(Command, Options, ?PORT_OPTIONS).
start_link(Command, Options, PortOptions) ->
    gen_server:start_link(couch_os_process, [Command, Options, PortOptions], []).

stop(Pid) ->
    gen_server:cast(Pid, stop).

% Read/Write API
set_timeout(Pid, TimeOut) when is_integer(TimeOut) ->
    ok = gen_server:call(Pid, {set_timeout, TimeOut}).

write(Pid, Data) ->
    gen_server:call(Pid, {write, Data}).

read(Pid) ->
    gen_server:call(Pid, read).

prompt(Pid, Data) ->
    gen_server:call(Pid, {prompt, Data}, infinity).

async(Pid, Data, CallBack) ->
    gen_server:cast(Pid, {async, Data, CallBack}).

% Utility functions for reading and writing
% in custom functions
writeline(OsProc, Data) when is_record(OsProc, os_proc) ->
    port_command(OsProc#os_proc.port, Data ++ "\n").

readline(OsProc) when is_record(OsProc, os_proc) ->
    readline(OsProc, []).
readline(OsProc, Acc) when is_record(OsProc, os_proc) ->
    #os_proc{port=Port} = OsProc,
    receive
    {Port, {data, {noeol, Data}}} ->
        readline(OsProc, [Data|Acc]);
    {Port, {data, {eol, Data}}} ->
        lists:reverse(Acc, Data);
    {Port, Err} ->
        catch port_close(Port),
        throw({os_process_error, Err})
    after OsProc#os_proc.timeout ->
        catch port_close(Port),
        throw({os_process_error, "OS process timed out."})
    end.

% Standard JSON functions
writejson(OsProc, Data) when is_record(OsProc, os_proc) ->
    true = writeline(OsProc, ?JSON_ENCODE(Data)).

readjson(OsProc) when is_record(OsProc, os_proc) ->
    Line = readline(OsProc),
    case ?JSON_DECODE(Line) of
    {[{<<"log">>,Msg}]} when is_binary(Msg) ->
        % we got a message to log. Log it and continue
        ?LOG_INFO("OS Process Log Message: ~s", [Msg]),
        readjson(OsProc);
    {[{<<"error">>, Id}, {<<"reason">>, Reason}]} ->
        throw({list_to_atom(binary_to_list(Id)),Reason});
    {[{<<"reason">>, Reason}, {<<"error">>, Id}]} ->
        throw({list_to_atom(binary_to_list(Id)),Reason});
    Result ->
        Result
    end.

% gen_server API
init([Command, Options, PortOptions]) ->
    BaseTimeOut = list_to_integer(couch_config:get(
        "couchdb", "os_process_timeout", "5000")),
    BaseProc = #os_proc{
        command=Command,
        port=open_port({spawn, Command}, PortOptions),
        writer=fun writejson/2,
        reader=fun readjson/1,
        timeout=BaseTimeOut
    },
    OsProc =
    lists:foldl(fun(Opt, Proc) ->
        case Opt of
        {writer, Writer} when is_function(Writer) ->
            Proc#os_proc{writer=Writer};
        {reader, Reader} when is_function(Reader) ->
            Proc#os_proc{reader=Reader};
        {timeout, TimeOut} when is_integer(TimeOut) ->
            Proc#os_proc{timeout=TimeOut}
        end
    end, BaseProc, Options),
    {ok, OsProc}.

terminate(_Reason, #os_proc{port=nil}) ->
    ok;
terminate(_Reason, #os_proc{port=Port}) ->
    catch port_close(Port),
    ok.

handle_call({set_timeout, TimeOut}, _From, OsProc) ->
    {reply, ok, OsProc#os_proc{timeout=TimeOut}};
handle_call({write, Data}, _From, OsProc) ->
    Writer = OsProc#os_proc.writer,
    {reply, Writer(OsProc, Data), OsProc};
handle_call(read, _From, OsProc) ->
    Reader = OsProc#os_proc.reader,
    {reply, Reader(OsProc), OsProc};
handle_call({prompt, Data}, _From, OsProc) ->
    #os_proc{writer=Writer, reader=Reader} = OsProc,
    Writer(OsProc, Data),
    {reply, Reader(OsProc), OsProc}.

handle_cast({async, Data, CallBack}, OsProc) ->
    #os_proc{writer=Writer, reader=Reader} = OsProc,
    Writer(OsProc, Data),
    CallBack(Reader(OsProc)),
    {noreply, OsProc};
handle_cast(stop, OsProc) ->
    {stop, normal, OsProc};
handle_cast(Msg, OsProc) ->
    ?LOG_DEBUG("OS Proc: Unknown cast: ~p", [Msg]),
    {noreply, OsProc}.

handle_info({Port, {exit_status, Status}}, #os_proc{port=Port}=OsProc) ->
    ?LOG_ERROR("OS Process died with status: ~p", [Status]),
    {stop, {exit_status, Status}, OsProc};
handle_info(Msg, OsProc) ->
    ?LOG_DEBUG("OS Proc: Unknown info: ~p", [Msg]),
    {noreply, OsProc}.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

