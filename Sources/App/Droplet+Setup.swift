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

enum BackendError: Error {
	case invalidUserID
	case noUserID
	case userIPBanned
	case parameterMissingX
	case parameterMissingY
	case invalidCoordinates
	case invalidColorID
	case parameterMissingColorID
	case none
}

extension Droplet {
    public func setup() throws {
		//Set up routes
        try setupRoutes()
		
        //Set up websocket
		socket("canvas") { message, webSocket in
			
			print("User connected")
			
			var user: User? = nil
			
			//Received JSON request from client
			webSocket.onText = { ws, text in
				//TODO: Session tokens if we have time for that
				let json = try JSON(bytes: Array(text.utf8))
				if let reqType = json.object?["requestType"]?.string {
					do {
						switch (reqType) {
						case "initialAuth":
							user = try initialAuth(message: message, socket: webSocket)
						case "getCanvas":
							try sendCanvas(json: json, user: user!)
						case "postTile":
							try handleTilePlace(json: json)
						case "getColors":
							try sendColors(json: json, user: user!)
						case "getTileData": break
						default: break
						}
					} catch {
						sendError(error: error, socket: webSocket)
					}
				}
			}
			
			//Connection closed
			webSocket.onClose = { ws in
				guard let u = user else {
					return
				}
				print("User \(u.uuid) at \(u.ip) disconnected")
				canvas.connections.removeValue(forKey: u)
			}
		}
		
		//Authentication
		func initialAuth(message: Request, socket: WebSocket) throws -> User {
			let user = User()
			user.ip = message.peerHostname!
			user.socket = socket
			canvas.connections[user] = socket
			
			//Send back generated UUID
			var structure = [[String: NodeRepresentable]]()
			structure.append(["responseType": "authSuccessful",
			                  "uuid": user.uuid])
			
			let json = try JSON(node: structure)
			
			user.sendJSON(json: json)
			
			return user
		}
		
		func userForUUID(uuid: String) -> User {
			//return canvas.connections.index(forKey: uuid)
			/*var user: User!
			canvas.connections.forEach { dict in
			if dict.key.uuid == uuid {
			user = dict.key
			}
			}*/
			return User(uuid: "1")
		}
		
		func colorForID(colorID: Int) -> TileColor {
			var color: TileColor!
			canvas.colors.forEach { c in
				if c.ID == colorID {
					color = c
				}
			}
			return color
		}
		
		// Responses
		func sendColors(json: JSON, user: User) throws {
			var structure = [[String: NodeRepresentable]]()
			structure.append(["responseType": "colorList"])
			for color in canvas.colors {
				structure.append([
					"R": color.color.red,
					"G": color.color.green,
					"B": color.color.blue,
					"ID": color.ID])
			}
			guard let json = try? JSON(node: structure) else {
				return
			}
			user.sendJSON(json: json)
		}
		
		//TODO: Use a raw base64 binary for this possibly
		//TODO: Require userID for this to prevent unauthed users (IP banned) from spamming getCanvas
		func sendCanvas(json: JSON, user: User) throws {
			var structure = [[String: NodeRepresentable]]()
			structure.append(["responseType": "fullCanvas"])
			for tile in canvas.tiles {
				structure.append([
					"X": tile.pos.x,
					"Y": tile.pos.y,
					"colorID":tile.color])
			}
			guard let json = try? JSON(node: structure) else {
				return
			}
			user.sendJSON(json: json)
		}
		
		//User requests
		func handleTilePlace(json: JSON) throws {
			//Make sure userID is valid
			//Make sure color is valid
			
			//First get params
			guard let userID = json.object?["userID"]?.string,
				let Xcoord = json.object?["X"]?.int, Xcoord <= canvas.width,
				let Ycoord = json.object?["Y"]?.int, Ycoord <= canvas.height,
				let colorID = json.object?["colorID"]?.int else {
					//Reply with some error message
					return
			}
			
			//Verifications here (uuid valid? tiles available? etc)
			//TODO
			//Then store this action to DB
			
			//Then update canvas
			canvas.tiles[Xcoord + Ycoord * canvas.width].placer = userForUUID(uuid: userID)
			canvas.tiles[Xcoord + Ycoord * canvas.width].color  = colorID
			canvas.tiles[Xcoord + Ycoord * canvas.width].placeTime = Date() //This current time
			
			//And finally send this update out to other clients
			canvas.updateTileToClients(tile: canvas.tiles[Xcoord + Ycoord * canvas.width])
		}
		
		/*
		case invalidUserID
		case noUserID
		case userIPBanned
		case parameterMissingX
		case parameterMissingY
		case invalidCoordinates
		case invalidColorID
		case parameterMissingColorID
		case none
		*/
		
		//Error handling
		func sendError(error: BackendError, socket: WebSocket) {
			var errorMessage = String()
			switch error {
			case .none:
				errorMessage = "No error!"
			case .invalidUserID:
				errorMessage = "Invalid user ID provided"
			case .noUserID:
				errorMessage = "No user ID provided (get it with initialAuth)"
			case .userIPBanned:
				errorMessage = "Server authentication error"
			case .parameterMissingX:
				errorMessage = "Missing X coordinate"
			case .parameterMissingY:
				errorMessage = "Missing Y coordinate"
			case .invalidCoordinates:
				errorMessage = "Invalid coordinates provided"
			case .invalidColorID:
				errorMessage = "Invalid color ID provided"
			case .parameterMissingColorID:
				errorMessage = "Missing color ID parameter"
			default: break
			}
			var structure = [[String: NodeRepresentable]]()
			structure.append(["responseType": "error",
			                  "errorMessage": errorMessage])
			guard let json = try? JSON(node: structure) else {
				return
			}
			try? socket.send(json.serialize().makeString())
		}
		
    }
}

/*
TODO:
Add UUID check for sendCanvas
Add UUID check for sendColors
Add dimensions to fullCanvas
*/

/*
API doc:

First do initialAuth
Then run getColors
Then run getCanvas

Request types:
- "initialAuth", params: none
- "getCanvas",   params: "userID"
- "postTile"     params: "userID", "X", "Y", "colorID"
- "getTileData"  params: "userID", "X", "Y" (Not finished)
- "getColors"    params: "userID"

Response types ("responseType"):
- "tileUpdate", params: "X", "Y", "colorID"
- "authSuccessful", params: "uuid"
- "fullCanvas", params: Array of "X", "Y", "colorID"
- "colorList",  params: Array of "R", "G", "B", "ID"
- "error"		params: "errorMessage", Error message in human-readable form
*/

