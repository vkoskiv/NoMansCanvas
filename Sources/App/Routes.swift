import Vapor

extension Droplet {
	func setupRoutes() throws {
		post("message") { req in
			guard req.data["pw"]?.string == "placeholder" else {
				return "invalid"
			}
			guard let msg = req.data["msg"]?.string else {
				return "No message"
			}
			
			canvas.sendAnnouncement(msg: msg)
			return "message sent!"
		}
		
		post("shutdown") { req in
			guard req.data["pw"]?.string == "placeholder" else {
				return "invalid"
			}
			print("shutting down. Disconnecting \(canvas.connections.count) nodes")
			canvas.shutdown()
			abort()
			return "done"
		}

        get("/") { _ in
            return "This is the API for the NoMansCanvas project."
        }
        
        try resource("posts", PostController.self)
    }
}
