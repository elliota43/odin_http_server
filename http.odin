package main

import "core:fmt"
import "core:strconv"
import "core:strings"

Parse_Error :: enum {
	None,
	Malformed_Request_Line,
	Invalid_Method,
	Invalid_Version,
	Malformed_Header,
	Header_Too_Large,
	Incomplete_Request,
}

parse_error_message :: proc(err: Parse_Error) -> (message: string) {
	switch err {
	case .Malformed_Request_Line:
		message = "Malformed Request Line"
	case .Invalid_Version:
		message = "Invalid Version"
	case .Header_Too_Large:
		message = "Header Too Large"
	case .Invalid_Method:
		message = "Invalid Method"
	case .None:
		message = "None"
	case .Malformed_Header:
		message = "Malformed Header"
	case .Incomplete_Request:
		message = "Incomplete Request"
	}

	return
}

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
	method:   Method,
	uri:      string,
	version:  Version,
	headers:  map[string]string,
	body:     []u8,
	raw:      []u8,
	has_body: bool,
	body_len: uint,
}

Response :: struct {
	version:  Version,
	status:   Status,
	headers:  map[string]string,
	body:     []u8,
	has_body: bool,
	body_len: uint,
}

response_init :: proc(res: ^Response) {
	res.version = .HTTP_1_1
	res.status = .OK
	res.headers = make(map[string]string)
}

response_set_header :: proc(res: ^Response, key: string, value: string) {
	res.headers[key] = value
}

response_set_body :: proc(res: ^Response, data: []u8) {
	res.body = data
	res.has_body = true
	res.body_len = uint(len(data))

	len_str := fmt.aprintf("%d", len(data))

	response_set_header(res, "Content-Length", len_str)
}

response_set_body_string :: proc(res: ^Response, text: string) {
	response_set_body(res, transmute([]u8)text)
}

response_serialize :: proc(res: ^Response, allocator := context.allocator) -> []u8 {
	b := strings.builder_make(allocator)

	version_str := res.version == .HTTP_1_0 ? "HTTP/1.0" : "HTTP/1.1"
	fmt.sbprintf(&b, "%s %d %s\r\n", version_str, int(res.status), status_reason(res.status))

	for key, value in res.headers {
		fmt.sbprintf(&b, "%s: %s\r\n", key, value)
	}

	strings.write_string(&b, "\r\n")

	if len(res.body) > 0 {
		append(&b.buf, ..res.body)
	}

	return b.buf[:]
}

parse_method_from_string :: proc(method_str: string) -> Method {
	switch method_str {
	case "GET":
		return .GET
	case "POST":
		return .POST
	case "HEAD":
		return .HEAD
	case "PUT":
		return .PUT
	case "DELETE":
		return .DELETE
	case "CONNECT":
		return .CONNECT
	case "OPTIONS":
		return .OPTIONS
	case "TRACE":
		return .TRACE
	case "PATCH":
		return .PATCH
	case:
		return .Invalid
	}
}

parse_http_version_from_string :: proc(http_str: string) -> Version {
	trimmed_str := strings.trim_right(http_str, "\r\n")
	switch trimmed_str {
	case "HTTP/1.0":
		return .HTTP_1_0
	case "HTTP/1.1":
		return .HTTP_1_1
	case:
		return .Unknown
	}
}

parse_request_line :: proc(
	req_line: string,
) -> (
	method: Method,
	uri: string,
	version: Version,
	parse_err: Parse_Error,
) {
	parts := strings.split(req_line, " ")
	defer delete(parts)

	if len(parts) < 3 {
		return Method.Invalid, "", Version.Unknown, Parse_Error.Malformed_Request_Line
	}

	method = parse_method_from_string(parts[0])

	if method == .Invalid {
		return Method.Invalid, "", Version.Unknown, Parse_Error.Malformed_Request_Line
	}

	uri = parts[1]
	version = parse_http_version_from_string(parts[2])

	if version == .Unknown {
		return Method.Invalid, "", Version.Unknown, Parse_Error.Malformed_Request_Line
	}

	parse_err = .None

	return method, uri, version, parse_err
}

