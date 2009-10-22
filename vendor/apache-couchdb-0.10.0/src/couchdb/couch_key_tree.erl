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

-module(couch_key_tree).

-export([merge/2, find_missing/2, get_key_leafs/2, get_full_key_paths/2, get/2]).
-export([map/2, get_all_leafs/1, count_leafs/1, remove_leafs/2,
    get_all_leafs_full/1,stem/2,map_leafs/2]).

% a key tree looks like this:
% Tree -> [] or [{Key, Value, ChildTree} | SiblingTree]
% ChildTree -> Tree
% SiblingTree -> [] or [{SiblingKey, Value, Tree} | Tree]
% And each Key < SiblingKey


% partial trees arranged by how much they are cut off.

merge(A, B) ->
    {Merged, HasConflicts} =
    lists:foldl(
        fun(InsertTree, {AccTrees, AccConflicts}) ->
            {ok, Merged, Conflicts} = merge_one(AccTrees, InsertTree, [], false),
            {Merged, Conflicts or AccConflicts}
        end,
        {A, false}, B),
    if HasConflicts or
            ((length(Merged) /= length(A)) and (length(Merged) /= length(B))) ->
        Conflicts = conflicts;
    true ->
        Conflicts = no_conflicts
    end,
    {lists:sort(Merged), Conflicts}.

merge_one([], Insert, OutAcc, ConflictsAcc) ->
    {ok, [Insert | OutAcc], ConflictsAcc};
merge_one([{Start, Tree}|Rest], {StartInsert, TreeInsert}, OutAcc, ConflictsAcc) ->
    if Start =< StartInsert ->
        StartA = Start,
        StartB = StartInsert,
        TreeA = Tree,
        TreeB = TreeInsert;
    true ->
        StartB = Start,
        StartA = StartInsert,
        TreeB = Tree,
        TreeA = TreeInsert
    end,
    case merge_at([TreeA], StartB - StartA, TreeB) of
    {ok, [CombinedTrees], Conflicts} ->
        merge_one(Rest, {StartA, CombinedTrees}, OutAcc, Conflicts or ConflictsAcc);
    no ->
        merge_one(Rest, {StartB, TreeB}, [{StartA, TreeA} | OutAcc], ConflictsAcc)
    end.

merge_at([], _Place, _Insert) ->
    no;
merge_at([{Key, Value, SubTree}|Sibs], 0, {InsertKey, InsertValue, InsertSubTree}) ->
    if Key == InsertKey ->
        {Merge, Conflicts} = merge_simple(SubTree, InsertSubTree),
        {ok, [{Key, Value, Merge} | Sibs], Conflicts};
    true ->
        case merge_at(Sibs, 0, {InsertKey, InsertValue, InsertSubTree}) of
        {ok, Merged, Conflicts} ->
            {ok, [{Key, Value, SubTree} | Merged], Conflicts};
        no ->
            no
        end
    end;
merge_at([{Key, Value, SubTree}|Sibs], Place, Insert) ->
    case merge_at(SubTree, Place - 1,Insert) of
    {ok, Merged, Conflicts} ->
        {ok, [{Key, Value, Merged} | Sibs], Conflicts};
    no ->
        case merge_at(Sibs, Place, Insert) of
        {ok, Merged, Conflicts} ->
            {ok, [{Key, Value, SubTree} | Merged], Conflicts};
        no ->
            no
        end
    end.

% key tree functions
merge_simple([], B) ->
    {B, false};
merge_simple(A, []) ->
    {A, false};
merge_simple([ATree | ANextTree], [BTree | BNextTree]) ->
    {AKey, AValue, ASubTree} = ATree,
    {BKey, _BValue, BSubTree} = BTree,
    if
    AKey == BKey ->
        %same key
        {MergedSubTree, Conflict1} = merge_simple(ASubTree, BSubTree),
        {MergedNextTree, Conflict2} = merge_simple(ANextTree, BNextTree),
        {[{AKey, AValue, MergedSubTree} | MergedNextTree], Conflict1 or Conflict2};
    AKey < BKey ->
        {MTree, _} = merge_simple(ANextTree, [BTree | BNextTree]),
        {[ATree | MTree], true};
    true ->
        {MTree, _} = merge_simple([ATree | ANextTree], BNextTree),
        {[BTree | MTree], true}
    end.

