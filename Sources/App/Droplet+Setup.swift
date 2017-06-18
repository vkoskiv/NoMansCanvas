@_exported import Vapor

let canvas = Canvas()

extension Droplet {
    public func setup() throws {
		//Set up routes
        try setupRoutes()
		
        //Set up websocket
		socket("canvas") { req, ws in
			
			//var user: User? = nil
			
			//Received JSON request from client
			ws.onText = { ws, text in
				//Handle different request types
				//initial auth, tile post, getCanvas
				//getTileData when highlight pixel, who edited it last? RGB value?
				
				//TODO: Session tokens if we have time for that
				
				let json = try JSON(bytes: Array(text.utf8))
				if let reqType = json.object?["requestType"]?.string {
					switch (reqType) {
						case "initialAuth": break
						case "getCanvas": break
						case "postTile": break
						case "getTileData": break
						default: break
					}
				}
			}
			
			//Connection closed
			ws.onClose = { ws in
				
			}
		}
    }
}