parse_headers :: proc(headers_str: string, req: ^Request) -> Parse_Error {
	req.headers = make(map[string]string)

	lines := strings.split(headers_str, "\r\n")
	defer delete(lines)

	for line in lines {
		if len(line) == 0 {
			continue
		}

		parts := strings.split_n(line, ":", 2)
		defer delete(parts)

		if len(parts) != 2 {
			return .Malformed_Header
		}

		raw_key := strings.trim_space(parts[0])
		value := strings.trim_space(parts[1])

		key := strings.to_lower(raw_key)
		req.headers[key] = value

		if key == "content-length" {
			val_as_int, ok := strconv.parse_uint(value, 10)
			if !ok {
				return .Malformed_Header
			}

			req.has_body = true
			req.body_len = val_as_int
		}
	}

	return .None
}

parse_body :: proc(raw_body_str: string, req: ^Request) -> Parse_Error {
	if !req.has_body {
		req.body = nil
		return .None
	}

	if uint(len(raw_body_str)) < req.body_len {
		return .Incomplete_Request
	}

	body_start_idx := len(req.raw) - len(raw_body_str)

	req.body = req.raw[body_start_idx:body_start_idx + int(req.body_len)]

	return .None
}

parse_request :: proc(raw_data: []u8) -> (req: ^Request, parse_err: Parse_Error) {

	req = new(Request)
	req.raw = raw_data

	fmt.printfln("%#v", string(raw_data))

	if len(raw_data) == 0 {
		free(req)
		return nil, .Incomplete_Request
	}

	parts, ok := strings.split_n(string(raw_data), "\r\n\r\n", 2)
	defer delete(parts)
	if ok != .None {
		free(req)
		return nil, .Incomplete_Request
	}

	header_block := parts[0]
	raw_body := parts[1]

	header_parts: []string
	header_parts, ok = strings.split_n(string(header_block), "\r\n", 2)
	defer delete(header_parts)
	if ok != .None {
		free(req)
		return nil, .Malformed_Header
	}

	request_line := header_parts[0]
	rest_of_headers := header_parts[1]

	method, uri, version, err := parse_request_line(request_line)
	if err != .None {
		free(req)
		return nil, err
	}

	req.method = method
	req.uri = uri
	req.version = version

	parse_headers_err := parse_headers(rest_of_headers, req)
	if parse_headers_err != .None {
		for key, _ in req.headers {delete(key)}
		delete(req.headers)
		free(req)
		return nil, parse_headers_err
	}

	parse_body_err := parse_body(raw_body, req)
	if parse_body_err != .None {
		for key, _ in req.headers {delete(key)}
		delete(req.headers)
		free(req)
		return nil, parse_body_err
	}

	return req, .None
}

Status :: enum {
	Continue                        = 100,
	Switching_Protocols             = 101,
	Processing                      = 102,
	Early_Hints                     = 103,
	OK                              = 200,
	Created                         = 201,
	Accepted                        = 202,
	Non_Authoritative_Information   = 203,
	No_Content                      = 204,
	Reset_Content                   = 205,
	Partial_Content                 = 206,
	Multi_Status                    = 207,
	Already_Reported                = 208,
	IM_Used                         = 226,
	Multiple_Choices                = 300,
	Moved_Permanently               = 301,
	Found                           = 302,
	See_Other                       = 303,
	Not_Modified                    = 304,
	Temporary_Redirect              = 307,
	Permanent_Redirect              = 308,
	Bad_Request                     = 400,
	Unauthorized                    = 401,
	Payment_Required                = 402,
	Forbidden                       = 403,
	Not_Found                       = 404,
	Method_Not_Allowed              = 405,
	Not_Acceptable                  = 406,
	Proxy_Authentication_Required   = 407,
	Request_Timeout                 = 408,
	Conflict                        = 409,
	Gone                            = 410,
	Length_Required                 = 411,
	Precondition_Failed             = 412,
	Content_Too_Large               = 413,
	URI_Too_Long                    = 414,
	Unsupported_Media_Type          = 415,
	Range_Not_Satisfiable           = 416,
	Expectation_Failed              = 417,
	Im_A_Teapot                     = 418,
	Misdirected_Request             = 421,
	Unprocessable_Content           = 422,
	Locked                          = 423,
	Failed_Dependency               = 424,
	Too_Early                       = 425,
	Upgrade_Required                = 426,
	Precondition_Required           = 428,
	Too_Many_Requests               = 429,
	Request_Header_Fields_Too_Large = 431,
	Unavailable_For_Legal_Reasons   = 451,
	Internal_Server_Error           = 500,
	Not_Implemented                 = 501,
	Bad_Gateway                     = 502,
	Service_Unavailable             = 503,
	Gateway_Timeout                 = 504,
	HTTP_Version_Not_Supported      = 505,
	Variant_Also_Negotiates         = 506,
	Insufficient_Storage            = 507,
	Loop_Detected                   = 508,
	Not_Extended                    = 510,
	Network_Authentication_Required = 511,
	Unknown                         = 1000,
}