find_missing(_Tree, []) ->
    [];
find_missing([], SeachKeys) ->
    SeachKeys;
find_missing([{Start, {Key, Value, SubTree}} | RestTree], SeachKeys) ->
    PossibleKeys = [{KeyPos, KeyValue} || {KeyPos, KeyValue} <- SeachKeys, KeyPos >= Start],
    ImpossibleKeys = [{KeyPos, KeyValue} || {KeyPos, KeyValue} <- SeachKeys, KeyPos < Start],
    Missing = find_missing_simple(Start, [{Key, Value, SubTree}], PossibleKeys),
    find_missing(RestTree, ImpossibleKeys ++ Missing).

find_missing_simple(_Pos, _Tree, []) ->
    [];
find_missing_simple(_Pos, [], SeachKeys) ->
    SeachKeys;
find_missing_simple(Pos, [{Key, _, SubTree} | RestTree], SeachKeys) ->
    PossibleKeys = [{KeyPos, KeyValue} || {KeyPos, KeyValue} <- SeachKeys, KeyPos >= Pos],
    ImpossibleKeys = [{KeyPos, KeyValue} || {KeyPos, KeyValue} <- SeachKeys, KeyPos < Pos],

    SrcKeys2 = PossibleKeys -- [{Pos, Key}],
    SrcKeys3 = find_missing_simple(Pos + 1, SubTree, SrcKeys2),
    ImpossibleKeys ++ find_missing_simple(Pos, RestTree, SrcKeys3).


filter_leafs([], _Keys, FilteredAcc, RemovedKeysAcc) ->
    {FilteredAcc, RemovedKeysAcc};
filter_leafs([{Pos, [{LeafKey, _}|_]} = Path |Rest], Keys, FilteredAcc, RemovedKeysAcc) ->
    FilteredKeys = lists:delete({Pos, LeafKey}, Keys),
    if FilteredKeys == Keys ->
        % this leaf is not a key we are looking to remove
        filter_leafs(Rest, Keys, [Path | FilteredAcc], RemovedKeysAcc);
    true ->
        % this did match a key, remove both the node and the input key
        filter_leafs(Rest, FilteredKeys, FilteredAcc, [{Pos, LeafKey} | RemovedKeysAcc])
    end.

% Removes any branches from the tree whose leaf node(s) are in the Keys
remove_leafs(Trees, Keys) ->
    % flatten each branch in a tree into a tree path
    Paths = get_all_leafs_full(Trees),

    % filter out any that are in the keys list.
    {FilteredPaths, RemovedKeys} = filter_leafs(Paths, Keys, [], []),

    % convert paths back to trees
    NewTree = lists:foldl(
        fun({PathPos, Path},TreeAcc) ->
            [SingleTree] = lists:foldl(
                fun({K,V},NewTreeAcc) -> [{K,V,NewTreeAcc}] end, [], Path),
            {NewTrees, _} = merge(TreeAcc, [{PathPos + 1 - length(Path), SingleTree}]),
            NewTrees
        end, [], FilteredPaths),
    {NewTree, RemovedKeys}.


% get the leafs in the tree matching the keys. The matching key nodes can be
% leafs or an inner nodes. If an inner node, then the leafs for that node
% are returned.
get_key_leafs(Tree, Keys) ->
    get_key_leafs(Tree, Keys, []).

get_key_leafs(_, [], Acc) ->
    {Acc, []};
get_key_leafs([], Keys, Acc) ->
    {Acc, Keys};
get_key_leafs([{Pos, Tree}|Rest], Keys, Acc) ->
    {Gotten, RemainingKeys} = get_key_leafs_simple(Pos, [Tree], Keys, []),
    get_key_leafs(Rest, RemainingKeys, Gotten ++ Acc).

get_key_leafs_simple(_Pos, _Tree, [], _KeyPathAcc) ->
    {[], []};
