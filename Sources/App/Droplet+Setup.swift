@_exported import Vapor
import Foundation

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
	case userNotFound
	case notAuthenticated
	case invalidRequestType
	case noUserID
	case userIPBanned
	case parameterMissingX
	case parameterMissingY
	case invalidCoordinates
	case invalidColorID
	case parameterMissingColorID
	case noTilesRemaining
	case userIDMismatch
	case none
}

extension Droplet {
    public func setup() throws {
		//Set up routes
        try setupRoutes()
		
        //Set up websocket
		socket("canvas") { message, webSocket in
			
			print("User connected")
			
			var user: User = User()
			
			background {
				while webSocket.state == .open {
					try? webSocket.ping()
					self.console.wait(seconds: 25)
				}
			}
			
			background {
				while webSocket.state == .open {
					if user.isAuthed && (user.remainingTiles < user.maxTiles) {
						var structure = [[String: NodeRepresentable]]()
						structure.append(["responseType": "incrementTileCount",
						                  "amount": 1])
						do {
							let json = try JSON(node: structure)
							user.remainingTiles += 1
							try user.save()
							try webSocket.send(json.serialize().makeString())
						} catch {
							print("Error: \(error)")
							sendError(error: error, socket: webSocket)
						}
					}
					self.console.wait(seconds: Double(user.tileRegenSeconds))
				}
			}
			
			//Received JSON request from client
			webSocket.onText = { ws, text in
				print("Received request: " + text)
				//TODO: Session tokens if we have time for that
				let json = try JSON(bytes: Array(text.utf8))
				if let reqType = json.object?["requestType"]?.string {
					
					do {
						
						//Handle strange case where UUID provided isn't found, and user = nil
						if !(user.isAuthed) && (reqType != "initialAuth" && reqType != "auth") {
							throw BackendError.notAuthenticated
						}
						
						switch (reqType) {
						case "initialAuth":
							user = try initialAuth(message: message, socket: webSocket)
						case "auth":
							user = try reAuth(json: json, message: message, socket: webSocket)
						case "getCanvas":
							try sendCanvas(json: json, user: user)
						case "postTile":
							try handleTilePlace(json: json, user: user)
						case "postColor":
							try handleAddColor(json: json)
						case "getColors":
							try sendColors(json: json, user: user)
						case "getTileData":
							try sendTileData(json: json, user: user)
						case "getStats": break //Connected users
						default:
							throw BackendError.invalidRequestType
						}
					} catch {
						sendError(error: error, socket: webSocket)
					}
				}
			}
			
			//TODO: Add close reason?
			//Connection closed
			webSocket.onClose = { ws in
				let u = user
				//Update lastConnected and save to DB
				u.lastConnected = Int64(Date().timeIntervalSince1970)
				try u.save()
				
				print("User \(u.uuid) at \(u.ip) disconnected")
				canvas.connections.removeValue(forKey: u)
			}
		}
		
		//Authentication
		func initialAuth(message: Request, socket: WebSocket) throws -> User {
			let user = User()
			user.ip = (message.peerHostname?.string)!
			user.socket = socket
			user.username = "Anonymous"
			user.isAuthed = true
			
			user.remainingTiles = 60
			user.tileRegenSeconds = 10
			user.totalTilesPlaced = 0
			
			user.uuid = UUID().uuidString
			canvas.connections[user] = socket
			
			//Send back generated UUID
			var structure = [[String: NodeRepresentable]]()
			structure.append(["responseType": "authSuccessful",
			                  "uuid": user.uuid,
			                  "remainingTiles": user.remainingTiles])
			
			let json = try JSON(node: structure)
			
			user.sendJSON(json: json)
			
			//Save user to DB
			try user.save()
			
			//And return for state
			return user
		}
		
		func reAuth(json: JSON, message: Request, socket: WebSocket) throws -> User {
			
			guard let userID = json.object?["userID"]?.string else {
				throw BackendError.noUserID
			}
			
			guard let user = try User.makeQuery().filter("uuid", userID).first() else {
				throw BackendError.userNotFound
			}
			
			//guard user.isBanned == false else {
			//	  throw BackendError.userIPBanned
			//}
		
			//Now set the newest WebSocket
			user.ip = (message.peerHostname?.string)!
			user.socket = socket
			user.isAuthed = true
			canvas.connections[user] = socket
			
			//Check for excess tiles (shouldn't need this)
			if user.remainingTiles > user.maxTiles {
				user.remainingTiles = user.maxTiles
			}
			
			//Update user tileCount based on diff of last login and now
			let diffSeconds = Int64(Date().timeIntervalSince1970) - user.lastConnected
			let tilesToAdd = diffSeconds / Int64(user.tileRegenSeconds)
			user.remainingTiles += Int(tilesToAdd >= Int64(user.maxTiles) ? Int64(user.maxTiles - user.remainingTiles) : tilesToAdd)
			
			var structure = [[String: NodeRepresentable]]()
			structure.append(["responseType": "reAuthSuccessful",
			                  "remainingTiles": user.remainingTiles])
			
			let json = try JSON(node: structure)
			
			user.sendJSON(json: json)
			
			//Now save this new user data to DB
			try user.save()
			
			//And return it for the state
			return user
		}
		
		// Responses
		//TODO: user-specific color lists
		func sendColors(json: JSON, user: User) throws {
			
			guard let userID = json.object?["userID"]?.string else {
				throw BackendError.noUserID
			}
			
			guard try userIDValid(id: userID) else {
				throw BackendError.invalidUserID
			}
			
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
		func sendCanvas(json: JSON, user: User) throws {
			guard let userID = json["userID"]?.string else {
				throw BackendError.noUserID
			}
			
			guard try userIDValid(id: userID) else {
				throw BackendError.invalidUserID
			}
			
			guard user.isAuthed else {
				throw BackendError.notAuthenticated
			}
			
			var structure: [[String: NodeRepresentable]] = canvas.tiles.map { tile in
				return [
					"colorID": tile.color
				]
			}
			structure.insert(["responseType": "fullCanvas"], at: 0)
			
			guard let json = try? JSON(node: structure) else {
				return
			}
			print("Sending Canvas: \((try json.serialize().count)/1024)KB")
			user.sendJSON(json: json)
		}
		
		func userIDValid(id: String) throws -> Bool {
			guard (try User.makeQuery().filter("uuid", id).first()) != nil else {
				return false
			}
			return true
		}
		
		//- "getTileData"  params: "userID", "X", "Y" (Not finished)
		func sendTileData(json: JSON, user: User) throws {
			//Get params
			guard let userID = json.object?["userID"]?.string else {
				throw BackendError.noUserID
			}
			
			guard user.isAuthed else {
				throw BackendError.notAuthenticated
			}
			
			guard let Xcoord = json.object?["X"]?.int else {
				throw BackendError.parameterMissingX
			}
			guard let Ycoord = json.object?["Y"]?.int else {
				throw BackendError.parameterMissingY
			}
			//Verify coords
			//FIXME: Negative coords crash here
			guard Xcoord <= canvas.width,
				Ycoord <= canvas.height else {
					throw BackendError.invalidCoordinates
			}
			//Verify userID
			guard try userIDValid(id: userID) else {
				throw BackendError.invalidUserID
			}
			//Get tile data and return it
			
			//TODO: Finish sendTileData()
		}
		
		//FIXME: pass user into handleTilePlace instead of UUID which COULD be faked, though it'd have to be valid
		//User requests
		func handleTilePlace(json: JSON, user: User) throws {
			//First get params
			guard let userID = json.object?["userID"]?.string else {
				throw BackendError.noUserID
			}
			guard let Xcoord = json.object?["X"]?.int else {
				throw BackendError.parameterMissingX
			}
			guard let Ycoord = json.object?["Y"]?.int else {
				throw BackendError.parameterMissingY
			}
			guard let colorID = json.object?["colorID"]?.int else {
				throw BackendError.parameterMissingColorID
			}
			
			guard user.remainingTiles > 0 else {
				throw BackendError.noTilesRemaining
			}
			
			guard user.isAuthed else {
				throw BackendError.notAuthenticated
			}
			
			guard user.uuid == userID else {
				throw BackendError.userIDMismatch
			}
			
			//Verifications here (uuid valid? tiles available? etc)
			//Check that coordinates are valid
			//FIXME: Negative values crash here
			guard Xcoord <= canvas.width,
				  Ycoord <= canvas.height else {
					throw BackendError.invalidCoordinates
			}
			
			//Verify userID is valid
			guard try userIDValid(id: userID) else {
				throw BackendError.invalidUserID
			}
			
			//Then store this action to DB separate table
			//TODO: action table
			
			//Then update canvas
			canvas.tiles[Xcoord + Ycoord * canvas.width].placer = user
			canvas.tiles[Xcoord + Ycoord * canvas.width].color  = colorID
			canvas.tiles[Xcoord + Ycoord * canvas.width].placeTime = String() //This current time
			
			do {
				try canvas.tiles[Xcoord + Ycoord * canvas.width].save()
			} catch {
				print("Failed to save tile to DB!")
			}
			
			//Update user tileCount
			user.remainingTiles -= 1
			user.totalTilesPlaced += 1
			//Save to DB
			try user.save()
			
			//And finally send this update out to other clients
			canvas.updateTileToClients(tile: canvas.tiles[Xcoord + Ycoord * canvas.width])
		}
		
		func handleAddColor(json: JSON) throws {
			//TODO: Create handleAddColor()
		}
		
		//Error handling
		func sendError(error: Error, socket: WebSocket) {
			var errorMessage = String()
			switch error {
			case BackendError.none:
				errorMessage = "No error!"
			case BackendError.invalidUserID:
				errorMessage = "Invalid user ID provided"
			case BackendError.noUserID:
				errorMessage = "No user ID provided (get it with initialAuth)"
			case BackendError.userIPBanned:
				errorMessage = "Server authentication error"
			case BackendError.parameterMissingX:
				errorMessage = "Missing X coordinate"
			case BackendError.parameterMissingY:
				errorMessage = "Missing Y coordinate"
			case BackendError.invalidCoordinates:
				errorMessage = "Invalid coordinates provided"
			case BackendError.invalidColorID:
				errorMessage = "Invalid color ID provided"
			case BackendError.parameterMissingColorID:
				errorMessage = "Missing color ID parameter"
			case BackendError.invalidRequestType:
				errorMessage = "Invalid requestType provided"
			case BackendError.userNotFound:
				errorMessage = "User not found! Get a new UUID with initialAuth"
			case BackendError.notAuthenticated:
				errorMessage = "Not authenticated yet."
			case BackendError.noTilesRemaining:
				errorMessage = "No tiles remaining!"
			case BackendError.userIDMismatch:
				errorMessage = "User ID Mismatch! Reauthenticate maybe."
			default:
				print(error)
			}
			print(errorMessage)
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
API µDoc:

First do initialAuth
Then run getColors
Then run getCanvas

Request types:
- "initialAuth", params: none
- "auth",        params: "userID"
- "getCanvas",   params: "userID"
- "postTile"     params: "userID", "X", "Y", "colorID"
- "getTileData"  params: "userID", "X", "Y" (Not finished)
- "getColors"    params: "userID"

Response types ("responseType"):
- "tileUpdate", params: "X", "Y", "colorID"
- "authSuccessful", params: "uuid"
- "reAuthSuccessful", params: TO BE ADDED
- "fullCanvas", params: Array of "X", "Y", "colorID"
- "colorList",  params: Array of "R", "G", "B", "ID"
- "error"		params: "errorMessage", Error message in human-readable form
*/

