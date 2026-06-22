package main

import "core:fmt"
import "core:net"

handle_hello :: proc(req: ^Request, res: ^Response) {
	res.status = .OK
	response_set_header(res, "Content-Type", "text/plain")
	response_set_body_string(res, "Hey from the hello route handler!")
}

handle_echo :: proc(req: ^Request, res: ^Response) {
	res.status = .Created
	response_set_header(res, "Content-Type", "application/json")
	response_set_body(res, req.body)
}

main :: proc() {
	endpoint, ep_ok := net.parse_endpoint("127.0.0.1:8080")
	if !ep_ok {
		fmt.eprintln("error: failed to parse endpoint string.")
		return
	}

	srv: Server
	server_init(&srv)

	router_add_route(&srv.router, .GET, "/hello", handle_hello)
	router_add_route(&srv.router, .POST, "/echo", handle_echo)
	server_listen_and_serve(&srv, endpoint)
}
