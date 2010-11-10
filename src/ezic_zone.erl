-module(ezic_zone).
-include("include/ezic.hrl").
-include_lib("eunit/include/eunit.hrl").

-export([
	 parse/1
	 , current/1
	 , current_as_of_utc/2
	 , split_by_name/2
	 , offset_sec/1

	 , project_end/2
	 , project_end_utc/2
	 , next/3
	]).




parse([Name,GmtOffS,Rule,FormatS | UntilTokens]) ->
%    ?debugVal(GmtOffS),
    GmtOff= ezic_parse:time_val(GmtOffS),
    Until = ezic_parse:until(UntilTokens),
    Format= ezic_parse:tz_abbr(FormatS),
    
    {ok, #zone{
       name=Name, gmtoff=GmtOff, rule=Rule,
       format=Format, until=Until
      }}.










current(TzName) ->
    current_as_of_utc(erlang:universaltime(), TzName).

current_as_of_utc(UTCDatetime, TzName) ->
    Zones= ezic_db:zones(TzName),
    get_zone_utc(UTCDatetime, Zones).




get_zone_utc(_, []) ->
    erlang:error(no_current);
get_zone_utc(_UTCDatetime, Zones) ->
    not_done.
			       



% returns {[SimilarZone], [DifferentZone]} 
%   where Similar Zones are those with the same name as Zone
%   and DifferentZones are all the rest
split_by_name(#zone{name=N}, Zones) ->
    lists:partition(
      fun(#zone{name=NI}) ->
	      N =:= NI
      end
      , Zones).


% @bug doesn't normalize times. Times are self-relative (to standard time), and Now may come from any timezone unless we're careful about that.
%% older_zone(#zone{until=Until}, UTCDatetime) ->
%%     ezic_date:compare(Until, UTCDatetime).



offset_sec(Zone) ->
    calendar:time_to_seconds((Zone#zone.gmtoff)#tztime.time).




% returns the UTC datetime projected for zone end (given current DST Offset)
project_end(#zone{until=Until, gmtoff=Offset}, DSTOffset) ->
    ezic_date:all_times(Until, Offset, DSTOffset).

% returns just the UTC datetime projected for zone end
project_end_utc(Zone=#zone{}, DSTOffset) ->
    {_,_,UTCDatetime}= project_end(Zone, DSTOffset),
    UTCDatetime.
    



% returns {Zone, Rest} where Zone is the next zone after UTCFrom,
%  subject to the DST offset. 
% Note that dst differences *can* change which zone comes next, 
%  though it's very unlikely (and does not exist in the current tz database files). 
%  this method covers that event, anyhow.
next(ZoneList, UTCFrom, DSTOff) ->
    DatedList= lists:map(
		 fun(Z=#zone{until=Until, gmtoff=Offset})->
			 NU= ezic_date:normalize(Until),
			 {_,_,UTCDt}= ezic_date:all_times(NU, Offset, DSTOff),
			 {UTCDt, Z}
		 end
		 , ZoneList),
    [{_,Zone} | DRest]= lists:sort(DatedList),
    {Zone, [R || {_,R}<- DRest]}.