get_key_leafs_simple(_Pos, [], KeysToGet, _KeyPathAcc) ->
    {[], KeysToGet};
get_key_leafs_simple(Pos, [{Key, _Value, SubTree}=Tree | RestTree], KeysToGet, KeyPathAcc) ->
    case lists:delete({Pos, Key}, KeysToGet) of
    KeysToGet -> % same list, key not found
        {LeafsFound, KeysToGet2} = get_key_leafs_simple(Pos + 1, SubTree, KeysToGet, [Key | KeyPathAcc]),
        {RestLeafsFound, KeysRemaining} = get_key_leafs_simple(Pos, RestTree, KeysToGet2, KeyPathAcc),
        {LeafsFound ++ RestLeafsFound, KeysRemaining};
    KeysToGet2 ->
        LeafsFound = get_all_leafs_simple(Pos, [Tree], KeyPathAcc),
        LeafKeysFound = [LeafKeyFound || {LeafKeyFound, _} <- LeafsFound],
        KeysToGet2 = KeysToGet2 -- LeafKeysFound,
        {RestLeafsFound, KeysRemaining} = get_key_leafs_simple(Pos, RestTree, KeysToGet2, KeyPathAcc),
        {LeafsFound ++ RestLeafsFound, KeysRemaining}
    end.

get(Tree, KeysToGet) ->
    {KeyPaths, KeysNotFound} = get_full_key_paths(Tree, KeysToGet),
    FixedResults = [ {Value, {Pos, [Key0 || {Key0, _} <- Path]}} || {Pos, [{_Key, Value}|_]=Path} <- KeyPaths],
    {FixedResults, KeysNotFound}.

get_full_key_paths(Tree, Keys) ->
    get_full_key_paths(Tree, Keys, []).

get_full_key_paths(_, [], Acc) ->
    {Acc, []};
get_full_key_paths([], Keys, Acc) ->
    {Acc, Keys};
get_full_key_paths([{Pos, Tree}|Rest], Keys, Acc) ->
    {Gotten, RemainingKeys} = get_full_key_paths(Pos, [Tree], Keys, []),
    get_full_key_paths(Rest, RemainingKeys, Gotten ++ Acc).


get_full_key_paths(_Pos, _Tree, [], _KeyPathAcc) ->
    {[], []};
get_full_key_paths(_Pos, [], KeysToGet, _KeyPathAcc) ->
    {[], KeysToGet};
get_full_key_paths(Pos, [{KeyId, Value, SubTree} | RestTree], KeysToGet, KeyPathAcc) ->
    KeysToGet2 = KeysToGet -- [{Pos, KeyId}],
    CurrentNodeResult =
    case length(KeysToGet2) == length(KeysToGet) of
    true -> % not in the key list.
        [];
    false -> % this node is the key list. return it
        [{Pos, [{KeyId, Value} | KeyPathAcc]}]
    end,
    {KeysGotten, KeysRemaining} = get_full_key_paths(Pos + 1, SubTree, KeysToGet2, [{KeyId, Value} | KeyPathAcc]),
    {KeysGotten2, KeysRemaining2} = get_full_key_paths(Pos, RestTree, KeysRemaining, KeyPathAcc),
    {CurrentNodeResult ++ KeysGotten ++ KeysGotten2, KeysRemaining2}.

get_all_leafs_full(Tree) ->
    get_all_leafs_full(Tree, []).

get_all_leafs_full([], Acc) ->
    Acc;
get_all_leafs_full([{Pos, Tree} | Rest], Acc) ->
    get_all_leafs_full(Rest, get_all_leafs_full_simple(Pos, [Tree], []) ++ Acc).

get_all_leafs_full_simple(_Pos, [], _KeyPathAcc) ->
    [];
get_all_leafs_full_simple(Pos, [{KeyId, Value, []} | RestTree], KeyPathAcc) ->
    [{Pos, [{KeyId, Value} | KeyPathAcc]} | get_all_leafs_full_simple(Pos, RestTree, KeyPathAcc)];
get_all_leafs_full_simple(Pos, [{KeyId, Value, SubTree} | RestTree], KeyPathAcc) ->
    get_all_leafs_full_simple(Pos + 1, SubTree, [{KeyId, Value} | KeyPathAcc]) ++ get_all_leafs_full_simple(Pos, RestTree, KeyPathAcc).

