//
//  User.swift
//  place
//
//  Created by Valtteri Koskivuori on 18/06/2017.
//
//

import Vapor

class User {
	//funcs for UUID gen, username store, getUser from DB, etc
	var username: String? = nil //Username is optional
	var uuid: String			//uuid is mandatory
	
	var availableColors: [TileColor]
	var remainingTiles: Int
	var lastConnected: Date //Used to keep track of accumulated tiles while disconnected
	
	init() {
		//TODO: UUID generation
		uuid = "Generate this randomly"
		
		availableColors = []
		remainingTiles = 50
		lastConnected = Date()
	}
}
