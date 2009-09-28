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

-module(couch_httpd_db).
-include("couch_db.hrl").

-export([handle_request/1, handle_compact_req/2, handle_design_req/2,
    db_req/2, couch_doc_open/4,handle_changes_req/2,
    update_doc_result_to_json/1, update_doc_result_to_json/2,
    handle_design_info_req/2, handle_view_cleanup_req/2]).

-import(couch_httpd,
    [send_json/2,send_json/3,send_json/4,send_method_not_allowed/2,
    start_json_response/2,start_json_response/3,
    send_chunk/2,end_json_response/1,
    start_chunked_response/3, absolute_uri/2, send/2,
    start_response_length/4]).

-record(doc_query_args, {
    options = [],
    rev = nil,
    open_revs = [],
    show = nil
}).

% Database request handlers
handle_request(#httpd{path_parts=[DbName|RestParts],method=Method,
        db_url_handlers=DbUrlHandlers}=Req)->
    case {Method, RestParts} of
    {'PUT', []} ->
        create_db_req(Req, DbName);
    {'DELETE', []} ->
        delete_db_req(Req, DbName);
    {_, []} ->
        do_db_req(Req, fun db_req/2);
    {_, [SecondPart|_]} ->
        Handler = couch_util:dict_find(SecondPart, DbUrlHandlers, fun db_req/2),
        do_db_req(Req, Handler)
    end.

get_changes_timeout(Req, Resp) ->
    DefaultTimeout = list_to_integer(
            couch_config:get("httpd", "changes_timeout", "60000")),
    case couch_httpd:qs_value(Req, "heartbeat") of
    undefined ->
        case couch_httpd:qs_value(Req, "timeout") of
        undefined ->
            {DefaultTimeout, fun() -> stop end};
        TimeoutList ->
            {lists:min([DefaultTimeout, list_to_integer(TimeoutList)]),
                fun() -> stop end}
        end;
    "true" ->
        {DefaultTimeout, fun() -> send_chunk(Resp, "\n"), ok end};
    TimeoutList ->
        {lists:min([DefaultTimeout, list_to_integer(TimeoutList)]),
            fun() -> send_chunk(Resp, "\n"), ok end}
    end.


start_sending_changes(_Resp, "continuous") ->
    ok;
start_sending_changes(Resp, _Else) ->
    send_chunk(Resp, "{\"results\":[\n").

