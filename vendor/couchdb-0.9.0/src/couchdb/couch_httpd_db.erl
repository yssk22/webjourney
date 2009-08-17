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

-module(couch_httpd_db).
-include("couch_db.hrl").

-export([handle_request/1, handle_design_req/2, db_req/2, couch_doc_open/4]).

-import(couch_httpd,
    [send_json/2,send_json/3,send_json/4,send_method_not_allowed/2,
    start_json_response/2,send_chunk/2,end_json_response/1,
    start_chunked_response/3, absolute_uri/2]).

-record(doc_query_args, {
    options = [],
    rev = nil,
    open_revs = []
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

handle_design_req(#httpd{
        path_parts=[_DbName,_Design,_DesName, <<"_",_/binary>> = Action | _Rest],
        design_url_handlers = DesignUrlHandlers
    }=Req, Db) ->
    Handler = couch_util:dict_find(Action, DesignUrlHandlers, fun db_req/2),
    Handler(Req, Db);
    
handle_design_req(Req, Db) ->
    db_req(Req, Db).

create_db_req(#httpd{user_ctx=UserCtx}=Req, DbName) ->
    ok = couch_httpd:verify_is_server_admin(Req),
    case couch_server:create(DbName, [{user_ctx, UserCtx}]) of
    {ok, Db} ->
        couch_db:close(Db),
        send_json(Req, 201, {[{ok, true}]});
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
            couch_db:close(Db)
        end;
    Error ->
        throw(Error)
    end.

db_req(#httpd{method='GET',path_parts=[_DbName]}=Req, Db) ->
    {ok, DbInfo} = couch_db:get_db_info(Db),
    send_json(Req, {DbInfo});

db_req(#httpd{method='POST',path_parts=[DbName]}=Req, Db) ->
    Doc = couch_doc:from_json_obj(couch_httpd:json_body(Req)),
    DocId = couch_util:new_uuid(),
    {ok, NewRev} = couch_db:update_doc(Db, Doc#doc{id=DocId}, []),
    DocUrl = absolute_uri(Req, 
        binary_to_list(<<"/",DbName/binary,"/",DocId/binary>>)),
    send_json(Req, 201, [{"Location", DocUrl}], {[
        {ok, true},
        {id, DocId},
        {rev, couch_doc:rev_to_str(NewRev)}
    ]});

db_req(#httpd{path_parts=[_DbName]}=Req, _Db) ->
    send_method_not_allowed(Req, "DELETE,GET,HEAD,POST");

db_req(#httpd{method='POST',path_parts=[_,<<"_ensure_full_commit">>]}=Req, Db) ->
    {ok, DbStartTime} = couch_db:ensure_full_commit(Db),
    send_json(Req, 201, {[
            {ok, true},
            {instance_start_time, DbStartTime}
        ]});
    
db_req(#httpd{path_parts=[_,<<"_ensure_full_commit">>]}=Req, _Db) ->
    send_method_not_allowed(Req, "POST");

db_req(#httpd{method='POST',path_parts=[_,<<"_bulk_docs">>]}=Req, Db) ->
    couch_stats_collector:increment({httpd, bulk_requests}),
    {JsonProps} = couch_httpd:json_body(Req),
    DocsArray = proplists:get_value(<<"docs">>, JsonProps),
    case couch_httpd:header_value(Req, "X-Couch-Full-Commit", "false") of
    "true" ->
        Options = [full_commit];
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
                    <<>> -> couch_util:new_uuid();
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
            DocResults = lists:zipwith(
                fun(Doc, {ok, NewRev}) ->
                    {[{<<"id">>, Doc#doc.id}, {<<"rev">>, couch_doc:rev_to_str(NewRev)}]};
                (Doc, Error) ->
                    {_Code, Err, Msg} = couch_httpd:error_info(Error),
                    % maybe we should add the http error code to the json?
                    {[{<<"id">>, Doc#doc.id}, {<<"error">>, Err}, {"reason", Msg}]}
                end,
                Docs, Results),
            send_json(Req, 201, DocResults);
        {aborted, Errors} ->
            ErrorsJson = 
                lists:map(
                    fun({{Id, Rev}, Error}) ->
                        {_Code, Err, Msg} = couch_httpd:error_info(Error),
                        {[{<<"id">>, Id},
                            {<<"rev">>, couch_doc:rev_to_str(Rev)},
                            {<<"error">>, Err},
                            {"reason", Msg}]}
                    end, Errors),
            send_json(Req, 417, ErrorsJson)
        end;
    false ->
        Docs = [couch_doc:from_json_obj(JsonObj) || JsonObj <- DocsArray],
        {ok, Errors} = couch_db:update_docs(Db, Docs, Options, replicated_changes),
        ErrorsJson = 
            lists:map(
                fun({{Id, Rev}, Error}) ->
                    {_Code, Err, Msg} = couch_httpd:error_info(Error),
                    {[{<<"id">>, Id},
                        {<<"rev">>, couch_doc:rev_to_str(Rev)},
                        {<<"error">>, Err},
                        {"reason", Msg}]}
                end, Errors),
        send_json(Req, 201, ErrorsJson)
    end;
db_req(#httpd{path_parts=[_,<<"_bulk_docs">>]}=Req, _Db) ->
    send_method_not_allowed(Req, "POST");

db_req(#httpd{method='POST',path_parts=[_,<<"_compact">>]}=Req, Db) ->
    ok = couch_db:start_compact(Db),
    send_json(Req, 202, {[{ok, true}]});

db_req(#httpd{path_parts=[_,<<"_compact">>]}=Req, _Db) ->
    send_method_not_allowed(Req, "POST");

db_req(#httpd{method='POST',path_parts=[_,<<"_purge">>]}=Req, Db) ->
    {IdsRevs} = couch_httpd:json_body(Req),
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
    {Props} = couch_httpd:json_body(Req),
    Keys = proplists:get_value(<<"keys">>, Props, nil),
    all_docs_view(Req, Db, Keys);

db_req(#httpd{path_parts=[_,<<"_all_docs">>]}=Req, _Db) ->
    send_method_not_allowed(Req, "GET,HEAD,POST");

db_req(#httpd{method='GET',path_parts=[_,<<"_all_docs_by_seq">>]}=Req, Db) ->
    #view_query_args{
        start_key = StartKey,
        limit = Limit,
        skip = SkipCount,
        direction = Dir
    } = QueryArgs = couch_httpd_view:parse_view_query(Req),

    {ok, Info} = couch_db:get_db_info(Db),
    CurrentEtag = couch_httpd:make_etag(proplists:get_value(update_seq, Info)),
    couch_httpd:etag_respond(Req, CurrentEtag, fun() ->
        TotalRowCount = proplists:get_value(doc_count, Info),
        FoldlFun = couch_httpd_view:make_view_fold_fun(Req, QueryArgs, CurrentEtag, Db,
            TotalRowCount, #view_fold_helper_funs{
                reduce_count = fun couch_db:enum_docs_since_reduce_to_count/1
            }),
        StartKey2 = case StartKey of
            nil -> 0;
            <<>> -> 100000000000;
            {} -> 100000000000;
            StartKey when is_integer(StartKey) -> StartKey
        end,
        {ok, FoldResult} = couch_db:enum_docs_since(Db, StartKey2, Dir,
            fun(DocInfo, Offset, Acc) ->
                #doc_info{
                    id=Id,
                    rev=Rev,
                    update_seq=UpdateSeq,
                    deleted=Deleted,
                    conflict_revs=ConflictRevs,
                    deleted_conflict_revs=DelConflictRevs
                } = DocInfo,
                Json = {
                    [{<<"rev">>, couch_doc:rev_to_str(Rev)}] ++
                    case ConflictRevs of
                        []  ->  [];
                        _   ->  [{<<"conflicts">>, couch_doc:rev_to_strs(ConflictRevs)}]
                    end ++
                    case DelConflictRevs of
                        []  ->  [];
                        _   ->  [{<<"deleted_conflicts">>, couch_doc:rev_to_strs(DelConflictRevs)}]
                    end ++
                    case Deleted of
                        true -> [{<<"deleted">>, true}];
                        false -> []
                    end
                },
                FoldlFun({{UpdateSeq, Id}, Json}, Offset, Acc)
            end, {Limit, SkipCount, undefined, []}),
        couch_httpd_view:finish_view_fold(Req, TotalRowCount, {ok, FoldResult})
    end);

db_req(#httpd{path_parts=[_,<<"_all_docs_by_seq">>]}=Req, _Db) ->
    send_method_not_allowed(Req, "GET,HEAD");

db_req(#httpd{method='POST',path_parts=[_,<<"_missing_revs">>]}=Req, Db) ->
    {JsonDocIdRevs} = couch_httpd:json_body(Req),
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
    RawSplit = regexp:split(MochiReq:get(raw_path),"_design%2F"),
    {ok, [PathFront|PathTail]} = RawSplit,
    couch_httpd:send_redirect(Req, PathFront ++ "_design/" ++ 
        mochiweb_util:join(PathTail, "_design%2F"));

db_req(#httpd{path_parts=[_DbName,<<"_design">>,Name]}=Req, Db) ->
    db_doc_req(Req, Db, <<"_design/",Name/binary>>);
    
db_req(#httpd{path_parts=[_DbName,<<"_design">>,Name|FileNameParts]}=Req, Db) ->
    db_attachment_req(Req, Db, <<"_design/",Name/binary>>, FileNameParts);


db_req(#httpd{path_parts=[_, DocId]}=Req, Db) ->
    db_doc_req(Req, Db, DocId);

db_req(#httpd{path_parts=[_, DocId | FileNameParts]}=Req, Db) ->
    db_attachment_req(Req, Db, DocId, FileNameParts).

all_docs_view(Req, Db, Keys) -> 
    #view_query_args{
        start_key = StartKey,
        start_docid = StartDocId,
        end_key = EndKey,
        limit = Limit,
        skip = SkipCount,
        direction = Dir
    } = QueryArgs = couch_httpd_view:parse_view_query(Req, Keys),    
    {ok, Info} = couch_db:get_db_info(Db),
    CurrentEtag = couch_httpd:make_etag(proplists:get_value(update_seq, Info)),
    couch_httpd:etag_respond(Req, CurrentEtag, fun() -> 
    
        TotalRowCount = proplists:get_value(doc_count, Info),
        StartId = if is_binary(StartKey) -> StartKey;
        true -> StartDocId
        end,
        FoldAccInit = {Limit, SkipCount, undefined, []},
    
        PassedEndFun = 
        case Dir of
        fwd ->
            fun(ViewKey, _ViewId) ->
                couch_db_updater:less_docid(EndKey, ViewKey)
            end;
        rev->
            fun(ViewKey, _ViewId) ->
                couch_db_updater:less_docid(ViewKey, EndKey)
            end
        end,
    
        case Keys of
        nil ->
            FoldlFun = couch_httpd_view:make_view_fold_fun(Req, QueryArgs, CurrentEtag, Db,
                TotalRowCount, #view_fold_helper_funs{
                    reduce_count = fun couch_db:enum_docs_reduce_to_count/1,
                    passed_end = PassedEndFun
                }),
            AdapterFun = fun(#full_doc_info{id=Id}=FullDocInfo, Offset, Acc) ->
                case couch_doc:to_doc_info(FullDocInfo) of
                #doc_info{deleted=false, rev=Rev} ->
                    FoldlFun({{Id, Id}, {[{rev, couch_doc:rev_to_str(Rev)}]}}, Offset, Acc);
                #doc_info{deleted=true} ->
                    {ok, Acc}
                end
            end,
            {ok, FoldResult} = couch_db:enum_docs(Db, StartId, Dir, 
                AdapterFun, FoldAccInit),
            couch_httpd_view:finish_view_fold(Req, TotalRowCount, {ok, FoldResult});
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
            {ok, FoldResult} = KeyFoldFun(
                fun(Key, {ok, FoldAcc}) ->
                    DocInfo = (catch couch_db:get_doc_info(Db, Key)),
                    Doc = case DocInfo of
                    {ok, #doc_info{id=Id, rev=Rev, deleted=false}} = DocInfo ->
                        {{Id, Id}, {[{rev, couch_doc:rev_to_str(Rev)}]}};
                    {ok, #doc_info{id=Id, rev=Rev, deleted=true}} = DocInfo ->
                        {{Id, Id}, {[{rev, couch_doc:rev_to_str(Rev)}, {deleted, true}]}};
                    not_found ->
                        {{Key, error}, not_found};
                    _ ->
                        ?LOG_ERROR("Invalid DocInfo: ~p", [DocInfo]),
                        throw({error, invalid_doc_info})
                    end,
                    Acc = (catch FoldlFun(Doc, 0, FoldAcc)),
                    case Acc of
                    {stop, Acc2} ->
                        {ok, Acc2};
                    _ ->
                        Acc
                    end
                end, {ok, FoldAccInit}, Keys),
            couch_httpd_view:finish_view_fold(Req, TotalRowCount, {ok, FoldResult})        
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
        rev = Rev,
        open_revs = Revs,
        options = Options
    } = parse_doc_query(Req),
    case Revs of
    [] ->
        Doc = couch_doc_open(Db, DocId, Rev, Options),
        DiskEtag = couch_httpd:doc_etag(Doc),
        couch_httpd:etag_respond(Req, DiskEtag, fun() -> 
            Headers = case Doc#doc.meta of
            [] -> [{"Etag", DiskEtag}]; % output etag only when we have no meta
            _ -> []
            end,
            send_json(Req, 200, Headers, couch_doc:to_json_obj(Doc, Options))
        end);
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

db_doc_req(#httpd{method='POST'}=Req, Db, DocId) ->
    Form = couch_httpd:parse_form(Req),
    Rev = couch_doc:parse_rev(list_to_binary(proplists:get_value("_rev", Form))),
    {ok, [{ok, Doc}]} = couch_db:open_doc_revs(Db, DocId, [Rev], []),

    NewAttachments = [
        {validate_attachment_name(Name), {list_to_binary(ContentType), Content}} ||
        {Name, {ContentType, _}, Content} <-
        proplists:get_all_values("_attachments", Form)
    ],
    #doc{attachments=Attachments} = Doc,
    NewDoc = Doc#doc{
        attachments = Attachments ++ NewAttachments
    },
    {ok, NewRev} = couch_db:update_doc(Db, NewDoc, []),

    send_json(Req, 201, [{"Etag", "\"" ++ ?b2l(couch_doc:rev_to_str(NewRev)) ++ "\""}], {[
        {ok, true},
        {id, DocId},
        {rev, couch_doc:rev_to_str(NewRev)}
    ]});

db_doc_req(#httpd{method='PUT'}=Req, Db, DocId) ->
    update_doc(Req, Db, DocId, couch_httpd:json_body(Req));

db_doc_req(#httpd{method='COPY'}=Req, Db, SourceDocId) ->
    SourceRev =
    case extract_header_rev(Req, couch_httpd:qs_value(Req, "rev")) of
        missing_rev -> nil;
        Rev -> Rev
    end,

    {TargetDocId, TargetRevs} = parse_copy_destination_header(Req),

    % open revision Rev or Current  
    Doc = couch_doc_open(Db, SourceDocId, SourceRev, []),
    % save new doc
    case couch_db:update_doc(Db, Doc#doc{id=TargetDocId, revs=TargetRevs}, []) of
    {ok, NewTargetRev} ->
        send_json(Req, 201, [{"Etag", "\"" ++ ?b2l(couch_doc:rev_to_str(NewTargetRev)) ++ "\""}],
            update_result_to_json({ok, NewTargetRev}));
    Error ->
        throw(Error)
    end;

db_doc_req(Req, _Db, _DocId) ->
    send_method_not_allowed(Req, "DELETE,GET,HEAD,POST,PUT,COPY").

update_result_to_json({ok, NewRev}) ->
    {[{rev, couch_doc:rev_to_str(NewRev)}]};
update_result_to_json(Error) ->
    {_Code, ErrorStr, Reason} = couch_httpd:error_info(Error),
    {[{error, ErrorStr}, {reason, Reason}]}.


update_doc(Req, Db, DocId, Json) ->
    #doc{deleted=Deleted} = Doc = couch_doc:from_json_obj(Json),
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
    
    case couch_httpd:header_value(Req, "X-Couch-Full-Commit", "false") of
    "true" ->
        Options = [full_commit];
    _ ->
        Options = []
    end,
    {ok, NewRev} = couch_db:update_doc(Db, Doc#doc{id=DocId, revs=Revs}, Options),
    NewRevStr = couch_doc:rev_to_str(NewRev),
    send_json(Req, if Deleted -> 200; true -> 201 end,
        [{"Etag", <<"\"", NewRevStr/binary, "\"">>}], {[
            {ok, true},
            {id, DocId},
            {rev, NewRevStr}]}).

% Useful for debugging
% couch_doc_open(Db, DocId) ->
%   couch_doc_open(Db, DocId, [], []).

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
    case couch_db:open_doc(Db, DocId, []) of
    {ok, #doc{attachments=Attachments}=Doc} ->
        case proplists:get_value(FileName, Attachments) of
        undefined ->
            throw({not_found, "Document is missing attachment"});
        {Type, Bin} ->
            {ok, Resp} = start_chunked_response(Req, 200, [
                {"ETag", couch_httpd:doc_etag(Doc)},
                {"Cache-Control", "must-revalidate"},
                {"Content-Type", binary_to_list(Type)}%,
                % My understanding of http://www.faqs.org/rfcs/rfc2616.html
                % says that we should not use Content-Length with a chunked
                % encoding. Turning this off makes libcurl happy, but I am
                % open to discussion.
                % {"Content-Length", integer_to_list(couch_doc:bin_size(Bin))}
                ]),
            couch_doc:bin_foldl(Bin,
                fun(BinSegment, []) ->
                    send_chunk(Resp, BinSegment),
                    {ok, []}
                end,
                []
            ),
            send_chunk(Resp, "")
        end;
    Error ->
        throw(Error)
    end;


db_attachment_req(#httpd{method=Method}=Req, Db, DocId, FileNameParts)
        when (Method == 'PUT') or (Method == 'DELETE') ->
    FileName = validate_attachment_name(
                    mochiweb_util:join(
                        lists:map(fun binary_to_list/1, 
                            FileNameParts),"/")),
    
    NewAttachment = case Method of
        'DELETE' ->
            [];
        _ ->
            % see couch_db:doc_flush_binaries for usage of this structure
            [{FileName, {
                case couch_httpd:header_value(Req,"Content-Type") of
                undefined ->
                    % We could throw an error here or guess by the FileName.
                    % Currently, just giving it a default.
                    <<"application/octet-stream">>;
                CType ->
                    list_to_binary(CType)
                end,
                case couch_httpd:header_value(Req,"Content-Length") of
                undefined -> 
                    {fun(MaxChunkSize, ChunkFun, InitState) -> 
                        couch_httpd:recv_chunked(Req, MaxChunkSize, 
                            ChunkFun, InitState) 
                    end, undefined};
                Length -> 
                    {fun() -> couch_httpd:recv(Req, 0) end,
                        list_to_integer(Length)}
                end
            }}]
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

    #doc{attachments=Attachments} = Doc,
    DocEdited = Doc#doc{
        attachments = NewAttachment ++ proplists:delete(FileName, Attachments)
    },
    {ok, UpdatedRev} = couch_db:update_doc(Db, DocEdited, []),
    send_json(Req, case Method of 'DELETE' -> 200; _ -> 201 end, {[
        {ok, true},
        {id, DocId},
        {rev, couch_doc:rev_to_str(UpdatedRev)}
    ]});

db_attachment_req(Req, _Db, _DocId, _FileNameParts) ->
    send_method_not_allowed(Req, "DELETE,GET,HEAD,PUT").


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
    case regexp:match(Destination, "\\?") of
    nomatch -> 
        {list_to_binary(Destination), {0, []}};
    {match, _, _} ->
        {ok, [DocId, RevQueryOptions]} = regexp:split(Destination, "\\?"),
        {ok, [_RevQueryKey, Rev]} = regexp:split(RevQueryOptions, "="),
        {Pos, RevId} = couch_doc:parse_rev(Rev),
        {list_to_binary(DocId), {Pos, [RevId]}}
    end.

validate_attachment_names(Doc) ->
    lists:foreach(fun({Name, _}) -> 
        validate_attachment_name(Name)
    end, Doc#doc.attachments).

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
