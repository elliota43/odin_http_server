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

		read_buf: [1024]u8
		bytes_read, recv_err := net.recv_tcp(client_sock, read_buf[:])
		if recv_err != nil {
			fmt.eprintfln("error reading from socket: %v", recv_err)
			net.close(client_sock)
			continue
		}

		raw_request := read_buf[:bytes_read]

		req, parse_req_err := parse_request(raw_request)
		if parse_req_err != nil {
			fmt.eprintfln("err: %v", parse_error_message(parse_req_err))
			net.close(client_sock)
			continue
		}

		fmt.printfln("\n=== New Request ===")
		fmt.printfln("Request struct: %#v", req^)
		if req.has_body {
			fmt.printfln("Body Text: %s", string(req.body))
		}

		fmt.printfln("===============================\n")

		res: Response
		response_init(&res)

		if req.method == .GET && req.uri == "/hello" {
			res.status = .OK
			response_set_header(&res, "Content-Type", "text/plain")
			response_set_body_string(&res, "Hey there!")
		} else if req.method == .POST && req.uri == "/echo" {
			res.status = .Created // 201
			response_set_header(&res, "Content-Type", "application/json")
			response_set_body(&res, req.body)
		} else {
			res.status = .Not_Found
			response_set_header(&res, "Content-Type", "text/plain")
			response_set_body_string(&res, "404 - Not Found")
		}

		raw_response := response_serialize(&res)

		_, send_err := net.send_tcp(client_sock, raw_response)
		if send_err != nil {
			fmt.eprintfln("error sending response: %v", send_err)
		}

		net.close(client_sock)
	}
}
