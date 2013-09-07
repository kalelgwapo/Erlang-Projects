-module(usermanager).
-export([new/0,loop/1,new_user/2,mod_user/3,del_user/2,say_to_user/3,say_to_all/2,name_to_socket/2,socket_to_name/2]).

new() ->
	UserList = [],
	spawn(?MODULE,loop,[UserList]).
	
loop(UserList) ->
	receive
		{From,newuser,Socket} ->
			NumUsers = length(UserList),
			UnusedNames = [Name || Name <- ["Guest" ++ integer_to_list(N) || N <- lists:seq(1,NumUsers+1)], lists:keyfind(Name, 2, UserList) == false],
			[Name|_OtherNames] = UnusedNames,
			UserList1 = UserList ++ [{Socket,Name}],
			From ! {ok,Name},
			loop(UserList1);
		{From,moduser,Socket,NewName} ->
		    UserExists = lists:keyfind(NewName, 2, UserList),
            if
				UserExists == false ->
					UserList1 = lists:keyreplace(Socket, 1, UserList, {Socket,NewName}),
					From ! {ok,NewName},
					loop(UserList1);
				true ->
					From ! {error,username_exists},
					loop(UserList)
			end;
		{From,deluser,Socket} ->
		    UserExists = lists:keyfind(Socket, 1, UserList),
            if
				UserExists == false ->
					From ! {error,user_does_not_exist},
					loop(UserList);
				true ->
					UserList1 = lists:keydelete(Socket, 1, UserList),
					From ! {ok,deleted},
					loop(UserList1)
			end;
		{From,nametosocket,Name} ->
			FindUser = lists:keyfind(Name, 2, UserList),
            if
				FindUser == false ->
					From ! {error,user_does_not_exist},
					loop(UserList);
				true ->
					{Socket,_Name} = FindUser,
					From ! {ok,Socket},
					loop(UserList)
			end;
		{From,sockettoname,Socket} ->
			FindUser = lists:keyfind(Socket, 1, UserList),
            if
				FindUser == false ->
					From ! {error,user_does_not_exist},
					loop(UserList);
				true ->
					{_Socket,Name} = FindUser,
					From ! {ok,Name},
					loop(UserList)
			end;
		{From,saytouser,ReceiverName,Message} ->
		    FindUser = lists:keyfind(ReceiverName, 2, UserList),
            if
				FindUser == false ->
					From ! {error,user_does_not_exist},
					loop(UserList);
				true ->
					{ReceiverSocket,_ReceiverName} = FindUser,
					gen_tcp:send(ReceiverSocket,Message),
					From ! {ok,sent},
					loop(UserList)
			end;
		{From,saytoall,Message} ->
			lists:map(fun(User) -> {Socket,_Name} = User, gen_tcp:send(Socket,Message) end,UserList),
			From ! {ok,sent},
			loop(UserList)
	end.

new_user(UserManagerPid,Socket) ->
	UserManagerPid ! {self(),newuser,Socket},
	receive
		Reply ->
			Reply
	end.

mod_user(UserManagerPid,Socket,NewName) ->
	UserManagerPid ! {self(),moduser,Socket,NewName},
	receive
		Reply ->
			Reply
	end.
	
del_user(UserManagerPid,Socket) ->
	UserManagerPid ! {self(),deluser,Socket},
	receive
		Reply ->
			Reply
	end.
	
name_to_socket(UserManagerPid,Name) ->
	UserManagerPid ! {self(),nametosocket,Name},
	receive
		Reply ->
			Reply
	end.

socket_to_name(UserManagerPid,Socket) ->
	UserManagerPid ! {self(),sockettoname,Socket},
	receive
		Reply ->
			Reply
	end.	

say_to_user(UserManagerPid,ReceiverName,Message) ->
	UserManagerPid ! {self(),saytouser,ReceiverName,Message},
	receive
		Reply ->
			Reply
	end.

say_to_all(UserManagerPid,Message) ->
	UserManagerPid ! {self(),saytoall,Message},
	receive
		Reply ->
			Reply
	end.