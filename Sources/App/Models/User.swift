//
//  User.swift
//  place
//
//  Created by Valtteri Koskivuori on 18/06/2017.
//
//

import Vapor

class User: Hashable {
	//funcs for UUID gen, username store, getUser from DB, etc
	var username: String? = nil //Username is optional
	var uuid: String			//uuid is mandatory
	var ip: String
	var socket: WebSocket!
	
	var availableColors: [TileColor]
	var remainingTiles: Int
	var lastConnected: Date //Used to keep track of accumulated tiles while disconnected
	
	var hashValue: Int {
		return self.uuid.hashValue
	}
	
	//New user
	init() {
		//TODO: Check from DB to make sure this UUID doesn't exist already.
		self.uuid = User.randomUUID(length: 20)
		self.availableColors = []
		self.remainingTiles = 50
		self.lastConnected = Date()
		self.ip = ""
	}
	
	//Existing user
	init(uuid: String) {
		//Get other params from DB
		self.uuid = uuid
		self.availableColors = []
		self.remainingTiles = 0
		self.lastConnected = Date() //Unused for now
		self.ip = ""
	}
	
	func sendJSON(json: JSON) {
		try? self.socket.send(json.serialize().makeString())
	}
	
	class func randomUUID(length: Int) -> String {
		let charset: String = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
		var randString: String = ""
		for _ in 0..<length {
			#if os(Linux)
			randString.append(charset[charset.index(charset.startIndex, offsetBy: Int(random() % Int(charset.characters.count)))])
			#else
			randString.append(charset[charset.index(charset.startIndex, offsetBy: Int(arc4random_uniform(UInt32(charset.characters.count))))])
			#endif
		}
		return randString
	}
}

func ==(lhs: User, rhs: User) -> Bool {
	return lhs.uuid.hashValue == rhs.uuid.hashValue
}