handle_changes_req(#httpd{method='GET',path_parts=[DbName|_]}=Req, Db) ->
    {FilterFun, EndFilterFun} = make_filter_funs(Req, Db),
    {ok, Info} = couch_db:get_db_info(Db),
    Seq = proplists:get_value(update_seq, Info),
    {Dir, StartSeq} = case couch_httpd:qs_value(Req, "descending", "false") of 
        "false" -> 
            {fwd, list_to_integer(couch_httpd:qs_value(Req, "since", "0"))}; 
        "true" -> 
            {rev, Seq};
        _Bad -> throw({bad_request, "descending must be true or false"})
    end,
    Limit = list_to_integer(couch_httpd:qs_value(Req, "limit", "1000000000000000")),
    ResponseType = couch_httpd:qs_value(Req, "feed", "normal"),
    if ResponseType == "continuous" orelse ResponseType == "longpoll" ->
        {ok, Resp} = start_json_response(Req, 200),
        start_sending_changes(Resp, ResponseType),

        Self = self(),
        {ok, Notify} = couch_db_update_notifier:start_link(
            fun({_, DbName0}) when DbName0 == DbName ->
                Self ! db_updated;
            (_) ->
                ok
            end),
        {Timeout, TimeoutFun} = get_changes_timeout(Req, Resp),
        couch_stats_collector:track_process_count(Self,
                            {httpd, clients_requesting_changes}),
        try
            keep_sending_changes(Req, Resp, Db, StartSeq, <<"">>, Timeout,
                TimeoutFun, ResponseType, Limit, FilterFun, EndFilterFun)
        after
            couch_db_update_notifier:stop(Notify),
            get_rest_db_updated() % clean out any remaining update messages
        end;
    true ->
        CurrentEtag = couch_httpd:make_etag(Info),
        couch_httpd:etag_respond(Req, CurrentEtag, fun() ->
            % send the etag
            {ok, Resp} = start_json_response(Req, 200, [{"Etag", CurrentEtag}]),
            start_sending_changes(Resp, ResponseType),
            {ok, {_, LastSeq, _Prepend, _, _, _, _, _}} =
                    send_changes(Req, Resp, Db, Dir, StartSeq, <<"">>, "normal",
                        Limit, FilterFun, EndFilterFun),
            end_sending_changes(Resp, LastSeq, ResponseType)
        end)
    end;

handle_changes_req(#httpd{path_parts=[_,<<"_changes">>]}=Req, _Db) ->
    send_method_not_allowed(Req, "GET,HEAD").

% waits for a db_updated msg, if there are multiple msgs, collects them.
wait_db_updated(Timeout, TimeoutFun) ->
    receive db_updated -> get_rest_db_updated()
    after Timeout ->
        case TimeoutFun() of
        ok -> wait_db_updated(Timeout, TimeoutFun);
        stop -> stop
        end
    end.

get_rest_db_updated() ->
    receive db_updated -> get_rest_db_updated()
    after 0 -> updated
    end.
    
end_sending_changes(Resp, EndSeq, "continuous") ->
    send_chunk(Resp, [?JSON_ENCODE({[{<<"last_seq">>, EndSeq}]}) | "\n"]),
    end_json_response(Resp);
end_sending_changes(Resp, EndSeq, _Else) ->
    send_chunk(Resp, io_lib:format("\n],\n\"last_seq\":~w}\n", [EndSeq])),
    end_json_response(Resp).

keep_sending_changes(#httpd{user_ctx=UserCtx,path_parts=[DbName|_]}=Req, Resp,
        Db, StartSeq, Prepend, Timeout, TimeoutFun, ResponseType, Limit, Filter, End) ->
    {ok, {_, EndSeq, Prepend2, _, _, _, NewLimit, _}} = send_changes(Req, Resp, Db, fwd, StartSeq,
        Prepend, ResponseType, Limit, Filter, End),
    couch_db:close(Db),
    if
    EndSeq > StartSeq, ResponseType == "longpoll" ->
        end_sending_changes(Resp, EndSeq, ResponseType);
    true ->
        case wait_db_updated(Timeout, TimeoutFun) of
        updated ->
            case couch_db:open(DbName, [{user_ctx, UserCtx}]) of
            {ok, Db2} ->
                keep_sending_changes(Req, Resp, Db2, EndSeq, Prepend2, Timeout,
                    TimeoutFun, ResponseType, NewLimit, Filter, End);
            _Else ->
                end_sending_changes(Resp, EndSeq, ResponseType)
            end;
        stop ->
            end_sending_changes(Resp, EndSeq, ResponseType)
        end
    end.

changes_enumerator(DocInfos, {Db, _, _, FilterFun, Resp, "continuous", Limit, IncludeDocs}) ->
    [#doc_info{id=Id, high_seq=Seq, revs=[#rev_info{deleted=Del,rev=Rev}|_]}|_] = DocInfos,
    Results0 = [FilterFun(DocInfo) || DocInfo <- DocInfos],
    Results = [Result || Result <- Results0, Result /= null],
    Go = if Limit =< 1 -> stop; true -> ok end,
    case Results of
    [] ->
        {Go, {Db, Seq, nil, FilterFun, Resp, "continuous", Limit, IncludeDocs}};
    _ ->
        send_chunk(Resp, [?JSON_ENCODE(changes_row(Db, Seq, Id, Del, Results, Rev, IncludeDocs))
            |"\n"]),
        {Go, {Db, Seq, nil, FilterFun, Resp, "continuous",  Limit-1, IncludeDocs}}
    end;
changes_enumerator(DocInfos, {Db, _, Prepend, FilterFun, Resp, _, Limit, IncludeDocs}) ->
    [#doc_info{id=Id, high_seq=Seq, revs=[#rev_info{deleted=Del,rev=Rev}|_]}|_] = DocInfos,
    Results0 = [FilterFun(DocInfo) || DocInfo <- DocInfos],
    Results = [Result || Result <- Results0, Result /= null],
    Go = if Limit =< 1 -> stop; true -> ok end,
    case Results of
    [] ->
        {Go, {Db, Seq, Prepend, FilterFun, Resp, nil, Limit, IncludeDocs}};
    _ ->
        send_chunk(Resp, [Prepend, ?JSON_ENCODE(
            changes_row(Db, Seq, Id, Del, Results, Rev, IncludeDocs))]),
        {Go, {Db, Seq, <<",\n">>, FilterFun, Resp, nil, Limit-1, IncludeDocs}}
    end.

changes_row(Db, Seq, Id, Del, Results, Rev, true) ->
    {[{seq,Seq},{id,Id},{changes,Results}] ++ deleted_item(Del) ++
        couch_httpd_view:doc_member(Db, {Id, Rev})};
changes_row(_, Seq, Id, Del, Results, _, false) ->
    {[{seq,Seq},{id,Id},{changes,Results}] ++ deleted_item(Del)}.

deleted_item(true) -> [{deleted,true}];
deleted_item(_) -> [].

send_changes(Req, Resp, Db, Dir, StartSeq, Prepend, ResponseType, Limit, FilterFun, End) ->
    Style = list_to_existing_atom(
            couch_httpd:qs_value(Req, "style", "main_only")),
    IncludeDocs = list_to_existing_atom(
            couch_httpd:qs_value(Req, "include_docs", "false")),
    try
        couch_db:changes_since(Db, Style, StartSeq, fun changes_enumerator/2, 
            [{dir, Dir}], {Db, StartSeq, Prepend, FilterFun, Resp, ResponseType, Limit, IncludeDocs})
    after
        End()
    end.

make_filter_funs(Req, Db) ->
    Filter = couch_httpd:qs_value(Req, "filter", ""),
    case [list_to_binary(couch_httpd:unquote(Part))
            || Part <- string:tokens(Filter, "/")] of
    [] ->
    {fun(#doc_info{revs=[#rev_info{rev=Rev}|_]}) ->
            {[{rev, couch_doc:rev_to_str(Rev)}]}
        end,
        fun() -> ok end};
    [DName, FName] ->
        DesignId = <<"_design/", DName/binary>>,
        case couch_db:open_doc(Db, DesignId) of
        {ok, #doc{body={Props}}} ->
            FilterSrc = try couch_util:get_nested_json_value({Props},
                [<<"filters">>, FName])
            catch
            throw:{not_found, _} ->
                throw({bad_request, "invalid filter function"})
            end,
            Lang = proplists:get_value(<<"language">>, Props, <<"javascript">>),
            {ok, Pid} = couch_query_servers:start_filter(Lang, FilterSrc),
            FilterFun = fun(DInfo = #doc_info{revs=[#rev_info{rev=Rev}|_]}) ->
                {ok, Doc} = couch_db:open_doc(Db, DInfo, [deleted]),
                {ok, Pass} = couch_query_servers:filter_doc(Pid, Doc, Req, Db),
                case Pass of
                true ->
                    {[{rev, couch_doc:rev_to_str(Rev)}]};
                false ->
                    null
                end
            end,
            EndFilterFun = fun() ->
                couch_query_servers:end_filter(Pid)
            end,
            {FilterFun, EndFilterFun};
        _Error ->
            throw({bad_request, "invalid design doc"})
        end;
    _Else ->
        throw({bad_request, 
            "filter parameter must be of the form `designname/filtername`"})
    end.  

handle_compact_req(#httpd{method='POST',path_parts=[DbName,_,Id|_]}=Req, _Db) ->
    ok = couch_view_compactor:start_compact(DbName, Id),
    send_json(Req, 202, {[{ok, true}]});

handle_compact_req(#httpd{method='POST'}=Req, Db) ->
    ok = couch_db:start_compact(Db),
    send_json(Req, 202, {[{ok, true}]});

handle_compact_req(Req, _Db) ->
    send_method_not_allowed(Req, "POST").

handle_view_cleanup_req(#httpd{method='POST'}=Req, Db) ->
    % delete unreferenced index files
    ok = couch_view:cleanup_index_files(Db),
    send_json(Req, 202, {[{ok, true}]});

handle_view_cleanup_req(Req, _Db) ->
    send_method_not_allowed(Req, "POST").


handle_design_req(#httpd{
        path_parts=[_DbName,_Design,_DesName, <<"_",_/binary>> = Action | _Rest],
        design_url_handlers = DesignUrlHandlers
    }=Req, Db) ->
    Handler = couch_util:dict_find(Action, DesignUrlHandlers, fun db_req/2),
    Handler(Req, Db);

handle_design_req(Req, Db) ->
    db_req(Req, Db).

handle_design_info_req(#httpd{
            method='GET',
            path_parts=[_DbName, _Design, DesignName, _]
        }=Req, Db) ->
    DesignId = <<"_design/", DesignName/binary>>,
    {ok, GroupInfoList} = couch_view:get_group_info(Db, DesignId),
    send_json(Req, 200, {[
        {name, DesignName},
        {view_index, {GroupInfoList}}
    ]});

handle_design_info_req(Req, _Db) ->
    send_method_not_allowed(Req, "GET").

create_db_req(#httpd{user_ctx=UserCtx}=Req, DbName) ->
    ok = couch_httpd:verify_is_server_admin(Req),
    case couch_server:create(DbName, [{user_ctx, UserCtx}]) of
    {ok, Db} ->
        couch_db:close(Db),
        DocUrl = absolute_uri(Req, "/" ++ couch_util:url_encode(DbName)),
        send_json(Req, 201, [{"Location", DocUrl}], {[{ok, true}]});
    Error ->
        throw(Error)
    end.

delete_db_req(#httpd{user_ctx=UserCtx}=Req, DbName) ->
    ok = couch_httpd:verify_is_server_admin(Req),
    case couch_server:delete(DbName, [{user_ctx, UserCtx}]) of
    ok ->
        send_json(Req, 200, {[{ok, true}]});
    Error ->
        throw(Error)
    end.

do_db_req(#httpd{user_ctx=UserCtx,path_parts=[DbName|_]}=Req, Fun) ->
    case couch_db:open(DbName, [{user_ctx, UserCtx}]) of
    {ok, Db} ->
        try
            Fun(Req, Db)
        after
            catch couch_db:close(Db)
        end;
    Error ->
        throw(Error)
    end.

db_req(#httpd{method='GET',path_parts=[_DbName]}=Req, Db) ->
    {ok, DbInfo} = couch_db:get_db_info(Db),
    send_json(Req, {DbInfo});

db_req(#httpd{method='POST',path_parts=[DbName]}=Req, Db) ->
    Doc = couch_doc:from_json_obj(couch_httpd:json_body(Req)),
    Doc2 = case Doc#doc.id of
        <<"">> ->
            Doc#doc{id=couch_uuids:new(), revs={0, []}};
        _ ->
            Doc
    end,
    DocId = Doc2#doc.id,
    case couch_httpd:qs_value(Req, "batch") of
    "ok" ->
        % batch
        ok = couch_batch_save:eventually_save_doc(
            Db#db.name, Doc2, Db#db.user_ctx),
        send_json(Req, 202, [], {[
            {ok, true},
            {id, DocId}
        ]});
    _Normal ->
        % normal
        {ok, NewRev} = couch_db:update_doc(Db, Doc2, []),
        DocUrl = absolute_uri(
            Req, binary_to_list(<<"/",DbName/binary,"/", DocId/binary>>)),
        send_json(Req, 201, [{"Location", DocUrl}], {[
            {ok, true},
            {id, DocId},
            {rev, couch_doc:rev_to_str(NewRev)}
        ]})
    end;


db_req(#httpd{path_parts=[_DbName]}=Req, _Db) ->
    send_method_not_allowed(Req, "DELETE,GET,HEAD,POST");

db_req(#httpd{method='POST',path_parts=[_,<<"_ensure_full_commit">>]}=Req, Db) ->
    UpdateSeq = couch_db:get_update_seq(Db),
    CommittedSeq = couch_db:get_committed_update_seq(Db),
    {ok, StartTime} =
    case couch_httpd:qs_value(Req, "seq") of
    undefined ->
        committed = couch_batch_save:commit_now(Db#db.name, Db#db.user_ctx),
        couch_db:ensure_full_commit(Db);
    RequiredStr ->
        RequiredSeq = list_to_integer(RequiredStr),
        if RequiredSeq > UpdateSeq ->
            throw({bad_request,
                "can't do a full commit ahead of current update_seq"});
        RequiredSeq > CommittedSeq ->
            % user asked for an explicit sequence, don't commit any batches
            couch_db:ensure_full_commit(Db);
        true ->
            {ok, Db#db.instance_start_time}
        end
    end,
    send_json(Req, 201, {[
        {ok, true},
        {instance_start_time, StartTime}
    ]});

db_req(#httpd{path_parts=[_,<<"_ensure_full_commit">>]}=Req, _Db) ->
    send_method_not_allowed(Req, "POST");

db_req(#httpd{method='POST',path_parts=[_,<<"_bulk_docs">>]}=Req, Db) ->
    couch_stats_collector:increment({httpd, bulk_requests}),
    {JsonProps} = couch_httpd:json_body_obj(Req),
    DocsArray = proplists:get_value(<<"docs">>, JsonProps),
    case couch_httpd:header_value(Req, "X-Couch-Full-Commit") of
    "true" ->
        Options = [full_commit];
    "false" ->
        Options = [delay_commit];
    _ ->
        Options = []
    end,
    case proplists:get_value(<<"new_edits">>, JsonProps, true) of
    true ->
        Docs = lists:map(
            fun({ObjProps} = JsonObj) ->
                Doc = couch_doc:from_json_obj(JsonObj),
                validate_attachment_names(Doc),
                Id = case Doc#doc.id of
                    <<>> -> couch_uuids:new();
                    Id0 -> Id0
                end,
                case proplists:get_value(<<"_rev">>, ObjProps) of
                undefined ->
                    Revs = {0, []};
                Rev  ->
                    {Pos, RevId} = couch_doc:parse_rev(Rev),
                    Revs = {Pos, [RevId]}
                end,
                Doc#doc{id=Id,revs=Revs}
            end,
            DocsArray),
        Options2 =
        case proplists:get_value(<<"all_or_nothing">>, JsonProps) of
        true  -> [all_or_nothing|Options];
        _ -> Options
        end,
        case couch_db:update_docs(Db, Docs, Options2) of
        {ok, Results} ->
            % output the results
            DocResults = lists:zipwith(fun update_doc_result_to_json/2,
                Docs, Results),
            send_json(Req, 201, DocResults);
        {aborted, Errors} ->
            ErrorsJson =
                lists:map(fun update_doc_result_to_json/1, Errors),
            send_json(Req, 417, ErrorsJson)
        end;
    false ->
        Docs = [couch_doc:from_json_obj(JsonObj) || JsonObj <- DocsArray],
        {ok, Errors} = couch_db:update_docs(Db, Docs, Options, replicated_changes),
        ErrorsJson =
            lists:map(fun update_doc_result_to_json/1, Errors),
        send_json(Req, 201, ErrorsJson)
    end;
db_req(#httpd{path_parts=[_,<<"_bulk_docs">>]}=Req, _Db) ->
    send_method_not_allowed(Req, "POST");

db_req(#httpd{method='POST',path_parts=[_,<<"_purge">>]}=Req, Db) ->
    {IdsRevs} = couch_httpd:json_body_obj(Req),
    IdsRevs2 = [{Id, couch_doc:parse_revs(Revs)} || {Id, Revs} <- IdsRevs],

    case couch_db:purge_docs(Db, IdsRevs2) of
    {ok, PurgeSeq, PurgedIdsRevs} ->
        PurgedIdsRevs2 = [{Id, couch_doc:rev_to_strs(Revs)} || {Id, Revs} <- PurgedIdsRevs],
        send_json(Req, 200, {[{<<"purge_seq">>, PurgeSeq}, {<<"purged">>, {PurgedIdsRevs2}}]});
    Error ->
        throw(Error)
    end;

db_req(#httpd{path_parts=[_,<<"_purge">>]}=Req, _Db) ->
    send_method_not_allowed(Req, "POST");

db_req(#httpd{method='GET',path_parts=[_,<<"_all_docs">>]}=Req, Db) ->
    all_docs_view(Req, Db, nil);

db_req(#httpd{method='POST',path_parts=[_,<<"_all_docs">>]}=Req, Db) ->
    {Fields} = couch_httpd:json_body_obj(Req),
    case proplists:get_value(<<"keys">>, Fields, nil) of
    nil ->
        ?LOG_DEBUG("POST to _all_docs with no keys member.", []),
        all_docs_view(Req, Db, nil);
    Keys when is_list(Keys) ->
        all_docs_view(Req, Db, Keys);
    _ ->
        throw({bad_request, "`keys` member must be a array."})
    end;

db_req(#httpd{path_parts=[_,<<"_all_docs">>]}=Req, _Db) ->
    send_method_not_allowed(Req, "GET,HEAD,POST");

db_req(#httpd{method='POST',path_parts=[_,<<"_missing_revs">>]}=Req, Db) ->
    {JsonDocIdRevs} = couch_httpd:json_body_obj(Req),
    JsonDocIdRevs2 = [{Id, [couch_doc:parse_rev(RevStr) || RevStr <- RevStrs]} || {Id, RevStrs} <- JsonDocIdRevs],
    {ok, Results} = couch_db:get_missing_revs(Db, JsonDocIdRevs2),
    Results2 = [{Id, [couch_doc:rev_to_str(Rev) || Rev <- Revs]} || {Id, Revs} <- Results],
    send_json(Req, {[
        {missing_revs, {Results2}}
    ]});

db_req(#httpd{path_parts=[_,<<"_missing_revs">>]}=Req, _Db) ->
    send_method_not_allowed(Req, "POST");

db_req(#httpd{method='PUT',path_parts=[_,<<"_admins">>]}=Req,
        Db) ->
    Admins = couch_httpd:json_body(Req),
    ok = couch_db:set_admins(Db, Admins),
    send_json(Req, {[{<<"ok">>, true}]});

db_req(#httpd{method='GET',path_parts=[_,<<"_admins">>]}=Req, Db) ->
    send_json(Req, couch_db:get_admins(Db));

db_req(#httpd{path_parts=[_,<<"_admins">>]}=Req, _Db) ->
    send_method_not_allowed(Req, "PUT,GET");

db_req(#httpd{method='PUT',path_parts=[_,<<"_revs_limit">>]}=Req,
        Db) ->
    Limit = couch_httpd:json_body(Req),
    ok = couch_db:set_revs_limit(Db, Limit),
    send_json(Req, {[{<<"ok">>, true}]});

db_req(#httpd{method='GET',path_parts=[_,<<"_revs_limit">>]}=Req, Db) ->
    send_json(Req, couch_db:get_revs_limit(Db));

db_req(#httpd{path_parts=[_,<<"_revs_limit">>]}=Req, _Db) ->
    send_method_not_allowed(Req, "PUT,GET");

% Special case to enable using an unencoded slash in the URL of design docs,
% as slashes in document IDs must otherwise be URL encoded.
db_req(#httpd{method='GET',mochi_req=MochiReq, path_parts=[DbName,<<"_design/",_/binary>>|_]}=Req, _Db) ->
    PathFront = "/" ++ couch_httpd:quote(binary_to_list(DbName)) ++ "/",
    [PathFront|PathTail] = re:split(MochiReq:get(raw_path), "_design%2F",
        [{return, list}]),
    couch_httpd:send_redirect(Req, PathFront ++ "_design/" ++
        mochiweb_util:join(PathTail, "_design%2F"));

db_req(#httpd{path_parts=[_DbName,<<"_design">>,Name]}=Req, Db) ->
    db_doc_req(Req, Db, <<"_design/",Name/binary>>);

db_req(#httpd{path_parts=[_DbName,<<"_design">>,Name|FileNameParts]}=Req, Db) ->
    db_attachment_req(Req, Db, <<"_design/",Name/binary>>, FileNameParts);


% Special case to allow for accessing local documents without %2F
% encoding the docid. Throws out requests that don't have the second
% path part or that specify an attachment name.
db_req(#httpd{path_parts=[_DbName, <<"_local">>]}, _Db) ->
    throw({bad_request, <<"Invalid _local document id.">>});

db_req(#httpd{path_parts=[_DbName, <<"_local/">>]}, _Db) ->
    throw({bad_request, <<"Invalid _local document id.">>});

db_req(#httpd{path_parts=[_DbName, <<"_local">>, Name]}=Req, Db) ->
    db_doc_req(Req, Db, <<"_local/", Name/binary>>);

db_req(#httpd{path_parts=[_DbName, <<"_local">> | _Rest]}, _Db) ->
    throw({bad_request, <<"_local documents do not accept attachments.">>});

db_req(#httpd{path_parts=[_, DocId]}=Req, Db) ->
    db_doc_req(Req, Db, DocId);

db_req(#httpd{path_parts=[_, DocId | FileNameParts]}=Req, Db) ->
    db_attachment_req(Req, Db, DocId, FileNameParts).

all_docs_view(Req, Db, Keys) ->
    #view_query_args{
        start_key = StartKey,
        start_docid = StartDocId,
        end_key = EndKey,
        end_docid = EndDocId,
        limit = Limit,
        skip = SkipCount,
        direction = Dir,
        inclusive_end = Inclusive
    } = QueryArgs = couch_httpd_view:parse_view_params(Req, Keys, map),
    {ok, Info} = couch_db:get_db_info(Db),
    CurrentEtag = couch_httpd:make_etag(Info),
    couch_httpd:etag_respond(Req, CurrentEtag, fun() ->

        TotalRowCount = proplists:get_value(doc_count, Info),
        StartId = if is_binary(StartKey) -> StartKey;
        true -> StartDocId
        end,
        EndId = if is_binary(EndKey) -> EndKey;
        true -> EndDocId
        end,
        FoldAccInit = {Limit, SkipCount, undefined, []},

        case Keys of
        nil ->
            FoldlFun = couch_httpd_view:make_view_fold_fun(Req, QueryArgs, CurrentEtag, Db,
                TotalRowCount, #view_fold_helper_funs{
                    reduce_count = fun couch_db:enum_docs_reduce_to_count/1
                }),
            AdapterFun = fun(#full_doc_info{id=Id}=FullDocInfo, Offset, Acc) ->
                case couch_doc:to_doc_info(FullDocInfo) of
                #doc_info{revs=[#rev_info{deleted=false, rev=Rev}|_]} ->
                    FoldlFun({{Id, Id}, {[{rev, couch_doc:rev_to_str(Rev)}]}}, Offset, Acc);
                #doc_info{revs=[#rev_info{deleted=true}|_]} ->
                    {ok, Acc}
                end
            end,
            {ok, LastOffset, FoldResult} = couch_db:enum_docs(Db,
                AdapterFun, FoldAccInit, [{start_key, StartId}, {dir, Dir},
                    {if Inclusive -> end_key; true -> end_key_gt end, EndId}]),
            couch_httpd_view:finish_view_fold(Req, TotalRowCount, LastOffset, FoldResult);
        _ ->
            FoldlFun = couch_httpd_view:make_view_fold_fun(Req, QueryArgs, CurrentEtag, Db,
                TotalRowCount, #view_fold_helper_funs{
                    reduce_count = fun(Offset) -> Offset end
                }),
            KeyFoldFun = case Dir of
            fwd ->
                fun lists:foldl/3;
            rev ->
                fun lists:foldr/3
            end,
            FoldResult = KeyFoldFun(
                fun(Key, FoldAcc) ->
                    DocInfo = (catch couch_db:get_doc_info(Db, Key)),
                    Doc = case DocInfo of
                    {ok, #doc_info{id=Id, revs=[#rev_info{deleted=false, rev=Rev}|_]}} ->
                        {{Id, Id}, {[{rev, couch_doc:rev_to_str(Rev)}]}};
                    {ok, #doc_info{id=Id, revs=[#rev_info{deleted=true, rev=Rev}|_]}} ->
                        {{Id, Id}, {[{rev, couch_doc:rev_to_str(Rev)}, {deleted, true}]}};
                    not_found ->
                        {{Key, error}, not_found};
                    _ ->
                        ?LOG_ERROR("Invalid DocInfo: ~p", [DocInfo]),
                        throw({error, invalid_doc_info})
                    end,
                    {_, FoldAcc2} = FoldlFun(Doc, 0, FoldAcc),
                    FoldAcc2
                end, FoldAccInit, Keys),
            couch_httpd_view:finish_view_fold(Req, TotalRowCount, 0, FoldResult)
        end
    end).

db_doc_req(#httpd{method='DELETE'}=Req, Db, DocId) ->
    % check for the existence of the doc to handle the 404 case.
    couch_doc_open(Db, DocId, nil, []),
    case couch_httpd:qs_value(Req, "rev") of
    undefined ->
        update_doc(Req, Db, DocId, {[{<<"_deleted">>,true}]});
    Rev ->
        update_doc(Req, Db, DocId, {[{<<"_rev">>, ?l2b(Rev)},{<<"_deleted">>,true}]})
    end;

db_doc_req(#httpd{method='GET'}=Req, Db, DocId) ->
    #doc_query_args{
        show = Format,
        rev = Rev,
        open_revs = Revs,
        options = Options
    } = parse_doc_query(Req),
    case Format of
    nil ->
        case Revs of
        [] ->
            Doc = couch_doc_open(Db, DocId, Rev, Options),
            DiskEtag = couch_httpd:doc_etag(Doc),
            case Doc#doc.meta of
            [] ->
                % output etag only when we have no meta
                couch_httpd:etag_respond(Req, DiskEtag, fun() -> 
                    send_json(Req, 200, [{"Etag", DiskEtag}], couch_doc:to_json_obj(Doc, Options))
                end);
            _ ->
                send_json(Req, 200, [], couch_doc:to_json_obj(Doc, Options))
            end;
        _ ->
            {ok, Results} = couch_db:open_doc_revs(Db, DocId, Revs, Options),
            {ok, Resp} = start_json_response(Req, 200),
            send_chunk(Resp, "["),
            % We loop through the docs. The first time through the separator
            % is whitespace, then a comma on subsequent iterations.
            lists:foldl(
                fun(Result, AccSeparator) ->
                    case Result of
                    {ok, Doc} ->
                        JsonDoc = couch_doc:to_json_obj(Doc, Options),
                        Json = ?JSON_ENCODE({[{ok, JsonDoc}]}),
                        send_chunk(Resp, AccSeparator ++ Json);
                    {{not_found, missing}, RevId} ->
                        Json = ?JSON_ENCODE({[{"missing", RevId}]}),
                        send_chunk(Resp, AccSeparator ++ Json)
                    end,
                    "," % AccSeparator now has a comma
                end,
                "", Results),
            send_chunk(Resp, "]"),
            end_json_response(Resp)
        end;
    _ ->
        {DesignName, ShowName} = Format,
        couch_httpd_show:handle_doc_show(Req, DesignName, ShowName, DocId, Db)
    end;

db_doc_req(#httpd{method='POST'}=Req, Db, DocId) ->
    couch_doc:validate_docid(DocId),
    case couch_httpd:header_value(Req, "content-type") of
    "multipart/form-data" ++  _Rest ->
        ok;
    _Else ->
        throw({bad_ctype, <<"Invalid Content-Type header for form upload">>})
    end,
    Form = couch_httpd:parse_form(Req),
    Rev = couch_doc:parse_rev(list_to_binary(proplists:get_value("_rev", Form))),
    {ok, [{ok, Doc}]} = couch_db:open_doc_revs(Db, DocId, [Rev], []),

    UpdatedAtts = [
        #att{name=validate_attachment_name(Name),
            type=list_to_binary(ContentType),
            data=Content} ||
        {Name, {ContentType, _}, Content} <-
        proplists:get_all_values("_attachments", Form)
    ],
    #doc{atts=OldAtts} = Doc,
    OldAtts2 = lists:flatmap(
        fun(#att{name=OldName}=Att) ->
            case [1 || A <- UpdatedAtts, A#att.name == OldName] of
            [] -> [Att]; % the attachment wasn't in the UpdatedAtts, return it
            _ -> [] % the attachment was in the UpdatedAtts, drop it
            end
        end, OldAtts),
    NewDoc = Doc#doc{
        atts = UpdatedAtts ++ OldAtts2
    },
    {ok, NewRev} = couch_db:update_doc(Db, NewDoc, []),

    send_json(Req, 201, [{"Etag", "\"" ++ ?b2l(couch_doc:rev_to_str(NewRev)) ++ "\""}], {[
        {ok, true},
        {id, DocId},
        {rev, couch_doc:rev_to_str(NewRev)}
    ]});

db_doc_req(#httpd{method='PUT'}=Req, Db, DocId) ->
    couch_doc:validate_docid(DocId),
    Json = couch_httpd:json_body(Req),
    case couch_httpd:qs_value(Req, "batch") of
    "ok" ->
        % batch
        Doc = couch_doc_from_req(Req, DocId, Json),
        ok = couch_batch_save:eventually_save_doc(Db#db.name, Doc, Db#db.user_ctx),
        send_json(Req, 202, [], {[
            {ok, true},
            {id, DocId}
        ]});
    _Normal ->
        % normal
        Location = absolute_uri(Req, "/" ++ ?b2l(Db#db.name) ++ "/" ++ ?b2l(DocId)),
        update_doc(Req, Db, DocId, Json, [{"Location", Location}])
    end;

db_doc_req(#httpd{method='COPY'}=Req, Db, SourceDocId) ->
    SourceRev =
    case extract_header_rev(Req, couch_httpd:qs_value(Req, "rev")) of
        missing_rev -> nil;
        Rev -> Rev
    end,
    {TargetDocId, TargetRevs} = parse_copy_destination_header(Req),
    % open old doc
    Doc = couch_doc_open(Db, SourceDocId, SourceRev, []),
    % save new doc
    {ok, NewTargetRev} = couch_db:update_doc(Db,
        Doc#doc{id=TargetDocId, revs=TargetRevs}, []),
    % respond
    send_json(Req, 201,
        [{"Etag", "\"" ++ ?b2l(couch_doc:rev_to_str(NewTargetRev)) ++ "\""}],
        update_doc_result_to_json(TargetDocId, {ok, NewTargetRev}));

db_doc_req(Req, _Db, _DocId) ->
    send_method_not_allowed(Req, "DELETE,GET,HEAD,POST,PUT,COPY").


update_doc_result_to_json({{Id, Rev}, Error}) ->
        {_Code, Err, Msg} = couch_httpd:error_info(Error),
        {[{id, Id}, {rev, couch_doc:rev_to_str(Rev)},
            {error, Err}, {reason, Msg}]}.

update_doc_result_to_json(#doc{id=DocId}, Result) ->
    update_doc_result_to_json(DocId, Result);
update_doc_result_to_json(DocId, {ok, NewRev}) ->
    {[{id, DocId}, {rev, couch_doc:rev_to_str(NewRev)}]};
update_doc_result_to_json(DocId, Error) ->
    {_Code, ErrorStr, Reason} = couch_httpd:error_info(Error),
    {[{id, DocId}, {error, ErrorStr}, {reason, Reason}]}.


update_doc(Req, Db, DocId, Json) ->
    update_doc(Req, Db, DocId, Json, []).

update_doc(Req, Db, DocId, Json, Headers) ->
    #doc{deleted=Deleted} = Doc = couch_doc_from_req(Req, DocId, Json),

    case couch_httpd:header_value(Req, "X-Couch-Full-Commit") of
    "true" ->
        Options = [full_commit];
    "false" ->
        Options = [delay_commit];
    _ ->
        Options = []
    end,
    {ok, NewRev} = couch_db:update_doc(Db, Doc, Options),
    NewRevStr = couch_doc:rev_to_str(NewRev),
    ResponseHeaders = [{"Etag", <<"\"", NewRevStr/binary, "\"">>}] ++ Headers,
    send_json(Req, if Deleted -> 200; true -> 201 end,
        ResponseHeaders, {[
            {ok, true},
            {id, DocId},
            {rev, NewRevStr}]}).

couch_doc_from_req(Req, DocId, Json) ->
    Doc = couch_doc:from_json_obj(Json),
    validate_attachment_names(Doc),
    ExplicitDocRev =
    case Doc#doc.revs of
        {Start,[RevId|_]} -> {Start, RevId};
        _ -> undefined
    end,
    case extract_header_rev(Req, ExplicitDocRev) of
    missing_rev ->
        Revs = {0, []};
    {Pos, Rev} ->
        Revs = {Pos, [Rev]}
    end,
    Doc#doc{id=DocId, revs=Revs}.


% Useful for debugging
% couch_doc_open(Db, DocId) ->
%   couch_doc_open(Db, DocId, nil, []).

couch_doc_open(Db, DocId, Rev, Options) ->
    case Rev of
    nil -> % open most recent rev
        case couch_db:open_doc(Db, DocId, Options) of
        {ok, Doc} ->
            Doc;
         Error ->
             throw(Error)
         end;
  _ -> % open a specific rev (deletions come back as stubs)
      case couch_db:open_doc_revs(Db, DocId, [Rev], Options) of
          {ok, [{ok, Doc}]} ->
              Doc;
          {ok, [Else]} ->
              throw(Else)
      end
  end.

% Attachment request handlers

db_attachment_req(#httpd{method='GET'}=Req, Db, DocId, FileNameParts) ->
    FileName = list_to_binary(mochiweb_util:join(lists:map(fun binary_to_list/1, FileNameParts),"/")),
    #doc_query_args{
        rev=Rev,
        options=Options
    } = parse_doc_query(Req),
    #doc{
        atts=Atts
    } = Doc = couch_doc_open(Db, DocId, Rev, Options),
    case [A || A <- Atts, A#att.name == FileName] of
    [] ->
        throw({not_found, "Document is missing attachment"});
    [#att{type=Type, len=Len}=Att] ->
        Etag = couch_httpd:doc_etag(Doc),
        couch_httpd:etag_respond(Req, Etag, fun() ->
            {ok, Resp} = start_response_length(Req, 200, [
                {"ETag", Etag},
                {"Cache-Control", "must-revalidate"},
                {"Content-Type", binary_to_list(Type)}
                ], integer_to_list(Len)),
            couch_doc:att_foldl(Att,
                    fun(BinSegment, _) -> send(Resp, BinSegment) end,[])
        end)
    end;


db_attachment_req(#httpd{method=Method}=Req, Db, DocId, FileNameParts)
        when (Method == 'PUT') or (Method == 'DELETE') ->
    FileName = validate_attachment_name(
                    mochiweb_util:join(
                        lists:map(fun binary_to_list/1,
                            FileNameParts),"/")),

    NewAtt = case Method of
        'DELETE' ->
            [];
        _ ->
            [#att{
                name=FileName,
                type = case couch_httpd:header_value(Req,"Content-Type") of
                    undefined ->
                        % We could throw an error here or guess by the FileName.
                        % Currently, just giving it a default.
                        <<"application/octet-stream">>;
                    CType ->
                        list_to_binary(CType)
                    end,
                data = case couch_httpd:body_length(Req) of
                    undefined ->
                        <<"">>;
                    {unknown_transfer_encoding, Unknown} ->
                        exit({unknown_transfer_encoding, Unknown});
                    chunked ->
                        fun(MaxChunkSize, ChunkFun, InitState) ->
                            couch_httpd:recv_chunked(Req, MaxChunkSize,
                                ChunkFun, InitState)
                        end;
                    0 ->
                        <<"">>;
                    Length when is_integer(Length) ->
                        fun() -> couch_httpd:recv(Req, 0) end;
                    Length ->
                        exit({length_not_integer, Length})
                    end,
                len = case couch_httpd:header_value(Req,"Content-Length") of
                    undefined ->
                        undefined;
                    Length ->
                        list_to_integer(Length)
                    end
                    }]
    end,

    Doc = case extract_header_rev(Req, couch_httpd:qs_value(Req, "rev")) of
        missing_rev -> % make the new doc
            #doc{id=DocId};
        Rev ->
            case couch_db:open_doc_revs(Db, DocId, [Rev], []) of
            {ok, [{ok, Doc0}]}  -> Doc0;
            {ok, [Error]}       -> throw(Error)
            end
    end,

    #doc{atts=Atts} = Doc,
    DocEdited = Doc#doc{
        atts = NewAtt ++ [A || A <- Atts, A#att.name /= FileName]
    },
    {ok, UpdatedRev} = couch_db:update_doc(Db, DocEdited, []),
    #db{name=DbName} = Db,

    {Status, Headers} = case Method of
        'DELETE' ->
            {200, []};
        _ ->
            {201, [{"Location", absolute_uri(Req, "/" ++
                binary_to_list(DbName) ++ "/" ++
                binary_to_list(DocId) ++ "/" ++
                binary_to_list(FileName)
            )}]}
        end,
    send_json(Req,Status, Headers, {[
        {ok, true},
        {id, DocId},
        {rev, couch_doc:rev_to_str(UpdatedRev)}
    ]});

db_attachment_req(Req, _Db, _DocId, _FileNameParts) ->
    send_method_not_allowed(Req, "DELETE,GET,HEAD,PUT").

parse_doc_format(FormatStr) when is_binary(FormatStr) ->
    parse_doc_format(?b2l(FormatStr));
parse_doc_format(FormatStr) when is_list(FormatStr) ->
    SplitFormat = lists:splitwith(fun($/) -> false; (_) -> true end, FormatStr),
    case SplitFormat of
        {DesignName, [$/ | ShowName]} -> {?l2b(DesignName), ?l2b(ShowName)};
        _Else -> throw({bad_request, <<"Invalid doc format">>})
    end;
parse_doc_format(_BadFormatStr) ->
    throw({bad_request, <<"Invalid doc format">>}).

parse_doc_query(Req) ->
    lists:foldl(fun({Key,Value}, Args) ->
        case {Key, Value} of
        {"attachments", "true"} ->
            Options = [attachments | Args#doc_query_args.options],
            Args#doc_query_args{options=Options};
        {"meta", "true"} ->
            Options = [revs_info, conflicts, deleted_conflicts | Args#doc_query_args.options],
            Args#doc_query_args{options=Options};
        {"revs", "true"} ->
            Options = [revs | Args#doc_query_args.options],
            Args#doc_query_args{options=Options};
        {"local_seq", "true"} ->
            Options = [local_seq | Args#doc_query_args.options],
            Args#doc_query_args{options=Options};
        {"revs_info", "true"} ->
            Options = [revs_info | Args#doc_query_args.options],
            Args#doc_query_args{options=Options};
        {"conflicts", "true"} ->
            Options = [conflicts | Args#doc_query_args.options],
            Args#doc_query_args{options=Options};
        {"deleted_conflicts", "true"} ->
            Options = [deleted_conflicts | Args#doc_query_args.options],
            Args#doc_query_args{options=Options};
        {"rev", Rev} ->
            Args#doc_query_args{rev=couch_doc:parse_rev(Rev)};
        {"open_revs", "all"} ->
            Args#doc_query_args{open_revs=all};
        {"open_revs", RevsJsonStr} ->
            JsonArray = ?JSON_DECODE(RevsJsonStr),
            Args#doc_query_args{open_revs=[couch_doc:parse_rev(Rev) || Rev <- JsonArray]};
        {"show", FormatStr} ->
            Args#doc_query_args{show=parse_doc_format(FormatStr)};
        _Else -> % unknown key value pair, ignore.
            Args
        end
    end, #doc_query_args{}, couch_httpd:qs(Req)).


extract_header_rev(Req, ExplicitRev) when is_binary(ExplicitRev) or is_list(ExplicitRev)->
    extract_header_rev(Req, couch_doc:parse_rev(ExplicitRev));
extract_header_rev(Req, ExplicitRev) ->
    Etag = case couch_httpd:header_value(Req, "If-Match") of
        undefined -> undefined;
        Value -> couch_doc:parse_rev(string:strip(Value, both, $"))
    end,
    case {ExplicitRev, Etag} of
    {undefined, undefined} -> missing_rev;
    {_, undefined} -> ExplicitRev;
    {undefined, _} -> Etag;
    _ when ExplicitRev == Etag -> Etag;
    _ ->
        throw({bad_request, "Document rev and etag have different values"})
    end.


parse_copy_destination_header(Req) ->
    Destination = couch_httpd:header_value(Req, "Destination"),
    case re:run(Destination, "\\?", [{capture, none}]) of
    nomatch ->
        {list_to_binary(Destination), {0, []}};
    match ->
        [DocId, RevQs] = re:split(Destination, "\\?", [{return, list}]),
        [_RevQueryKey, Rev] = re:split(RevQs, "=", [{return, list}]),
        {Pos, RevId} = couch_doc:parse_rev(Rev),
        {list_to_binary(DocId), {Pos, [RevId]}}
    end.

validate_attachment_names(Doc) ->
    lists:foreach(fun(#att{name=Name}) ->
        validate_attachment_name(Name)
    end, Doc#doc.atts).

validate_attachment_name(Name) when is_list(Name) ->
    validate_attachment_name(list_to_binary(Name));
validate_attachment_name(<<"_",_/binary>>) ->
    throw({bad_request, <<"Attachment name can't start with '_'">>});
validate_attachment_name(Name) ->
    case is_valid_utf8(Name) of
        true -> Name;
        false -> throw({bad_request, <<"Attachment name is not UTF-8 encoded">>})
    end.

%% borrowed from mochijson2:json_bin_is_safe()
is_valid_utf8(<<>>) ->
    true;
is_valid_utf8(<<C, Rest/binary>>) ->
    case C of
        $\" ->
            false;
        $\\ ->
            false;
        $\b ->
            false;
        $\f ->
            false;
        $\n ->
            false;
        $\r ->
            false;
        $\t ->
            false;
        C when C >= 0, C < $\s; C >= 16#7f, C =< 16#10FFFF ->
            false;
        C when C < 16#7f ->
            is_valid_utf8(Rest);
        _ ->
            false
    end.