get_all_leafs(Trees) ->
    get_all_leafs(Trees, []).

get_all_leafs([], Acc) ->
    Acc;
get_all_leafs([{Pos, Tree}|Rest], Acc) ->
    get_all_leafs(Rest, get_all_leafs_simple(Pos, [Tree], []) ++ Acc).

get_all_leafs_simple(_Pos, [], _KeyPathAcc) ->
    [];
get_all_leafs_simple(Pos, [{KeyId, Value, []} | RestTree], KeyPathAcc) ->
    [{Value, {Pos, [KeyId | KeyPathAcc]}} | get_all_leafs_simple(Pos, RestTree, KeyPathAcc)];
get_all_leafs_simple(Pos, [{KeyId, _Value, SubTree} | RestTree], KeyPathAcc) ->
    get_all_leafs_simple(Pos + 1, SubTree, [KeyId | KeyPathAcc]) ++ get_all_leafs_simple(Pos, RestTree, KeyPathAcc).


count_leafs([]) ->
    0;
count_leafs([{_Pos,Tree}|Rest]) ->
    count_leafs_simple([Tree]) + count_leafs(Rest).

count_leafs_simple([]) ->
    0;
count_leafs_simple([{_Key, _Value, []} | RestTree]) ->
    1 + count_leafs_simple(RestTree);
count_leafs_simple([{_Key, _Value, SubTree} | RestTree]) ->
    count_leafs_simple(SubTree) + count_leafs_simple(RestTree).


map(_Fun, []) ->
    [];
map(Fun, [{Pos, Tree}|Rest]) ->
    case erlang:fun_info(Fun, arity) of
    {arity, 2} ->
        [NewTree] = map_simple(fun(A,B,_C) -> Fun(A,B) end, Pos, [Tree]),
        [{Pos, NewTree} | map(Fun, Rest)];
    {arity, 3} ->
        [NewTree] = map_simple(Fun, Pos, [Tree]),
        [{Pos, NewTree} | map(Fun, Rest)]
    end.

map_simple(_Fun, _Pos, []) ->
    [];
map_simple(Fun, Pos, [{Key, Value, SubTree} | RestTree]) ->
    Value2 = Fun({Pos, Key}, Value, 
            if SubTree == [] -> leaf; true -> branch end),
    [{Key, Value2, map_simple(Fun, Pos + 1, SubTree)} | map_simple(Fun, Pos, RestTree)].


map_leafs(_Fun, []) ->
    [];
map_leafs(Fun, [{Pos, Tree}|Rest]) ->
    [NewTree] = map_leafs_simple(Fun, Pos, [Tree]),
    [{Pos, NewTree} | map_leafs(Fun, Rest)].

map_leafs_simple(_Fun, _Pos, []) ->
    [];
map_leafs_simple(Fun, Pos, [{Key, Value, []} | RestTree]) ->
    Value2 = Fun({Pos, Key}, Value),
    [{Key, Value2, []} | map_leafs_simple(Fun, Pos, RestTree)];
map_leafs_simple(Fun, Pos, [{Key, Value, SubTree} | RestTree]) ->
    [{Key, Value, map_leafs_simple(Fun, Pos + 1, SubTree)} | map_leafs_simple(Fun, Pos, RestTree)].


stem(Trees, Limit) ->
    % flatten each branch in a tree into a tree path
    Paths = get_all_leafs_full(Trees),

    Paths2 = [{Pos, lists:sublist(Path, Limit)} || {Pos, Path} <- Paths],

    % convert paths back to trees
    lists:foldl(
        fun({PathPos, Path},TreeAcc) ->
            [SingleTree] = lists:foldl(
                fun({K,V},NewTreeAcc) -> [{K,V,NewTreeAcc}] end, [], Path),
            {NewTrees, _} = merge(TreeAcc, [{PathPos + 1 - length(Path), SingleTree}]),
            NewTrees
        end, [], Paths2).

% Tests moved to test/etap/06?-*.t

