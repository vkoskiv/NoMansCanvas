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
	var ip: String
	
	var availableColors: [TileColor]
	var remainingTiles: Int
	var lastConnected: Date //Used to keep track of accumulated tiles while disconnected
	
	//New user
	init(ip: String) {
		//TODO: Check from DB to make sure this UUID doesn't exist already.
		self.uuid = randomUUID(length: 20)
		self.availableColors = []
		self.remainingTiles = 50
		self.lastConnected = Date()
		self.ip = ip
	}
	
	//Existing user
	init(uuid: String, ip: String) {
		//Get other params from DB
		self.uuid = uuid
		self.availableColors = []
		self.remainingTiles = 0
		self.lastConnected = Date() //Unused for now
		self.ip = ip
	}
	
	func randomUUID(length: Int) -> String {
		let charset: String = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
		var randString: String = ""
		for _ in 0..<length {
			randString.append(charset[charset.index(charset.startIndex, offsetBy: Int(arc4random_uniform(UInt32(charset.characters.count))))])
		}
		return randString
	}
}
