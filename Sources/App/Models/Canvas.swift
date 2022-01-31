//
//  Canvas.swift
//  place
//
//  Created by Valtteri Koskivuori on 18/06/2017.
//
//

import Vapor
import MySQLProvider

class Canvas {
	//Connection is a key-val pair; User:WebSocket
	var connections: [User: WebSocket]
	var tiles: [Tile] = []
	var width: Int = 512
	var height: Int = 512
	
	//Colors, people may add additional ones
	var colors: [TileColor]
	
	func updateTileToClients(tile: Tile) {
		//We've received a tile change, it's been approved, send that update to ALL connected clients
		var structure = [[String: NodeRepresentable]]()
		
		structure.append(["responseType": "tileUpdate",
		                  "X": tile.pos.x,
		                  "Y": tile.pos.y,
		                  "colorID": tile.color])
		//Create json
		guard let json = try? JSON(node: structure) else {
			print("Failed to create JSON in updateTileToClients()")
			return
		}
		//Send to all connected users
		sendJSON(json: json)
	}
	
	func sendAnnouncement(msg: String) {		
		var structure = [[String: NodeRepresentable]]()
		structure.append(["responseType": "announcement",
						  "message": msg])
		
		guard let json = try? JSON(node: structure) else {
			print("Failed to create JSON in sendAnnouncement()")
			return
		}
		
		sendJSON(json: json)
	}
	
	func shutdown() {
		var structure = [[String: NodeRepresentable]]()
		structure.append(["responseType": "disconnecting"])
		
		guard let json = try? JSON(node: structure) else {
			print("Failed to create JSON in shutdown()")
			return
		}
		
		for (user, socket) in connections {
			do {
				try socket.send(json.serialize().makeString())
				try socket.close()
				canvas.connections.removeValue(forKey: user)
			} catch {
				print("oops?")
			}
		}
		print("Closed all connections.")
	}
	
	//Send to all users
	func sendJSON(json: JSON) {
		for (user, socket) in connections {
			do {
				try socket.send(json.serialize().makeString())
			} catch {
				try? socket.close()
				canvas.connections.removeValue(forKey: user)
			}
		}
	}
	
	//Init canvas, load it from the DB here
	init() {
		connections = [:]
		//Add some default colors. Remember to preserve IDs, as existing drawings use em for now
		colors = [
			TileColor(color: Color(with: 255,	green: 255, blue: 255),		id: 3),//White
			TileColor(color: Color(with: 221,	green: 221, blue: 221),		id: 10),//Dark white
			TileColor(color: Color(with: 117,	green: 117, blue: 117),		id: 11),//Grey
			TileColor(color: Color(with: 0,		green: 0,	blue: 0),		id: 4),//Black
			TileColor(color: Color(with: 219,	green: 0,	blue: 5	),		id: 0),//Red
			TileColor(color: Color(with: 252,	green: 145,	blue: 199),		id: 8),//Pink
			TileColor(color: Color(with: 142,	green: 87,	blue: 51),		id: 12),//Brown
			TileColor(color: Color(with: 255,	green: 153, blue: 51),		id: 7),//Orange
			TileColor(color: Color(with: 255,	green: 255, blue: 0),		id: 9),//Yellow
			TileColor(color: Color(with: 133,	green: 222, blue: 53),		id: 1),//Green
			TileColor(color: Color(with: 24,	green: 181, blue: 4),		id: 6),//Dark green
			TileColor(color: Color(with: 0,		green: 0,	blue: 255),		id: 2),//Blue
			TileColor(color: Color(with: 13,	green: 109,	blue: 187),		id: 13),//almostLight blue
			TileColor(color: Color(with: 26,	green: 203, blue: 213),		id: 5),//Light blue
			TileColor(color: Color(with: 195,	green: 80,	blue: 222),		id: 14),//light purple
			TileColor(color: Color(with: 110,	green: 0,	blue: 108),		id: 15)//purple
		]
		//init the tiles
		
		var initTileDB: Bool = false
		let dbTiles = try? Tile.makeQuery().all()
		if dbTiles?.count == 0 {
			initTileDB = true
		}
		
		if initTileDB {
			print("Running first tile db init!")
			for y in 0..<height {
				for x in 0..<width {
					let tile = Tile()
					tile.pos = Coord(x: x, y: y)
					tile.color = 3
					//Only run once, check the row count
					try? tile.save()
					self.tiles.append(tile)
				}
			}
		} else {
			print("Loading canvas from DB...")
			dbTiles?.forEach { dbTile in
				self.tiles.append(dbTile)
			}
		}
	}
	
}
