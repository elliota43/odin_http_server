package main

import "core:fmt"
import "core:mem"
import "core:net"
import "core:strings"
import "core:sync"
import "core:thread"

// Optional callback for `server_listen_and_serve`.
On_Listen_Callback :: #type proc(endpoint: net.Endpoint)

Thread_Pool :: struct {
	queue:  [dynamic]net.TCP_Socket,
	mutex:  sync.Mutex,
	cond:   sync.Cond,
	router: ^Router,
}

// Initialize thread pool and spawn `num_worker` worker threads.
thread_pool_init :: proc(pool: ^Thread_Pool, num_workers: int, router: ^Router) {
	pool.queue = make([dynamic]net.TCP_Socket)
	pool.router = router

	for i in 0 ..< num_workers {
		t := thread.create(worker_routine)
		t.data = rawptr(pool)
		thread.start(t)
	}
}

worker_routine :: proc(t: ^thread.Thread) {
	pool := cast(^Thread_Pool)t.data

	for {
		sync.mutex_lock(&pool.mutex)

		for len(pool.queue) == 0 {
			sync.cond_wait(&pool.cond, &pool.mutex)
		}

		client_sock := pool.queue[0]

		ordered_remove(&pool.queue, 0)
		sync.mutex_unlock(&pool.mutex)

		server_handle_connection(client_sock, pool.router)
	}
}

Server :: struct {
	router: Router,
	pool:   Thread_Pool,
}

// Holds context for connection (1:1 connection:thread)
Connection_Context :: struct {
	client_sock: net.TCP_Socket,
	router:      ^Router,
}

server_init :: proc(s: ^Server) {
	router_init(&s.router)
	thread_pool_init(&s.pool, 8, &s.router)
}

// Binds to endpoint and enters a loop listening for connections.
server_listen_and_serve :: proc(
	s: ^Server,
	endpoint: net.Endpoint,
	on_listen: On_Listen_Callback = nil,
) {
	server_sock, listen_err := net.listen_tcp(endpoint)
	if listen_err != nil {
		fmt.eprintfln("error starting server: %v", listen_err)
		return
	}
	defer net.close(server_sock)

	if on_listen != nil {
		on_listen(endpoint)
	}

	for {
		client_sock, source, accept_err := net.accept_tcp(server_sock)
		if accept_err != nil {
			fmt.eprintfln("error accepting connection: %v", accept_err)
			continue
		}

		sync.mutex_lock(&s.pool.mutex)
		append(&s.pool.queue, client_sock)
		sync.cond_signal(&s.pool.cond)
		sync.mutex_unlock(&s.pool.mutex)
	}
}

handle_connection_thread :: proc(t: ^thread.Thread) {
	data := cast(^Connection_Context)t.data
	client_sock := data.client_sock
	router := data.router
	free(data)

	server_handle_connection(client_sock, router)
}

server_handle_connection :: proc(client_sock: net.TCP_Socket, router: ^Router) {
	defer net.close(client_sock)

	arena_buffer: [65536]u8
	req_arena: mem.Arena
	mem.arena_init(&req_arena, arena_buffer[:])

	req_allocator := mem.arena_allocator(&req_arena)
	context.allocator = req_allocator

	raw_request := make([dynamic]u8, context.allocator)

	read_buf: [8192]u8

	for {
		bytes_read, recv_err := net.recv_tcp(client_sock, read_buf[:])

		if recv_err != nil {
			// connection reset / network err
			return
		}

		if bytes_read == 0 {
			// client gracefully closed (EOF)
			return
		}

		append(&raw_request, ..read_buf[:bytes_read])

		// did we reach the end of the headers
		if strings.contains(string(raw_request[:]), "\r\n\r\n") {
			break
		}

		if len(raw_request) > 8192 {
			fmt.eprintfln("error: incoming request headers exceeded 8KB limit")
			return
		}
	}

	req, parse_req_err := parse_request(raw_request[:])
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
