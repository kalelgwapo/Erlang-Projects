-module(chatbot2).
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
	gen_tcp:send(Socket, "Skynet is online. \r\nBackspace does not work. If you do not want to add anything to Skynet, simply input .cancel when she asks you the keyword.\r\nSkynet greets you user.\r\n\r\n"),
	WBank = [],
	Mode = [],
    recv_loop(Socket, WBank, Mode),
    gen_tcp:close(Socket).

recv_loop(Socket, WBank, Mode) ->
	inet:setopts(Socket, [{active, once}]),
		receive
      	{tcp, Socket, "\r\n"} ->
			case Mode == [] of
				true->
					words(WBank, Socket);
				_Else->
					learn(WBank, Socket, Mode)
			end,
			recv_loop(Socket, [],[]);
		{tcp, Socket, Data} ->
          	A = WBank ++ Data,
            recv_loop(Socket,A,Mode)
		end.		

		

words(String, Socket) ->
	{ok, Bin} = file:read_file("db.txt"),
	bot(string:tokens(string:to_lower(String)," "), convert(string:tokens(binary_to_list(Bin), "\r\n")), Socket).

convert(List) ->
	[list_to_tuple(string:tokens(E,"|")) || E <- List].

learn(Data, Socket, Type)->
case Type == 1 of
	true ->
		if Data == ".cancel" ->
		gen_tcp:send(Socket, "\r\nSkynet>Learning Module has been cancelled.\r\n");
		true ->
		{ok, WriteDescr} = file:open(db.txt, [raw, append]), 
		file:write(WriteDescr,"\r\n" ++ string:to_lower(Data)), 
		file:close(WriteDescr),
		gen_tcp:send(Socket, "\r\nSkynet>Can you tell me the meaning of your keyword? Or what should I reply to it?\r\n"),
		recv_loop(Socket, [], 2)
		end;
	_Else ->
		{ok, WriteDescr} = file:open(db.txt, [raw, append]), 
		file:write(WriteDescr,"|" ++ Data), 
		file:close(WriteDescr),
		gen_tcp:send(Socket, "\r\nSkynet>I have stored the information in my database, we can now resume chatting.\r\n")
end.

bot([H|T], DBList, Socket)->
case lists:keymember(H, 1, DBList) of 
	true ->
		{_,Reply} = lists:keyfind(H, 1, DBList),
		gen_tcp:send(Socket,"\r\nSkynet>" ++ Reply ++ "\r\n\r\n");
	_Else ->
		bot(T, DBList, Socket)
end;

bot([], DBList, Socket)->
	gen_tcp:send(Socket, "\r\n\r\nSkynet> I am sorry, i do not know, can you tell me the keyword of your previous sentence? \r\n\r\n"),
	recv_loop(Socket, [], 1).