package main

import "core:testing"

@(test)
test_parse_method :: proc(t: ^testing.T) {
	testing.expect(t, parse_method_from_string("GET") == .GET, "Expected GET")
	testing.expect(t, parse_method_from_string("POST") == .POST, "Expected POST")
	testing.expect(t, parse_method_from_string("NOTAREALMETHOD") == .Invalid, "Expected Invalid")
}

@(test)
test_parse_http_version :: proc(t: ^testing.T) {
	testing.expect(
		t,
		parse_http_version_from_string("HTTP/1.1\r\n") == Version.HTTP_1_1,
		"Expected HTTP/1.1 to parse and trim correctly",
	)
	testing.expect(
		t,
		parse_http_version_from_string("HTTP/1.0") == Version.HTTP_1_0,
		"Expected HTTP/1.0 to parse",
	)
	testing.expect(
		t,
		parse_http_version_from_string("HTTP/2.0") == Version.Unknown,
		"Expected Unknown for unsupported HTTP version",
	)
}

@(test)
test_parse_request_line :: proc(t: ^testing.T) {
	req_line := "POST /api/users HTTP/1.1\r\n"

	method, uri, version, err := parse_request_line(req_line)

	testing.expect(t, err == .None, "Expected no error for valid request line")
	testing.expect(t, method == .POST, "Expected method to be POST")
	testing.expect(t, uri == "/api/users", "Expected URI to be /api/users")
	testing.expect(t, version == .HTTP_1_1, "Expected version to be HTTP/1.1")
}

@(test)
test_parse_request_line_malformed :: proc(t: ^testing.T) {
	req_line := "GET / "
	method, uri, version, err := parse_request_line(req_line)

	testing.expect(t, err == .Malformed_Request_Line, "Expected Malformed_Request_Line error")
}

@(test)
test_parse_headers :: proc(t: ^testing.T) {
	req: Request

	raw_headers := "Host: localhost:8080\r\nContent-Type: application/json\r\nAccept: */*\r\n\r\n"
	err := parse_headers(raw_headers, &req)

	defer {
		for key, _ in req.headers {
			delete(key)
		}
		delete(req.headers)
	}

	testing.expect(t, err == .None, "Expected headers to parse without error")

	testing.expect(
		t,
		req.headers["host"] == "localhost:8080",
		"Expected host to be parsed correctly",
	)
	testing.expect(
		t,
		req.headers["content-type"] == "application/json",
		"expected content-type to be parsed correctly",
	)
	testing.expect(t, req.headers["accept"] == "*/*", "expected accept to be parsed correctly")
}
