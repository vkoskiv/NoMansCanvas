//
//  Canvas.swift
//  place
//
//  Created by Valtteri Koskivuori on 18/06/2017.
//
//

import Vapor

class Canvas {
	//Connection is a key-val pair; userID:WebSocket
	//Consider making User hashable somehow? And have User:WebSocket keyval pairs
	var connections: [String: WebSocket]
	var tiles: [Tile] = []
	var width: Int = 100
	var height: Int = 100
	
	func updateTileToClients() {
		//We've received a tile change, it's been approved, send that update to ALL connected clients
	}
	
	//FIXME: Consider user.sendJSON(somejson)
	//Send to a specific user
	func sendJSON(to: User, json: JSON) {
		for (uuid, socket) in connections {
			guard uuid == to.uuid else{
				continue
			}
			try? socket.send(json.serialize().makeString())
		}
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
		for y in 0..<height {
			for x in 0..<width {
				let tile = Tile()
				tile.pos = Coord(x: x, y: y)
				self.tiles.append(tile)
			}
		}
	}
	
}
