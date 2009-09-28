% Licensed under the Apache License, Version 2.0 (the "License"); you may not
% use this file except in compliance with the License. You may obtain a copy of
% the License at
%
%   http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
% WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
% License for the specific language governing permissions and limitations under
% the License.

-module(couch_stats_aggregator).
-include("couch_stats.hrl").

-behaviour(gen_server).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
        terminate/2, code_change/3]).

-export([start/0, stop/0,
         get/1, get/2, get_json/1, get_json/2, all/0,
         time_passed/0, clear_aggregates/1]).

-record(state, {
    aggregates = [],
    descriptions = []
}).

-define(COLLECTOR, couch_stats_collector).
-define(QUEUE_MAX_LENGTH, 900). % maximimum number of seconds

% PUBLIC API

start() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

stop() ->
    gen_server:call(?MODULE, stop).

get(Key) ->
    gen_server:call(?MODULE, {get, Key}).
get(Key, Time) ->
    gen_server:call(?MODULE, {get, Key, Time}).

get_json(Key) ->
    gen_server:call(?MODULE, {get_json, Key}).
get_json(Key, Time) ->
    gen_server:call(?MODULE, {get_json, Key, Time}).

time_passed() ->
    gen_server:call(?MODULE, time_passed).

clear_aggregates(Time) ->
    gen_server:call(?MODULE, {clear_aggregates, Time}).

all() ->
    gen_server:call(?MODULE, all).

% GEN_SERVER

