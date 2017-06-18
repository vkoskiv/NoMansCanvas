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
				user?.socket = ws
				canvas.connections[(user?.uuid)!] = ws
				//Return generated UUID
				let structure: [String: NodeRepresentable] = [
					"response": "authSuccessful",
					"uuid": user?.uuid]
				
				guard let json = try? JSON(node: structure) else {
					return
				}
				
				user?.sendJSON(json: json)
			}
			
			func sendCanvas() {
				var structure: [[String: NodeRepresentable]] = [[:]]
				for tile in canvas.tiles {
					structure.append([
						"x": tile.pos.x,
						"y": tile.pos.y,
						"ID":tile.color.ID])
				}
				guard let json = try? JSON(node: structure) else {
					return
				}
				user?.sendJSON(json: json)
			}
			
			func handleTilePlace(json: JSON) {
				//Make sure userID is valid
				//Make sure color is valid
				
				//First get params
				//params: userID, X+Y coords, colorID
				guard let userID = json.object?["userID"]?.string else {
					//Return error
					return
				}
				guard let Xcoord = json.object?["X"]?.int else {
					//Return error
					return
				}
				guard let Ycoord = json.object?["Y"]?.int else {
					//Return error
					return
				}
				guard let colorID = json.object?["colorID"]?.int else {
					//Return error
					return
				}
				//Make sure coords are good
				if Xcoord > canvas.width {
					//Return error
				}
				if Ycoord > canvas.height {
					//Return error
				}
				
			}
			
			//Received JSON request from client
			ws.onText = { ws, text in
				//TODO: Session tokens if we have time for that
				let json = try JSON(bytes: Array(text.utf8))
				if let reqType = json.object?["requestType"]?.string {
					switch (reqType) {
						case "initialAuth":
							initialAuth()
						case "getCanvas":
							sendCanvas()
						case "postTile":
							handleTilePlace(json: json)
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
				print("User \(u.uuid) at \(u.ip) disconnected")
				canvas.connections.removeValue(forKey: u.uuid)
			}
		}
    }
}
