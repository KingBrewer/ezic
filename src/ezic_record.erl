-module(ezic_record).
-include("include/ezic.hrl").
-include_lib("eunit/include/eunit.hrl").


-ifdef(TEST).
-compile([export_all]).
-endif.


-export([rule/1,zone/1,link/1,leap/1]).



rule([Name,FromS,ToS,Type,InS,OnS,AtS,SaveS,Letters]) ->
    From= parse_from(FromS),
    To= parse_to(ToS),
    % @todo handle year types
    In= month_to_num(InS),
    On= parse_on(OnS),
    At=parse_at(AtS),
    Save=parse_save(SaveS),

    {ok, #rule{
       name=Name, from=From, to=To, type=Type,
       in=In, on=On, at=At, save=Save, letters=Letters
      }}.


zone([Name,GmtOffS,Rules,FormatS | UntilTokens]) ->
    GmtOff=parse_time(GmtOffS),
    Until = parse_until(UntilTokens),
    Format= convert_format(FormatS),
    
    {ok, #zone{
       name=Name, gmtoff=GmtOff, rules=Rules,
       format=Format, until=Until
      }}.

    
link([From,To]) ->
    {ok, #link{from=From, to=To}}.


leap([YearS, MonthS, DayS, TimeS, Corr, RS]) ->
    Y=list_to_integer(YearS),
    M=month_to_num(MonthS),
    D=list_to_integer(DayS),
    Time=parse_abs_time(TimeS),
    {ok, #leap{datetime={{Y,M,D}, Time}}}.



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PRIVATE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


parse_from(X) when X=:="maximum";X=:="max" ->
    maximum;
parse_from(X) when X=:="minimum";X=:="min" ->
    minimum;
parse_from(Year) ->
    list_to_integer(Year).



parse_to("only") ->
    only;
parse_to(Other) ->
    parse_from(Other).



parse_on(X=[$l,$a,$s,$t|Day]) ->
    case is_day(Day) of
	true -> list_to_atom(X);
	false -> erlang:error(badday,X)
    end;
parse_on(X=[D,A,Y, Sign,$= | IntS]) ->
    Int=list_to_integer(IntS),
    Day=[D,A,Y],
    {ok, FSign} =parse_on_sign(Sign),

    case is_day(Day) of
	true -> #tzon{day=list_to_atom(string:to_lower(Day)), filter={FSign, Int}};
	false -> erlang:error(badday, X)
    end;
parse_on(X) ->
    list_to_integer(X).
	    

parse_until([]) ->
    current;
parse_until([YS]) ->
    Y= list_to_integer(YS),
    {Y,1,1};
parse_until([YS,MS]) ->
    Y= list_to_integer(YS),
    M=month_to_num(MS),
    {Y,M,1};
parse_until([YS,MS,DS]) ->
    Y= list_to_integer(YS),
    M=month_to_num(MS),
    D= parse_on(DS),
    {Y,M,D};
parse_until([YS,MS,DS,TS]) ->
    Y= list_to_integer(YS),
    M=month_to_num(MS),
    D= parse_on(DS),
    {{Y,M,D},parse_time(TS)}.



parse_at(X) ->
    parse_time(X).



parse_save("-") ->
    parse_time("-");
parse_save(X) ->
    XRev=lists:reverse(X),
    parse_save_rev(XRev).


parse_time("-") ->
    #tztime{time={0,0,0}};
parse_time(TS) ->
    parse_time_rev(lists:reverse(TS)).


parse_abs_time(T) ->
    Tokez= string:tokens(T, ":"),
    parse_abs_time_2(Tokez).



convert_format(Format) ->
    convert_format(Format, string:str(Format, "%s")).



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INTERNAL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


parse_on_sign($>) -> {ok, geq};
parse_on_sign($<) -> {ok, leq}.




parse_time_rev([F|RTime]) when F =:= $s; F =:= $w; F =:= $u ->
    Time=lists:reverse(RTime),
    #tztime{time=parse_abs_time(Time), flag=list_to_atom([F])};
parse_time_rev(X=[F|_]) when F-48 < 0; F-48 > 9 ->
    erlang:error(badtime, X);
parse_time_rev(RTime) ->
    Time=lists:reverse(RTime),
    #tztime{time=parse_abs_time(Time)}.
    



parse_abs_time_2([HS]) ->
    H= list_to_integer(HS),
    {H,0,0};
parse_abs_time_2([HS,MS]) ->
    H= list_to_integer(HS),
    M= list_to_integer(MS),
    {H,M,0};
parse_abs_time_2([HS,MS,SS]) ->
    H= list_to_integer(HS),
    M= list_to_integer(MS),
    S= list_to_integer(SS),
    {H,M,S};
parse_abs_time_2(X) ->
    erlang:error(badtime, X).
			       


parse_save_rev(X=[F|_]) when F-48 < 0; F-48 > 9 ->
    erlang:error(badsave, lists:reverse(X));
parse_save_rev(X) ->
    parse_time(lists:reverse(X)).



convert_format(Format, 0) ->
    Format;
convert_format(Format, Pos) ->
    First=string:substr(Format, 1, Pos-1),
    Last=string:substr(Format, Pos+2),
    string:concat(First, [$~, $s|Last]).
	    
    



month_to_num("Jan") -> 1;
month_to_num("Feb") -> 2;
month_to_num("Mar") -> 3;
month_to_num("Apr") -> 4;
month_to_num("May") -> 5;
month_to_num("Jun") -> 6;
month_to_num("Jul") -> 7;
month_to_num("Aug") -> 8;
month_to_num("Sep") -> 9;
month_to_num("Oct") -> 10;
month_to_num("Nov") -> 11;
month_to_num("Dec") -> 12;
month_to_num(X) -> erlang:error(badMonth, X).



is_day(X) when X=:="Mon";X=:="Tue";X=:="Wed";X=:="Thu";X=:="Fri";X=:="Sat";X=:="Sun" ->
    true;
is_day(_) ->
    false.

