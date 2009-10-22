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

-module(couch_rep_att).

-export([convert_stub/2, cleanup/0]).

-include("couch_db.hrl").

convert_stub(#att{data=stub} = Attachment, {#http_db{} = Db, Id, Rev}) ->
    {Pos, [RevId|_]} = Rev,
    Name = Attachment#att.name,
    Request = Db#http_db{
        resource = lists:flatten([couch_util:url_encode(Id), "/",
            couch_util:url_encode(Name)]),
        qs = [{rev, couch_doc:rev_to_str({Pos,RevId})}]
    },
    Ref = make_ref(),
    RcvFun = fun() -> attachment_receiver(Ref, Request) end,
    Attachment#att{data=RcvFun}.

cleanup() ->
    receive 
    {ibrowse_async_response, _, _} ->
        %% TODO maybe log, didn't expect to have data here
        cleanup();
    {ibrowse_async_response_end, _} -> 
        cleanup()
    after 0 ->
        erase(),
        ok
    end.
        
% internal funs

attachment_receiver(Ref, Request) ->
    case get(Ref) of
    undefined ->
        ReqId = start_http_request(Request),
        put(Ref, ReqId),
        receive_data(Ref, ReqId);
    ReqId ->
        receive_data(Ref, ReqId)
    end.

receive_data(Ref, ReqId) ->
    receive
    {ibrowse_async_response, ReqId, {chunk_start,_}} ->
        receive_data(Ref, ReqId);
    {ibrowse_async_response, ReqId, chunk_end} ->
        receive_data(Ref, ReqId);
    {ibrowse_async_response, ReqId, {error, Err}} ->
        ?LOG_ERROR("streaming attachment ~p failed with ~p", [ReqId, Err]),
        throw({attachment_request_failed, Err});
    {ibrowse_async_response, ReqId, Data} ->
        % ?LOG_DEBUG("got ~p bytes for ~p", [size(Data), ReqId]),
        Data;
    {ibrowse_async_response_end, ReqId} ->
        ?LOG_ERROR("streaming att. ended but more data requested ~p", [ReqId]),
        throw({attachment_request_failed, premature_end})
    end.

start_http_request(Req) ->
    %% set stream_to here because self() has changed
    Req2 = Req#http_db{options = [{stream_to,self()} | Req#http_db.options]},
    {ibrowse_req_id, ReqId} = couch_rep_httpc:request(Req2),
    receive {ibrowse_async_headers, ReqId, Code, Headers} ->
        case validate_headers(Req2, list_to_integer(Code), Headers) of
        ok ->
            ReqId;
        {ok, NewReqId} ->
            NewReqId
        end
    end.

validate_headers(_Req, 200, _Headers) ->
    ok;
validate_headers(Req, Code, Headers) when Code > 299, Code < 400 ->
    %% TODO check that the qs is actually included in the Location header
    %% TODO this only supports one level of redirection
    Url = mochiweb_headers:get_value("Location",mochiweb_headers:make(Headers)),
    NewReq = Req#http_db{url=Url, resource="", qs=[]},
    {ibrowse_req_id, ReqId} = couch_rep_httpc:request(NewReq),
    receive {ibrowse_async_headers, ReqId, NewCode, NewHeaders} ->
        ok = validate_headers(NewReq, list_to_integer(NewCode), NewHeaders)
    end,
    {ok, ReqId};
validate_headers(Req, Code, _Headers) ->
    #http_db{url=Url, resource=Resource} = Req,
    ?LOG_ERROR("got ~p for ~s~s", [Code, Url, Resource]),
    throw({attachment_request_failed, {bad_code, Code}}).
