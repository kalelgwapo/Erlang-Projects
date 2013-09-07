-module(chatbot).
-compile(export_all).


-define(LISTEN_PORT, 8888).
-define(TCP_OPTS, [list, {packet, raw}, {nodelay, true}, {reuseaddr, true}, {active, true}]).

start() ->
    case gen_tcp:listen(?LISTEN_PORT, ?TCP_OPTS) of
        {ok, Listen} -> spawn(?MODULE, connect, [Listen]),
            io:format("~p Skynet Server online~n", [erlang:localtime()]);
        Error ->
            io:format("Error: ~p~n", [Error])
    end.

connect(Listen) ->
    {ok, Socket} = gen_tcp:accept(Listen),
    inet:setopts(Socket, ?TCP_OPTS),
    spawn(fun() -> connect(Listen) end),
	gen_tcp:send(Socket, "Skynet is online. \r\n Backspace does not work\r\n\r\n"),
	WBank = [],
	QBank = [],
    recv_loop(Socket, WBank, QBank),
    gen_tcp:close(Socket).
	


bot([H|T], DBList, Socket)->
io:fwrite("~w~n", [DBList]),
io:fwrite("~w~n", [(H)]),
case lists:keymember(list_to_atom(H), 1, DBList) of 
true ->
{_,Reply} = lists:keyfind(list_to_atom(H), 1, DBList),
gen_tcp:send(Socket, atom_to_list(Reply) ++ "\r\n");
_Else ->
bot(T, DBList, Socket)
end;

bot([], DBList, Socket)->
gen_tcp:send(Socket, "I do not understand.\r\n").

recv_loop(Socket, WBank, QBank) ->
	inet:setopts(Socket, [{active, once}]),
		receive
      	{tcp, Socket, "\r\n"} ->
			words(WBank, Socket),
			recv_loop(Socket, [],QBank);
		{tcp, Socket, Data} ->
          	A = WBank ++ Data,
            recv_loop(Socket,A,QBank)
		end.		

words(String, Socket) ->
{ok, Bin} = file:read_file("db.txt"),
bot(string:tokens(string:to_lower(String)," "), convert(string:tokens(binary_to_list(Bin), "\r\n"), []), Socket).
%test lang gen_tcp:send(Socket, "\r\n" ++ convert(string:tokens(binary_to_list(Bin),"\r\n"),[]) ++ "\r\n").
%gen_tcp:send(Socket, "\r\n" ++ string:tokens(string:to_lower(String), " ") ++ "\r\n").	

convert([H|T], List) ->
{ok,Tokens,_} = erl_scan:string(H ++ "."),
{ok,Parsed} = erl_parse:parse_term(Tokens),
convert(T, List ++ [Parsed]);

convert([], List)->
List.

	
	%recv_loop(Socket,WBank,DataReceivedSoFar) ->
    %inet:setopts(Socket, [{active, once}]),
    %receive
     %   {tcp,Socket,WBank} ->
		%	CRNLPos = binary:match(WBank,<<"\r\n">>),
		%	if
		%		CRNLPos =/= nomatch ->
		%			Data1 = binary:split(WBank,<<"\r\n">>,[trim]),
		%			DataReceivedSoFar1 = DataReceivedSoFar ++ Data1,
		%			BinData = binary:list_to_bin(DataReceivedSoFar1),
		%			StrData = binary:bin_to_list(BinData),
		%			StrDataLen = string:len(StrData),
		%					if 
		%						StrDataLen > 0 ->
		%						words(StrData, Socket);
		%						true ->
		%							true
		%					end,
		%					recv_loop(Socket,WBank,[])
		%			end;
		%		true ->
		%			io:format("~p ~p ~p~n", [inet:peername(Socket), erlang:localtime(), WBank]),
		%			recv_loop(Socket,WBank,DataReceivedSoFar ++ [WBank])
		%	end.