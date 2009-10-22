#!/usr/bin/env escript
%% -*- erlang -*-

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

main(_) ->
    code:add_patha("src/etap"),
    code:add_pathz("src/couchdb"),
    code:add_pathz("src/mochiweb"),

    etap:plan(4),
    case (catch test()) of
        ok ->
            etap:end_tests();
        Other ->
            etap:diag(io_lib:format("Test died abnormally: ~p", [Other])),
            etap:bail(Other)
    end,
    ok.

test() ->

    couch_server:start(
        ["etc/couchdb/default_dev.ini", "etc/couchdb/local_dev.ini"]
    ),

    couch_db:create(<<"etap-test-db">>, []),
    {ok, AllDbs} = couch_server:all_databases(),
    etap:ok(lists:member(<<"etap-test-db">>, AllDbs), "Database was created."),

    couch_server:delete(<<"etap-test-db">>, []),
    {ok, AllDbs2} = couch_server:all_databases(),
    etap:ok(not lists:member(<<"etap-test-db">>, AllDbs2),
        "Database was deleted."),

    MkDbName = fun(Int) -> list_to_binary("lru-" ++ integer_to_list(Int)) end,

    lists:foreach(fun(Int) ->
        {ok, TestDbs} = couch_server:all_databases(),
        ok = case lists:member(MkDbName(Int), TestDbs) of
            true -> couch_server:delete(MkDbName(Int), []);
            _ -> ok
        end,
        {ok, Db} = couch_db:create(MkDbName(Int), []),
        ok = couch_db:close(Db)
    end, lists:seq(1, 200)),

    {ok, AllDbs3} = couch_server:all_databases(),
    NumCreated = lists:foldl(fun(Int, Acc) ->
        true = lists:member(MkDbName(Int), AllDbs3),
        Acc+1
    end, 0, lists:seq(1, 200)),
    etap:is(200, NumCreated, "Created all databases."),

    lists:foreach(fun(Int) ->
        ok = couch_server:delete(MkDbName(Int), [])
    end, lists:seq(1, 200)),

    {ok, AllDbs4} = couch_server:all_databases(),
    NumDeleted = lists:foldl(fun(Int, Acc) ->
        false = lists:member(MkDbName(Int), AllDbs4),
        Acc+1
    end, 0, lists:seq(1, 200)),
    etap:is(200, NumDeleted, "Deleted all databases."),

    ok.
