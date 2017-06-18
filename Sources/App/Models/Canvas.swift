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
	
	func updateTileToClients() {
		//We've received a tile change, it's been approved, send that update to ALL connected clients
	}
	
	//Init canvas, load it from the DB here
	init() {
		connections = [:]
	}
	
}
