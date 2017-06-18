@_exported import Vapor

let canvas = Canvas()

/*
TODO:

InitialAuth (First ever join, no params?) Return UUID, then client requests getUserStats, if IP banned, return nothing
getCanvas (Logging in, no params?) Return canvas in an efficient format
postTile (Client posts a new tile, params: userID, X+Y coords, colorID) Return OK or incorrect param
getTileData (User has highlighted a tile, client sends this to get the info for that tile, params: userID, X+Y coords)
getUserStats (client has UUID, is returning, parameters: UUID) returns player stats
*/

extension Droplet {
    public func setup() throws {
		//Set up routes
        try setupRoutes()
		
        //Set up websocket
		socket("canvas") { req, ws in
			
			print("User connected")
			
			var user: User? = nil
			
			func initialAuth() {
				//TODO: Check for IP ban here
				user = User(ip: req.peerHostname!)
				canvas.connections[(user?.uuid)!] = ws
				//Return generated UUID
				let structure: [String: NodeRepresentable] = [
					"response": "authSuccessful",
					"uuid": user?.uuid]
				
				guard let json = try? JSON(node: structure) else {
					return
				}
				
				canvas.sendJSON(to: user!, json: json)
			}
			
			//Received JSON request from client
			ws.onText = { ws, text in
				//TODO: Session tokens if we have time for that
				let json = try JSON(bytes: Array(text.utf8))
				if let reqType = json.object?["requestType"]?.string {
					switch (reqType) {
						case "initialAuth":
							initialAuth()
						case "getCanvas": break
						case "postTile": break
						case "getTileData": break
						default: break
					}
				}
			}
			
			//Connection closed
			ws.onClose = { ws in
				guard let u = user else {
					return
				}
				print("User \(u.uuid) disconnected")
				canvas.connections.removeValue(forKey: u.uuid)
			}
		}
    }
}
