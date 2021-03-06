// Router.swift
//
// The MIT License (MIT)
//
// Copyright (c) 2015 Zewo
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Core
import HTTP
public struct Router: ResponderType {
    public let routes: [Route]
    public let fallback: Request throws -> Response

    public struct Route: ResponderType {
        public let path: String
        public let methods: Set<Method>
        public let routeRespond: Request throws -> Response

        private let parameterKeys: [String]
        private let regularExpression: Regex

        public init(path: String, methods: Set<Method>, routeRespond: Request throws -> Response) {
            self.path = path
            self.methods = methods
            self.routeRespond = routeRespond

            let parameterRegularExpression = try! Regex(pattern: ":([[:alnum:]]+)")
            let pattern = parameterRegularExpression.replace(path, withTemplate: "([[:alnum:]]+)")

            self.parameterKeys = parameterRegularExpression.groups(path)
            self.regularExpression = try! Regex(pattern: "^" + pattern + "$")
        }

        func matchesRequest(request: Request) -> Bool {
            return regularExpression.matches(request.uri.path!) && methods.contains(request.method)
        }

        public  func respond(request: Request) throws -> Response {
            var request = request
            let values = self.regularExpression.groups(request.uri.path!)

            for (index, key) in parameterKeys.enumerate() {
                request.parameters[key] = values[index]
            }

            return try routeRespond(request)
        }
    }

    public final class RouterBuilder {
        let basePath: String
        var routes: [Route] = []

        init(basePath: String) {
            self.basePath = basePath
        }

        var fallback: Request throws -> Response = { request in
            return Response(statusCode: 404, reasonPhrase: "Not Found")
        }

        public func router(path: String, _ router: Router) {
            let newRoutes = router.routes.map { route in
                Route(
                    path: self.basePath + path + route.path,
                    methods: route.methods,
                    routeRespond: route.routeRespond
                )
            }

            routes.appendContentsOf(newRoutes)
        }

        public func fallback(fallback: Request throws -> Response) {
            self.fallback = fallback
        }

        public func fallback(responder: ResponderType) {
            fallback(responder.respond)
        }

        public func any(path: String, _ respond: Request throws -> Response) {
            let route = Route(
                path: basePath + path,
                methods: [
                    .GET,
                    .POST,
                    .PUT,
                    .PATCH,
                    .DELETE
                ],
                routeRespond: respond
            )

            routes.append(route)
        }

        public func any(path: String, _ responder: ResponderType) {
            any(path, responder.respond)
        }

        public func get(path: String, _ respond: Request throws -> Response) {
            let route = Route(
                path: basePath + path,
                methods: [.GET],
                routeRespond: respond
            )

            routes.append(route)
        }

        public func get(path: String, _ responder: ResponderType) {
            get(path, responder.respond)
        }

        public func post(path: String, _ respond: Request throws -> Response) {
            let route = Route(
                path: basePath + path,
                methods: [.POST],
                routeRespond: respond
            )

            routes.append(route)
        }

        public func post(path: String, _ responder: ResponderType) {
            post(path, responder.respond)
        }

        public func put(path: String, _ respond: Request throws -> Response) {
            let route = Route(
                path: basePath + path,
                methods: [.PUT],
                routeRespond: respond
            )

            routes.append(route)
        }

        public func put(path: String, _ responder: ResponderType) {
            put(path, responder.respond)
        }

        public func patch(path: String, _ respond: Request throws -> Response) {
            let route = Route(
                path: basePath + path,
                methods: [.PATCH],
                routeRespond: respond
            )

            routes.append(route)
        }

        public func patch(path: String, _ responder: ResponderType) {
            patch(path, responder.respond)
        }

        public func delete(path: String, _ respond: Request throws -> Response) {
            let route = Route(
                path: basePath + path,
                methods: [.DELETE],
                routeRespond: respond
            )

            routes.append(route)
        }

        public func delete(path: String, _ responder: ResponderType) {
            delete(path, responder.respond)
        }
    }

    public init(_ basePath: String = "", build: (router: RouterBuilder) -> Void) {
        let builder = RouterBuilder(basePath: basePath)
        build(router: builder)

        fallback = builder.fallback
        routes = builder.routes
    }

    public init(routes: [Route], fallback: Request throws -> Response) {
        self.routes = routes
        self.fallback = fallback
    }

    public func respond(request: Request) throws -> Response {
        for route in routes {
            if route.matchesRequest(request) {
                return try route.respond(request)
            }
        }
        return try fallback(request)
    }
}
