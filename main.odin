package main

import "core:fmt"
import "core:mem"
import "core:net"

main :: proc() {

	endpoint, ep_ok := net.parse_endpoint("127.0.0.1:8080")
	if !ep_ok {
		fmt.eprintln("Error: failed to parse endpoint string.")
		return
	}

	server_sock, listen_err := net.listen_tcp(endpoint)
	if listen_err != nil {
		fmt.eprintfln("error starting server: %v", listen_err)
		return
	}

	defer net.close(server_sock)

	endpoint_str := net.to_string(endpoint)

	fmt.printfln("listening for incoming connections on %v...", endpoint_str)

	for {
		client_sock, source, accept_err := net.accept_tcp(server_sock)
		if accept_err != nil {
			fmt.eprintfln("error accepting connection: %v", accept_err)
			continue
		}

		arena_buffer: [65536]u8

		req_arena: mem.Arena
		mem.arena_init(&req_arena, arena_buffer[:])

		req_allocator := mem.arena_allocator(&req_arena)
		context.allocator = req_allocator

		req := Request {
			headers = make(map[string]string),
		}


		read_buf: [1024]u8
		bytes_read, recv_err := net.recv_tcp(client_sock, read_buf[:])
		if recv_err != nil {
			fmt.eprintfln("error reading from socket: %v", recv_err)
			net.close(client_sock)
			continue
		}

		raw_request := read_buf[:bytes_read]

		parse_request(raw_request)
		// TODO: Parsing

		response := "HTTP/1.1 200 OK\r\nContent-Length: 2\r\nContent-Type: text/plain\r\n\r\nOK"

		_, send_err := net.send_tcp(client_sock, transmute([]u8)response)
		if send_err != nil {
			fmt.eprintfln("error sending response: %v", send_err)
		}

		net.close(client_sock)
	}
}
