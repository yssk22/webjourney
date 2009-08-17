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

-module(couch_view).
-behaviour(gen_server).

-export([start_link/0,fold/4,fold/5,less_json/2,less_json_keys/2,expand_dups/2,
    detuple_kvs/2,init/1,terminate/2,handle_call/3,handle_cast/2,handle_info/2,
    code_change/3,get_reduce_view/4,get_temp_reduce_view/5,get_temp_map_view/4,
    get_map_view/4,get_row_count/1,reduce_to_count/1,fold_reduce/7,
    extract_map_view/1]).

-include("couch_db.hrl").


-record(server,{
    root_dir = []}).
    
start_link() ->
    gen_server:start_link({local, couch_view}, couch_view, [], []).

get_temp_updater(DbName, Type, DesignOptions, MapSrc, RedSrc) ->
    {ok, Pid} = gen_server:call(couch_view,
            {start_temp_updater, DbName, Type, DesignOptions, MapSrc, RedSrc}),
    Pid.

get_group_server(DbName, GroupId) ->
    case gen_server:call(couch_view, {start_group_server, DbName, GroupId}) of
    {ok, Pid} ->
        Pid;
    Error ->
        throw(Error)
    end.
    
get_group(Db, GroupId, Stale) ->
    MinUpdateSeq = case Stale of
    ok -> 0;
    _Else -> couch_db:get_update_seq(Db)
    end,
    couch_view_group:request_group(
            get_group_server(couch_db:name(Db), GroupId),
            MinUpdateSeq).


get_temp_group(Db, Type, DesignOptions, MapSrc, RedSrc) ->
    couch_view_group:request_group(
            get_temp_updater(couch_db:name(Db), Type, DesignOptions, MapSrc, RedSrc),
            couch_db:get_update_seq(Db)).

