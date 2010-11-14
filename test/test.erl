-module(test).
-export([all/0]).
-include_lib("eunit/include/eunit.hrl").

all() ->
    setup(),

    eunit:test(ezic)
    , eunit:test(ezic_record)
    , eunit:test(ezic_date)
    , eunit:test(ezic_zone)
    , eunit:test(ezic_parse)
    , eunit:test(ezic_rule)
    ,ok.


%% temporary db init because mnesia data gets corrupted between starting and stopping nodes.
setup()->
    ezic_db:init(),
    ezic:load("priv/tzdata"),
    ezic_flatten:flatten().