init(_) ->
    ets:new(?MODULE, [named_table, set, protected]),
    init_timers(),
    init_descriptions(),
    {ok, #state{}}.

handle_call({get, Key}, _, State) ->
    Value = get_aggregate(Key, State),
    {reply, Value, State};

handle_call({get, Key, Time}, _, State) ->
    Value = get_aggregate(Key, State, Time),
    {reply, Value, State};

handle_call({get_json, Key}, _, State) ->
    Value = aggregate_to_json_term(get_aggregate(Key, State)),
    {reply, Value, State};

handle_call({get_json, Key, Time}, _, State) ->
    Value = aggregate_to_json_term(get_aggregate(Key, State, Time)),
    {reply, Value, State};

handle_call(time_passed, _, OldState) ->

    % the foldls below could probably be refactored into a less code-duping form

    % update aggregates on incremental counters
    NextState = lists:foldl(fun(Counter, State) ->
        {Key, Value} = Counter,
        update_aggregates_loop(Key, Value, State, incremental)
    end, OldState, ?COLLECTOR:all(incremental)),

    % update aggregates on absolute value counters
    NewState = lists:foldl(fun(Counter, State) ->
        {Key, Value} = Counter,
        % clear the counter, we've got the important bits in State
        ?COLLECTOR:clear(Key),
        update_aggregates_loop(Key, Value, State, absolute)
    end, NextState, ?COLLECTOR:all(absolute)),

    {reply, ok, NewState};

handle_call({clear_aggregates, Time}, _, State) ->
    {reply, ok, do_clear_aggregates(Time, State)};

handle_call(all, _ , State) ->
    Results = do_get_all(State),
    {reply, Results, State};

handle_call(stop, _, State) ->
    {stop, normal, stopped, State}.


% PRIVATE API

% Stats = [{Key, TimesProplist}]
% TimesProplist = [{Time, Aggrgates}]
% Aggregates = #aggregates{}
%
% [
%  {Key, [
%             {TimeA, #aggregates{}},
%             {TimeB, #aggregates{}},
%             {TimeC, #aggregates{}},
%             {TimeD, #aggregates{}}
%        ]
%  },
%
% ]

%% clear the aggregats record for a specific Time = 60 | 300 | 900
do_clear_aggregates(Time, #state{aggregates=Stats}) ->
    NewStats = lists:map(fun({Key, TimesProplist}) ->
        {Key, case proplists:lookup(Time, TimesProplist) of
            % do have stats for this key, if we don't, return Stat unmodified
            none ->
                TimesProplist;
            % there are stats, let's unset the Time one
            {_Time, _Stat} ->
                [{Time, #aggregates{}} | proplists:delete(Time, TimesProplist)]
        end}
    end, Stats),
    #state{aggregates=NewStats}.

get_aggregate(Key, State) ->
    %% default Time is 0, which is when CouchDB started
    get_aggregate(Key, State, '0').
get_aggregate(Key, #state{aggregates=StatsList}, Time) ->
    Description = get_description(Key),
    Aggregates = case proplists:lookup(Key, StatsList) of
        % if we don't have any data here, return an empty record
        none -> #aggregates{description=Description};
        {Key, Stats} ->
            case proplists:lookup(Time, Stats) of
                none -> #aggregates{description=Description}; % empty record again
                {Time, Stat} -> Stat#aggregates{description=Description}
            end
    end,
    Aggregates.

get_description(Key) ->
    case ets:lookup(?MODULE, Key) of
        [] -> <<"No description yet.">>;
        [{_Key, Description}] -> Description
    end.

%% updates all aggregates for Key
update_aggregates_loop(Key, Values, State, CounterType) ->
    #state{aggregates=AllStats} = State,
    % if we don't have any aggregates yet, put a list of empty atoms in
    % so we can loop over them in update_aggregates().
    % [{{httpd,requests},
    %              [{'0',{aggregates,1,1,1,0,0,1,1}},
    %               {'60',{aggregates,1,1,1,0,0,1,1}},
    %               {'300',{aggregates,1,1,1,0,0,1,1}},
    %               {'900',{aggregates,1,1,1,0,0,1,1}}]}]
    [{_Key, StatsList}] = case proplists:lookup(Key, AllStats) of
        none -> [{Key, [
                {'0', empty},
                {'60', empty},
                {'300', empty},
                {'900', empty}
             ]}];
        AllStatsMatch ->
        [AllStatsMatch]
    end,

    % if we  get called with a single value, wrap in in a list
    ValuesList = case is_list(Values) of
        false -> [Values];
        _True -> Values
    end,

    % loop over all Time's
    NewStats = lists:map(fun({Time, Stats}) ->
        % loop over all values for Key
        lists:foldl(fun(Value, Stat) ->
            {Time, update_aggregates(Value, Stat, CounterType)}
        end, Stats, ValuesList)
    end, StatsList),

    % put the newly calculated aggregates into State and delete the previous
    % entry
    #state{
        aggregates=[{Key, NewStats} | proplists:delete(Key, AllStats)]
    }.

% does the actual updating of the aggregate record
update_aggregates(Value, Stat, CounterType) ->
    case Stat of
        % the first time this is called, we don't have to calculate anything
        % we just populate the record with Value
        empty -> #aggregates{
            min=Value,
            max=Value,
            mean=Value,
            variance=0,
            stddev=0,
            count=1,
            current=Value
        };
        % this sure could look nicer -- any ideas?
        StatsRecord ->
            #aggregates{
                min=Min,
                max=Max,
                mean=Mean,
                variance=Variance,
                count=Count,
                current=Current
            } = StatsRecord,

            % incremental counters need to keep track of the last update's value
            NewValue = case CounterType of
                incremental -> Value - Current;
                absolute -> Value
            end,
                % Knuth, The Art of Computer Programming, vol. 2, p. 232.
                NewCount = Count + 1,
                NewMean = Mean + (NewValue - Mean) / NewCount, % NewCount is never 0.
                NewVariance = Variance + (NewValue - Mean) * (NewValue - NewMean),
                #aggregates{
                    min=lists:min([NewValue, Min]),
                    max=lists:max([NewValue, Max]),
                    mean=NewMean,
                    variance=NewVariance,
                    stddev=math:sqrt(NewVariance / NewCount),
                    count=NewCount,
                    current=Value
                }
    end.


aggregate_to_json_term(#aggregates{min=Min,max=Max,mean=Mean,stddev=Stddev,count=Count,current=Current,description=Description}) ->
    {[
        {current, Current},
        {count, Count},
        {mean, Mean},
        {min, Min},
        {max, Max},
        {stddev, Stddev},
        {description, Description}
    ]}.

get_stats(Key, State) ->
    aggregate_to_json_term(get_aggregate(Key, State)).

% convert ets2list() list into JSON-erlang-terms.
% Thanks to Paul Davis
do_get_all(#state{aggregates=Stats}=State) ->
    case Stats of
        [] -> {[]};
        _ ->
        [{LastMod, LastVals} | LastRestMods] = lists:foldl(fun({{Module, Key}, _Count}, AccIn) ->
              case AccIn of
                  [] ->
                      [{Module, [{Key, get_stats({Module, Key}, State)}]}];
                  [{Module, PrevVals} | RestMods] ->
                      [{Module, [{Key, get_stats({Module, Key}, State)} | PrevVals]} | RestMods];
                  [{OtherMod, ModVals} | RestMods] ->
                      [{Module, [{Key, get_stats({Module, Key}, State)}]}, {OtherMod, {lists:reverse(ModVals)}} | RestMods]
              end
          end, [], lists:sort(Stats)),
          {[{LastMod, {lists:sort(LastVals)}} | LastRestMods]}
    end.


init_descriptions() ->

    % ets is probably overkill here, but I didn't manage to keep the
    % descriptions in the gen_server state. Which means there is probably
    % a bug in one of the handle_call() functions most likely the one that
    % handles the time_passed message. But don't tell anyone, the math is
    % correct :) -- Jan


    % Style guide for descriptions: Start with a lowercase letter & do not add
    % a trailing full-stop / period.

    % please keep this in alphabetical order
    ets:insert(?MODULE, {{couchdb, database_writes}, <<"number of times a database was changed">>}),
    ets:insert(?MODULE, {{couchdb, database_reads}, <<"number of times a document was read from a database">>}),
    ets:insert(?MODULE, {{couchdb, open_databases}, <<"number of open databases">>}),
    ets:insert(?MODULE, {{couchdb, open_os_files}, <<"number of file descriptors CouchDB has open">>}),
    ets:insert(?MODULE, {{couchdb, request_time}, <<"length of a request inside CouchDB without MochiWeb">>}),

    ets:insert(?MODULE, {{httpd, bulk_requests}, <<"number of bulk requests">>}),
    ets:insert(?MODULE, {{httpd, requests}, <<"number of HTTP requests">>}),
    ets:insert(?MODULE, {{httpd, temporary_view_reads}, <<"number of temporary view reads">>}),
    ets:insert(?MODULE, {{httpd, view_reads}, <<"number of view reads">>}),
    ets:insert(?MODULE, {{httpd, clients_requesting_changes}, <<"Number of clients currently requesting continuous _changes">>}),

    ets:insert(?MODULE, {{httpd_request_methods, 'COPY'}, <<"number of HTTP COPY requests">>}),
    ets:insert(?MODULE, {{httpd_request_methods, 'DELETE'}, <<"number of HTTP DELETE requests">>}),
    ets:insert(?MODULE, {{httpd_request_methods, 'GET'}, <<"number of HTTP GET requests">>}),
    ets:insert(?MODULE, {{httpd_request_methods, 'HEAD'}, <<"number of HTTP HEAD requests">>}),
    ets:insert(?MODULE, {{httpd_request_methods, 'MOVE'}, <<"number of HTTP MOVE requests">>}),
    ets:insert(?MODULE, {{httpd_request_methods, 'POST'}, <<"number of HTTP POST requests">>}),
    ets:insert(?MODULE, {{httpd_request_methods, 'PUT'}, <<"number of HTTP PUT requests">>}),

    ets:insert(?MODULE, {{httpd_status_codes, '200'}, <<"number of HTTP 200 OK responses">>}),
    ets:insert(?MODULE, {{httpd_status_codes, '201'}, <<"number of HTTP 201 Created responses">>}),
    ets:insert(?MODULE, {{httpd_status_codes, '202'}, <<"number of HTTP 202 Accepted responses">>}),
    ets:insert(?MODULE, {{httpd_status_codes, '301'}, <<"number of HTTP 301 Moved Permanently responses">>}),
    ets:insert(?MODULE, {{httpd_status_codes, '304'}, <<"number of HTTP 304 Not Modified responses">>}),
    ets:insert(?MODULE, {{httpd_status_codes, '400'}, <<"number of HTTP 400 Bad Request responses">>}),
    ets:insert(?MODULE, {{httpd_status_codes, '401'}, <<"number of HTTP 401 Unauthorized responses">>}),
    ets:insert(?MODULE, {{httpd_status_codes, '403'}, <<"number of HTTP 403 Forbidden responses">>}),
    ets:insert(?MODULE, {{httpd_status_codes, '404'}, <<"number of HTTP 404 Not Found responses">>}),
    ets:insert(?MODULE, {{httpd_status_codes, '405'}, <<"number of HTTP 405 Method Not Allowed responses">>}),
    ets:insert(?MODULE, {{httpd_status_codes, '409'}, <<"number of HTTP 409 Conflict responses">>}),
    ets:insert(?MODULE, {{httpd_status_codes, '412'}, <<"number of HTTP 412 Precondition Failed responses">>}),
    ets:insert(?MODULE, {{httpd_status_codes, '500'}, <<"number of HTTP 500 Internal Server Error responses">>}).
    % please keep this in alphabetical order


% Timer

init_timers() ->

    % OTP docs on timer: http://erlang.org/doc/man/timer.html
    %   start() -> ok
    %   Starts the timer server. Normally, the server does not need to be
    %   started explicitly. It is started dynamically if it is needed. This is
    %   useful during development, but in a target system the server should be
    %   started explicitly. Use configuration parameters for kernel for this.
    %
    % TODO: Add timer_start to kernel start options.


    % start timers every second, minute, five minutes and fifteen minutes
    % in the rare event of a timer death, couch_stats_aggregator will die,
    % too and restarted by the supervision tree, all stats (for the last
    % fifteen minutes) are gone.

    {ok, _} = timer:apply_interval(1000, ?MODULE, time_passed, []),
    {ok, _} = timer:apply_interval(60000, ?MODULE, clear_aggregates, ['60']),
    {ok, _} = timer:apply_interval(300000, ?MODULE, clear_aggregates, ['300']),
    {ok, _} = timer:apply_interval(900000, ?MODULE, clear_aggregates, ['900']).


% Unused gen_server behaviour API functions that we need to declare.

%% @doc Unused
handle_cast(foo, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

%% @doc Unused
terminate(_Reason, _State) -> ok.

%% @doc Unused
code_change(_OldVersion, State, _Extra) -> {ok, State}.


%% Tests

-ifdef(TEST).
% Internal API unit tests go here


-endif.