get_row_count(#view{btree=Bt}) ->
    {ok, {Count, _Reds}} = couch_btree:full_reduce(Bt),
    {ok, Count}.

get_temp_reduce_view(Db, Type, DesignOptions, MapSrc, RedSrc) ->
    {ok, #group{views=[View]}=Group} = get_temp_group(Db, Type, DesignOptions, MapSrc, RedSrc),
    {ok, {temp_reduce, View}, Group}.


get_reduce_view(Db, GroupId, Name, Update) ->
    case get_group(Db, GroupId, Update) of
    {ok, #group{views=Views,def_lang=Lang}=Group} ->
        case get_reduce_view0(Name, Lang, Views) of
        {ok, View} ->
            {ok, View, Group};
        Else ->
            Else
        end;
    Error ->
        Error
    end.

get_reduce_view0(_Name, _Lang, []) ->
    {not_found, missing_named_view};
get_reduce_view0(Name, Lang, [#view{reduce_funs=RedFuns}=View|Rest]) ->
    case get_key_pos(Name, RedFuns, 0) of
        0 -> get_reduce_view0(Name, Lang, Rest);
        N -> {ok, {reduce, N, Lang, View}}
    end.

extract_map_view({reduce, _N, _Lang, View}) ->
    View.

detuple_kvs([], Acc) ->
    lists:reverse(Acc);
detuple_kvs([KV | Rest], Acc) ->
    {{Key,Id},Value} = KV,
    NKV = [[Key, Id], Value],
    detuple_kvs(Rest, [NKV | Acc]).

expand_dups([], Acc) ->
    lists:reverse(Acc);
expand_dups([{Key, {dups, Vals}} | Rest], Acc) ->
    Expanded = [{Key, Val} || Val <- Vals],
    expand_dups(Rest, Expanded ++ Acc);
expand_dups([KV | Rest], Acc) ->
    expand_dups(Rest, [KV | Acc]).

fold_reduce({temp_reduce, #view{btree=Bt}}, Dir, StartKey, EndKey, GroupFun, Fun, Acc) ->

    WrapperFun = fun({GroupedKey, _}, PartialReds, Acc0) ->
            {_, [Red]} = couch_btree:final_reduce(Bt, PartialReds),
            Fun(GroupedKey, Red, Acc0)
        end,
    couch_btree:fold_reduce(Bt, Dir, StartKey, EndKey, GroupFun,
            WrapperFun, Acc);

fold_reduce({reduce, NthRed, Lang, #view{btree=Bt, reduce_funs=RedFuns}}, Dir, StartKey, EndKey, GroupFun, Fun, Acc) ->    
    PreResultPadding = lists:duplicate(NthRed - 1, []),
    PostResultPadding = lists:duplicate(length(RedFuns) - NthRed, []),
    {_Name, FunSrc} = lists:nth(NthRed,RedFuns),
    ReduceFun =
        fun(reduce, KVs) ->
            {ok, Reduced} = couch_query_servers:reduce(Lang, [FunSrc], detuple_kvs(expand_dups(KVs, []),[])),
            {0, PreResultPadding ++ Reduced ++ PostResultPadding};
        (rereduce, Reds) ->
            UserReds = [[lists:nth(NthRed, UserRedsList)] || {_, UserRedsList} <- Reds],
            {ok, Reduced} = couch_query_servers:rereduce(Lang, [FunSrc], UserReds),
            {0, PreResultPadding ++ Reduced ++ PostResultPadding}
        end,
    WrapperFun = fun({GroupedKey, _}, PartialReds, Acc0) ->
            {_, Reds} = couch_btree:final_reduce(ReduceFun, PartialReds),
            Fun(GroupedKey, lists:nth(NthRed, Reds), Acc0)
        end,
    couch_btree:fold_reduce(Bt, Dir, StartKey, EndKey, GroupFun,
            WrapperFun, Acc).
        
get_key_pos(_Key, [], _N) ->
    0;
get_key_pos(Key, [{Key1,_Value}|_], N) when Key == Key1 ->
    N + 1;
get_key_pos(Key, [_|Rest], N) ->
    get_key_pos(Key, Rest, N+1).


get_temp_map_view(Db, Type, DesignOptions, Src) ->
    {ok, #group{views=[View]}=Group} = get_temp_group(Db, Type, DesignOptions, Src, []),
    {ok, View, Group}.

get_map_view(Db, GroupId, Name, Stale) ->
    case get_group(Db, GroupId, Stale) of
    {ok, #group{views=Views}=Group} ->
        case get_map_view0(Name, Views) of
        {ok, View} ->
            {ok, View, Group};
        Else ->
            Else
        end;
    Error ->
        Error
    end.

get_map_view0(_Name, []) ->
    {not_found, missing_named_view};
get_map_view0(Name, [#view{map_names=MapNames}=View|Rest]) ->
    case lists:member(Name, MapNames) of
        true -> {ok, View};
        false -> get_map_view0(Name, Rest)
    end.

reduce_to_count(Reductions) ->
    {Count, _} = 
    couch_btree:final_reduce(
        fun(reduce, KVs) ->
            Count = lists:sum(
                [case V of {dups, Vals} -> length(Vals); _ -> 1 end
                || {_,V} <- KVs]),
            {Count, []};
        (rereduce, Reds) ->
            {lists:sum([Count0 || {Count0, _} <- Reds]), []}
        end, Reductions),
    Count.
                

    
fold_fun(_Fun, [], _, Acc) ->
    {ok, Acc};
fold_fun(Fun, [KV|Rest], {KVReds, Reds}, Acc) ->
    case Fun(KV, {KVReds, Reds}, Acc) of
    {ok, Acc2} ->
        fold_fun(Fun, Rest, {[KV|KVReds], Reds}, Acc2);
    {stop, Acc2} ->
        {stop, Acc2}
    end.

fold(#view{btree=Btree}, Dir, Fun, Acc) ->
    fold(Btree, nil, Dir, Fun, Acc).

fold(#view{btree=Btree}, StartKey, Dir, Fun, Acc) ->
    WrapperFun =
        fun(KV, Reds, Acc2) ->
            fold_fun(Fun, expand_dups([KV],[]), Reds, Acc2)
        end,
    {ok, _AccResult} = couch_btree:fold(Btree, StartKey, Dir, WrapperFun, Acc).


init([]) ->
    % read configuration settings and register for configuration changes
    RootDir = couch_config:get("couchdb", "view_index_dir"),
    Self = self(),
    ok = couch_config:register(
        fun("couchdb", "view_index_dir")->
            exit(Self, config_change)
        end),
        
    couch_db_update_notifier:start_link(
        fun({deleted, DbName}) ->
            gen_server:cast(couch_view, {reset_indexes, DbName});
        ({created, DbName}) ->
            gen_server:cast(couch_view, {reset_indexes, DbName});
        (_Else) ->
            ok
        end),
    ets:new(couch_groups_by_db, [bag, private, named_table]),
    ets:new(group_servers_by_name, [set, protected, named_table]),
    ets:new(couch_groups_by_updater, [set, private, named_table]),
    ets:new(couch_temp_group_fd_by_db, [set, protected, named_table]),
    process_flag(trap_exit, true),
    {ok, #server{root_dir=RootDir}}.

terminate(_Reason,_State) ->
    ok.


handle_call({start_temp_updater, DbName, Lang, DesignOptions, MapSrc, RedSrc},
                                                _From, #server{root_dir=Root}=Server) ->
    <<SigInt:128/integer>> = erlang:md5(term_to_binary({Lang, DesignOptions, MapSrc, RedSrc})),
    Name = lists:flatten(io_lib:format("_temp_~.36B",[SigInt])),
    Pid = 
    case ets:lookup(group_servers_by_name, {DbName, Name}) of
    [] ->
        case ets:lookup(couch_temp_group_fd_by_db, DbName) of
        [] ->
            FileName = Root ++ "/." ++ binary_to_list(DbName) ++ "_temp",
            {ok, Fd} = couch_file:open(FileName, [create, overwrite]),
            Count = 0;
        [{_, Fd, Count}] ->
            ok
        end,
        ?LOG_DEBUG("Spawning new temp update process for db ~s.", [DbName]),
        {ok, NewPid} = couch_view_group:start_link({slow_view, DbName, Fd, Lang, DesignOptions, MapSrc, RedSrc}),
        true = ets:insert(couch_temp_group_fd_by_db, {DbName, Fd, Count + 1}),
        add_to_ets(NewPid, DbName, Name),
        NewPid;
    [{_, ExistingPid0}] ->
        ExistingPid0
    end,
    {reply, {ok, Pid}, Server};
handle_call({start_group_server, DbName, GroupId}, _From, #server{root_dir=Root}=Server) ->
    case ets:lookup(group_servers_by_name, {DbName, GroupId}) of
    [] ->
        ?LOG_DEBUG("Spawning new group server for view group ~s in database ~s.", [GroupId, DbName]),
        case couch_view_group:start_link({view, Root, DbName, GroupId}) of
        {ok, NewPid} ->
            add_to_ets(NewPid, DbName, GroupId),
            {reply, {ok, NewPid}, Server};
        Error ->
            {reply, Error, Server}
        end;
    [{_, ExistingPid}] ->
        {reply, {ok, ExistingPid}, Server}
    end.

handle_cast({reset_indexes, DbName}, #server{root_dir=Root}=Server) ->
    % shutdown all the updaters
    Names = ets:lookup(couch_groups_by_db, DbName),
    lists:foreach(
        fun({_DbName, GroupId}) ->
            ?LOG_DEBUG("Killing update process for view group ~s. in database ~s.", [GroupId, DbName]),
            [{_, Pid}] = ets:lookup(group_servers_by_name, {DbName, GroupId}),
            exit(Pid, kill),
            receive {'EXIT', Pid, _} ->
                delete_from_ets(Pid, DbName, GroupId)
            end
        end, Names),
    delete_index_dir(Root, DbName),
    file:delete(Root ++ "/." ++ binary_to_list(DbName) ++ "_temp"),
    {noreply, Server}.

handle_info({'EXIT', FromPid, Reason}, #server{root_dir=RootDir}=Server) ->
    case ets:lookup(couch_groups_by_updater, FromPid) of
    [] ->
        if Reason /= normal ->
            % non-updater linked process died, we propagate the error
            ?LOG_ERROR("Exit on non-updater process: ~p", [Reason]),
            exit(Reason);
        true -> ok
        end;
    [{_, {DbName, "_temp_" ++ _ = GroupId}}] ->
        delete_from_ets(FromPid, DbName, GroupId),
        [{_, Fd, Count}] = ets:lookup(couch_temp_group_fd_by_db, DbName),
        case Count of
        1 -> % Last ref
            couch_file:close(Fd),
            file:delete(RootDir ++ "/." ++ binary_to_list(DbName) ++ "_temp"),
            true = ets:delete(couch_temp_group_fd_by_db, DbName);
        _ ->
            true = ets:insert(couch_temp_group_fd_by_db, {DbName, Fd, Count - 1})
        end;
    [{_, {DbName, GroupId}}] ->
        delete_from_ets(FromPid, DbName, GroupId)
    end,
    {noreply, Server}.
    
add_to_ets(Pid, DbName, GroupId) ->
    true = ets:insert(couch_groups_by_updater, {Pid, {DbName, GroupId}}),
    true = ets:insert(group_servers_by_name, {{DbName, GroupId}, Pid}),
    true = ets:insert(couch_groups_by_db, {DbName, GroupId}).
    
delete_from_ets(Pid, DbName, GroupId) ->
    true = ets:delete(couch_groups_by_updater, Pid),
    true = ets:delete(group_servers_by_name, {DbName, GroupId}),
    true = ets:delete_object(couch_groups_by_db, {DbName, GroupId}).

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.




delete_index_dir(RootDir, DbName) ->
    nuke_dir(RootDir ++ "/." ++ binary_to_list(DbName) ++ "_design").

nuke_dir(Dir) ->
    case file:list_dir(Dir) of
    {error, enoent} -> ok; % doesn't exist
    {ok, Files} ->
        lists:foreach(
            fun(File)->
                Full = Dir ++ "/" ++ File,
                case file:delete(Full) of
                ok -> ok;
                {error, eperm} ->
                    ok = nuke_dir(Full)
                end
            end,
            Files),    
        ok = file:del_dir(Dir)
    end.

% keys come back in the language of btree - tuples.
less_json_keys(A, B) ->
    less_json(tuple_to_list(A), tuple_to_list(B)).

less_json(A, B) ->
    TypeA = type_sort(A),
    TypeB = type_sort(B),
    if
    TypeA == TypeB ->
        Less = less_same_type(A,B),
        Less;
    true ->
        TypeA < TypeB
    end.

type_sort(V) when is_atom(V) -> 0;
type_sort(V) when is_integer(V) -> 1;
type_sort(V) when is_float(V) -> 1;
type_sort(V) when is_binary(V) -> 2;
type_sort(V) when is_list(V) -> 3;
type_sort({V}) when is_list(V) -> 4;
type_sort(V) when is_tuple(V) -> 5.


atom_sort(nil) -> 0;
atom_sort(null) -> 1;
atom_sort(false) -> 2;
atom_sort(true) -> 3.


less_same_type(A,B) when is_atom(A) ->
  atom_sort(A) < atom_sort(B);
less_same_type(A,B) when is_binary(A) ->
  couch_util:collate(A, B) < 0;
less_same_type({AProps}, {BProps}) ->
  less_props(AProps, BProps);
less_same_type(A, B) when is_list(A) ->
  less_list(A, B);
less_same_type(A, B) ->
    A < B.
	
less_props([], [_|_]) ->
    true;
less_props(_, []) ->
    false;
less_props([{AKey, AValue}|RestA], [{BKey, BValue}|RestB]) ->
    case couch_util:collate(AKey, BKey) of
    -1 -> true;
    1 -> false;
    0 ->
        case less_json(AValue, BValue) of
        true -> true;
        false ->
            case less_json(BValue, AValue) of
            true -> false;
            false ->
                less_props(RestA, RestB)
            end
        end
    end.

less_list([], [_|_]) ->
    true;
less_list(_, []) ->
    false;
less_list([A|RestA], [B|RestB]) ->
    case less_json(A,B) of
    true -> true;
    false ->
        case less_json(B,A) of
        true -> false;
        false ->
            less_list(RestA, RestB)
        end
    end.


