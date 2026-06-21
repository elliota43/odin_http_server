package main

import "core:fmt"
Method :: enum {
	GET,
	HEAD,
	POST,
	PUT,
	DELETE,
	CONNECT,
	OPTIONS,
	TRACE,
	PATCH,
	Invalid,
}

Version :: enum {
	Unknown,
	HTTP_1_0,
	HTTP_1_1,
}

Request :: struct {
	method:  Method,
	uri:     string,
	version: Version,
	headers: map[string]string,
	body:    []u8,
}

Response :: struct {
	status_code: int,
	headers:     map[string]string,
	body:        []u8,
}

parse_request :: proc(raw_data: []u8) -> Request {
	fmt.printfln("raw_req: %v", raw_data)

	return Request{}
}
