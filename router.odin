package main

// Defines a unique route based on Method and path.
Route_Key :: struct {
	method: Method,
	path:   string,
}

// The Router holds a map of the Routes, which map a `Route_Key` to a `Handler_Proc`.
Router :: struct {
	routes: map[Route_Key]Handler_Proc,
}

// Initializes the router.
router_init :: proc(r: ^Router) {
	r.routes = make(map[Route_Key]Handler_Proc)
}

// Register a new route.
router_add_route :: proc(r: ^Router, method: Method, path: string, handler: Handler_Proc) {
	key := Route_Key {
		method = method,
		path   = path,
	}
	r.routes[key] = handler
}


// Dispatches the route.
// TODO: handle patterns/route parameters. Right now it just matches the route by req.method and req.uri.
router_dispatch :: proc(r: ^Router, req: ^Request, res: ^Response) {
	key := Route_Key {
		method = req.method,
		path   = req.uri,
	}

	if handler, exists := r.routes[key]; exists {
		handler(req, res)
	} else {
		res.status = .Not_Found
		response_set_header(res, "Content-Type", "text/plain")
		response_set_body_string(res, "404 - Not Found")
	}
}
