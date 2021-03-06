-module(udp_test).
-export([start_server/0, fac/3, fac/1]).

start_server() ->
    spawn(fun() -> server(4000) end).

%% The server 		  
server(Port) ->
    {ok, Socket} = gen_udp:open(Port, [binary]),
    io:format("server on ~p opened socket:~p~n",[my_ip(), Socket]),
     loop(Socket).

loop(Socket) ->
    receive
	{udp, Socket, Host, Port, Bin} = Msg ->
	    {ok, Peer} = inet:peername(Socket),
	    io:format("server received:~p from ~p~n",[Msg, Peer]),
	    N = binary_to_term(Bin),
	    Fac = fac(N),
	    gen_udp:send(Socket, Host, Port, term_to_binary(Fac)),
	    loop(Socket)
    end.

%% The client

fac(N) ->
    fac("localhost", 4000, N).

fac(Host, Port, N) ->
    {ok, Socket} = gen_udp:open(0, [binary]),
    io:format("client opened socket=~p~n",[Socket]),
    ok = gen_udp:send(Socket, Host, Port, term_to_binary(N)),
    Value = receive
		{udp, Socket, _, _, Bin} = Msg ->
		    io:format("client received:~p~n",[Msg]),
		    binary_to_term(Bin)
	    after 2000 ->
		    0
	    end,
    gen_udp:close(Socket),
    Value.

my_ip() ->
    case inet:ifget("eth0",[addr]) of
        {ok,[{addr,IP}]} ->
            IP;
        _ ->
            exit(cannot_find_local_ip)
    end.

    

