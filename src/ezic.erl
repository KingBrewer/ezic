-module(ezic).
-include("include/ezic.hrl").

-export([
	 localtime/1
	 , utc_to_local/2
	 , next_timechange/1
	 , next_timechange_after/2
	]).

-export([load/1, dev/0, test/0]).



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PUBLIC API
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



localtime(TzName) ->
    utc_to_local(erlang:universaltime(), TzName).

%% utc_to_local(UTCDatetime, TzName) ->
%%     {ok, Zone, Rule}= current_as_of_utc(UTCDatetime, TzName),
%%     SecDiff= time_offset(Zone, Rule),
%%     ezic_date:add_seconds(UTCDatetime, SecDiff).


utc_to_local(UTCDatetime, TzName) ->
    #flatzone{offset=Offset, dstoffset=DSTOffset}= ezic_db:flatzone(UTCDatetime, TzName),
    ezic_date:add_offset(ezic_date:add_offset(UTCDatetime, Offset), DSTOffset).
    



next_timechange(TzName) ->
    next_timechange_after(erlang:universaltime(), TzName).

next_timechange_after(_UTCDatetime, _TzName) ->
    not_done.





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DEV API
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



load(Folder) ->
    ezic_loader:load(Folder).


dev() ->
    ezic:load(filename:join("priv","tzdata")),
    ezic_flatten:flatten(),
%    Zones= ezic_db:zones("WET"),
%    ezic_flatten:flatten_all_zones(Zones),

    ok.


test() ->
    lists:foreach(
      fun(TZ)->
	      io:format("~s: ~p~n", [TZ, localtime(TZ)])
      end,
      ["Asia/Tokyo", "America/New_York", "America/Los_Angeles", "America/Jamaica", "Australia/Adelaide"]).



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PRIVATE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


current_as_of_utc(UTCDatetime, TzName) ->
    CZone= ezic_zone:current_as_of_utc(UTCDatetime, TzName),
    RuleName= CZone#zone.rule,
    Rules= ezic_db:rules(RuleName),
    CRule= ezic_rule:current_as_of_utc(UTCDatetime, Rules),
    {ok, CZone, CRule}.
    

%%current_as_of_local(Datetime, TzName) ->
%%    not_done.


time_offset(Zone, Rule) ->
    OffsetSec= ezic_zone:offset_sec(Zone),
    DSTSec= ezic_rule:dst_sec(Rule),
    OffsetSec + DSTSec.
    
