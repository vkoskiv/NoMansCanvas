//
//  User.swift
//  place
//
//  Created by Valtteri Koskivuori on 18/06/2017.
//
//

import Vapor
import FluentProvider

final class User: Hashable, Model {
	//funcs for UUID gen, username store, getUser from DB, etc
	var username: String? = nil //Username is optional
	var uuid: String			//uuid is mandatory
	var ip: String
	var socket: WebSocket? = nil

	let storage = Storage()

	var availableColors: [Int] //ColorID array
	var remainingTiles: Int
	var tileRegenSeconds: Int
	var totalTilesPlaced: Int
	var lastConnected: Int64 //Used to keep track of accumulated tiles while disconnected, unix epoch

	required init(row: Row) throws {
		self.username = try row.get("username")
		self.uuid = try row.get("uuid")
		self.ip = try row.get("latestIP")
		self.remainingTiles = try row.get("remainingTiles")
		self.tileRegenSeconds = try row.get("tileRegenSeconds")
		self.totalTilesPlaced = try row.get("totalTilesPlaced")
		self.lastConnected = try row.get("lastConnected")
		self.availableColors = User.makeColorListFromString(colors: try row.get("availableColors"))
	}

	//DB requirements
	func makeRow() throws -> Row {
		var row = Row()
		try row.set("username", username)
		try row.set("uuid", uuid)
		try row.set("latestIP", ip)
		try row.set("remainingTiles", remainingTiles)
		try row.set("tileRegenSeconds", tileRegenSeconds)
		try row.set("totalTilesPlaced", totalTilesPlaced)
		try row.set("lastConnected", lastConnected)
		try row.set("availableColors", User.getColorListString(colors: availableColors))
		return row
	}

	class func makeColorListFromString(colors: String) -> [Int] {
		return colors.components(separatedBy: ",").flatMap { Int($0.trimmingCharacters(in: .whitespaces)) }
	}

	class func getColorListString(colors: [Int]) -> String {
		return colors.map({"\($0)"}).joined(separator: ",")
	}

	var hashValue: Int {
		return self.uuid.hashValue
	}

	//New user
	init() {
		//TODO: Check from DB to make sure this UUID doesn't exist already.
		self.uuid = User.randomUUID(length: 20)
		self.availableColors = []
		self.remainingTiles = 60
		self.tileRegenSeconds = 60
		self.totalTilesPlaced = 0
		self.lastConnected = 0
		self.ip = ""
	}

	func sendJSON(json: JSON) {
		//TODO: Change serialize() to makeBytes() to save bandwidth
		try? self.socket?.send(json.serialize().makeString())
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

//Database preparation
extension User: Preparation {
	static func prepare(_ database: Database) throws {
		try database.create(self) { users in
			users.id()
			users.string("username")
			users.string("uuid")
			users.string("latestIP")
			users.int("remainingTiles")
			users.int("tileRegenSeconds")
			users.int("totalTilesPlaced")
			users.bigInteger("lastConnected")
			users.string("availableColors")
		}
	}

	static func revert(_ database: Database) throws {
		try database.delete(self)
	}
}
