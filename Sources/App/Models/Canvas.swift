//
//  Canvas.swift
//  place
//
//  Created by Valtteri Koskivuori on 18/06/2017.
//
//

import Vapor

class Canvas {
	//Connection is a key-val pair; User:WebSocket
	var connections: [User: WebSocket]
	var tiles: [Tile] = []
	var width: Int = 100
	var height: Int = 100
	
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
			return
		}
		//Send to all connected users
		sendJSON(json: json)
	}
	
	//Send to all users
	func sendJSON(json: JSON) {
		for (_, socket) in connections {
			try? socket.send(json.serialize().makeString())
		}
	}
	
	//Init canvas, load it from the DB here
	init() {
		connections = [:]
		//Add some default colors: red, green, blue, black
		colors = [
			TileColor(color: Color(with: 255, green: 0, blue: 0),		id: 0),//Red
			TileColor(color: Color(with: 0, green: 255, blue: 0),		id: 1),//Green
			TileColor(color: Color(with: 0, green: 0, blue: 255),		id: 2),//Blue
			TileColor(color: Color(with: 255, green: 255, blue: 255),	id: 3),//White
			TileColor(color: Color(with: 0, green: 0, blue: 0),			id: 4)]//Black
		//init the tiles
		for y in 0..<height {
			for x in 0..<width {
				let tile = Tile()
				tile.pos = Coord(x: x, y: y)
				self.tiles.append(tile)
			}
		}
	}
	
}