status_reason :: proc(s: Status) -> string {
	switch s {
	case .Continue:
		return "Continue"
	case .Switching_Protocols:
		return "Switching Protocols"
	case .Processing:
		return "Processing"
	case .Early_Hints:
		return "Early Hints"

	case .OK:
		return "OK"
	case .Created:
		return "Created"
	case .Accepted:
		return "Accepted"
	case .Non_Authoritative_Information:
		return "Non-Authoritative Information"
	case .No_Content:
		return "No Content"
	case .Reset_Content:
		return "Reset Content"
	case .Partial_Content:
		return "Partial Content"
	case .Multi_Status:
		return "Multi-Status"
	case .Already_Reported:
		return "Already Reported"
	case .IM_Used:
		return "IM Used"

	case .Multiple_Choices:
		return "Multiple Choices"
	case .Moved_Permanently:
		return "Moved Permanently"
	case .Found:
		return "Found"
	case .See_Other:
		return "See Other"
	case .Not_Modified:
		return "Not Modified"
	case .Temporary_Redirect:
		return "Temporary Redirect"
	case .Permanent_Redirect:
		return "Permanent Redirect"
	case .Bad_Request:
		return "Bad Request"
	case .Unauthorized:
		return "Unauthorized"
	case .Payment_Required:
		return "Payment Required"
	case .Forbidden:
		return "Forbidden"
	case .Not_Found:
		return "Not Found"
	case .Method_Not_Allowed:
		return "Method Not Allowed"
	case .Not_Acceptable:
		return "Not Acceptable"
	case .Proxy_Authentication_Required:
		return "Proxy Authentication Required"
	case .Request_Timeout:
		return "Request Timeout"
	case .Conflict:
		return "Conflict"
	case .Gone:
		return "Gone"
	case .Length_Required:
		return "Length Required"
	case .Precondition_Failed:
		return "Precondition Failed"
	case .Content_Too_Large:
		return "Content Too Large"
	case .URI_Too_Long:
		return "URI Too Long"
	case .Unsupported_Media_Type:
		return "Unsupported Media Type"
	case .Range_Not_Satisfiable:
		return "Range Not Satisfiable"
	case .Expectation_Failed:
		return "Expectation Failed"
	case .Im_A_Teapot:
		return "I'm a teapot"
	case .Misdirected_Request:
		return "Misdirected Request"
	case .Unprocessable_Content:
		return "Unprocessable Content"
	case .Locked:
		return "Locked"
	case .Failed_Dependency:
		return "Failed Dependency"
	case .Too_Early:
		return "Too Early"
	case .Upgrade_Required:
		return "Upgrade Required"
	case .Precondition_Required:
		return "Precondition Required"
	case .Too_Many_Requests:
		return "Too Many Requests"
	case .Request_Header_Fields_Too_Large:
		return "Request Header Fields Too Large"
	case .Unavailable_For_Legal_Reasons:
		return "Unavailable For Legal Reasons"
	case .Internal_Server_Error:
		return "Internal Server Error"
	case .Not_Implemented:
		return "Not Implemented"
	case .Bad_Gateway:
		return "Bad Gateway"
	case .Service_Unavailable:
		return "Service Unavailable"
	case .Gateway_Timeout:
		return "Gateway Timeout"
	case .HTTP_Version_Not_Supported:
		return "HTTP Version Not Supported"
	case .Variant_Also_Negotiates:
		return "Variant Also Negotiates"
	case .Insufficient_Storage:
		return "Insufficient Storage"
	case .Loop_Detected:
		return "Loop Detected"
	case .Not_Extended:
		return "Not Extended"
	case .Network_Authentication_Required:
		return "Network Authentication Required"
	case .Unknown:
		return "Unknown"
	}

	return "Unknown Status"
}
