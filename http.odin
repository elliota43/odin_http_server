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
	}
}
