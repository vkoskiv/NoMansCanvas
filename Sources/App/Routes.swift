import Vapor

extension Droplet {
    func setupRoutes() throws {
        get("hello") { req in
            var json = JSON()
            try json.set("hello", "world")
            return json
        }

        get("/") { _ in
            return "This is the API for the NoMansCanvas project."
        }
        
        try resource("posts", PostController.self)
    }
}
