package main

import "core:fmt"
import "core:mem"
import "core:net"


Server :: struct {
	router: Router,
}

server_init :: proc(s: ^Server) {
	router_init(&s.router)
}

server_listen_and_serve :: proc(s: ^Server, endpoint: net.Endpoint) {
	server_sock, listen_err := net.listen_tcp(endpoint)
	if listen_err != nil {
		fmt.eprintfln("error starting server: %v", listen_err)
		return
	}
	defer net.close(server_sock)

	fmt.printfln("Listening for incoming connections on %v...", net.to_string(endpoint))

	for {
		client_sock, source, accept_err := net.accept_tcp(server_sock)
		if accept_err != nil {
			fmt.eprintfln("error accepting connection: %v", accept_err)
			continue
		}

		server_handle_connection(client_sock, &s.router)
	}
}

server_handle_connection :: proc(client_sock: net.TCP_Socket, router: ^Router) {
	defer net.close(client_sock)

	arena_buffer: [65536]u8
	req_arena: mem.Arena
	mem.arena_init(&req_arena, arena_buffer[:])

	req_allocator := mem.arena_allocator(&req_arena)
	context.allocator = req_allocator

	read_buf: [8192]u8
	bytes_read, recv_err := net.recv_tcp(client_sock, read_buf[:])
	if recv_err != nil {
		fmt.eprintfln("error reading from socket: %v", recv_err)
		return
	}

	raw_request := read_buf[:bytes_read]

	req, parse_req_err := parse_request(raw_request)
	if parse_req_err != nil {
		fmt.eprintfln("err: %v", parse_error_message(parse_req_err))
		return
	}

	res: Response
	response_init(&res)

	router_dispatch(router, req, &res)

	raw_response := response_serialize(&res)

	_, send_err := net.send_tcp(client_sock, raw_response)
	if send_err != nil {
		fmt.eprintfln("error sending response: %v", send_err)
	}
}
