% 2008-0051 Kevin Khalil B. Reyes

-module(mobius).
-export([is_prime/1,prime_factors/1,is_square_multiple/1,find_square_multiples/2]).

is_prime(N) ->
is_primeh(N,2).

is_primeh(2,_) ->
true;
is_primeh(N,K) when K >= N/2 ->
N rem K /= 0;
is_primeh(N,K) when N rem K > 0 ->
is_primeh(N,K+1);
is_primeh(N,K) when N rem K == 0 ->
false.

prime_factors(N)->
prime_factorsh(N, 2, []).
prime_factorsh(N, K, L) when N > 1 ->
    case N rem K of
    0 ->
        prime_factorsh(N div K, K,[K|L]);
    _Else ->
        prime_factorsh(N,K+1, L)
    end;

prime_factorsh(_N,_K,L) ->
L.

is_square_multiple(N)->
is_square_multipleh(prime_factors(N)).

is_square_multipleh([H|T]) when length([H|T]) > 1->
case lists:member(H,T) of
true ->
true;
false ->
is_square_multipleh(T)
end;

is_square_multipleh([H|T]) when length([H|T]) == 1->
false;
is_square_multipleh([])->
false.


find_square_multiples(Count, MaxN)->
find_square_multiplesh(Count, MaxN, 2, [],[]).

find_square_multiplesh(Count, MaxN, K, L, P) when K =< MaxN ->
case is_square_multiple(K) of
true ->
find_square_multiplesh(Count, MaxN, K+1, lists:sort([K|L]), lists:sublist(L,Count));
false ->
find_square_multiplesh(Count, MaxN, K+1, L,P)
end;

find_square_multiplesh(Count, MaxN, K, [H,T],[O|P])->
fail;

find_square_multiplesh(Count, MaxN, K, [H|T],L) when H /= L->
case lists:seq(H,lists:last(L)) == L of
true ->
H;
false ->
find_square_multiplesh(Count, MaxN, K, T,lists:sublist(T,Count))
end.

%Sample Interactions:
%2> mobius:is_prime(111317).
%true
%3> mobius:is_prime(112317).
%false
%4> mobius:prime_factors(112317).
%[1291,29,3]
%5> mobius:prime_factors(11220). 
%[17,11,5,3,2,2]
%6> mobius:is_square_multiple(11220).
%true
%7> mobius:is_square_multiple(112317).
%false
%8> mobius:find_square_multiples(3,50).  
%48
%9> mobius:find_square_multiples(3,20).
%fail
%10> mobius:find_square_multiples(4,30000).
%242
%11> timer:tc(mobius,find_square_multiples,[4,30000]).
%{41609000,242}
%12> mobius:find_square_multiples(5,30000).
%844 
%13> timer:tc(mobius,find_square_multiples,[5,30000]).
%{43922000,844}
%14> mobius:find_square_multiples(6,30000).
%22020
%15> timer:tc(mobius,find_square_multiples,[6,30000]).
%{47734000,22020}

