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
	var username: String? = nil //Username is optional
	var uuid: String			//uuid is mandatory
	var socket: WebSocket? = nil
	var isAuthed: Bool = false
	var hasSetUsername: Bool
	var isShadowBanned: Bool

	let storage = Storage()

	var availableColors: [Int] //ColorID array
	var remainingTiles: Int
	var maxTiles: Int
	var tileRegenSeconds: Int
	var totalTilesPlaced: Int
	var level: Int
	var lastConnected: Int64 //Used to keep track of accumulated tiles while disconnected, unix epoch

	required init(row: Row) throws {
		self.username = try row.get("username")
		self.uuid = try row.get("uuid")
		self.remainingTiles = try row.get("remainingTiles")
		self.maxTiles = try row.get("maxTiles")
		self.tileRegenSeconds = try row.get("tileRegenSeconds")
		self.totalTilesPlaced = try row.get("totalTilesPlaced")
		self.lastConnected = try row.get("lastConnected")
		self.hasSetUsername = try row.get("hasSetUsername")
		self.isShadowBanned = try row.get("isShadowBanned")
		self.level = try row.get("level")
		self.availableColors = User.makeColorListFromString(colors: try row.get("availableColors"))
		self.isAuthed = false
	}

	//DB requirements
	func makeRow() throws -> Row {
		var row = Row()
		try row.set("username", username)
		try row.set("uuid", uuid)
		try row.set("remainingTiles", remainingTiles)
		try row.set("maxTiles", maxTiles)
		try row.set("tileRegenSeconds", tileRegenSeconds)
		try row.set("totalTilesPlaced", totalTilesPlaced)
		try row.set("lastConnected", lastConnected)
		try row.set("hasSetUsername", hasSetUsername)
		try row.set("isShadowBanned", isShadowBanned)
		try row.set("level", level)
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
		self.uuid = ""//User.randomUUID(length: 20)
		self.availableColors = []
		self.remainingTiles = 0
		self.maxTiles = 60
		self.tileRegenSeconds = 30
		self.totalTilesPlaced = 0
		self.level = 0
		self.lastConnected = 0
		self.isAuthed = false
		self.hasSetUsername = false
		self.isShadowBanned = false
	}

	func sendJSON(json: JSON) {
		do {
			try self.socket?.send(json.serialize().makeString())
		} catch {
			try? self.socket?.close()
			canvas.connections.removeValue(forKey: self)
		}
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

//Modify to remove latestIP and add two new fields
struct UserModify: Preparation {
	static func prepare(_ database: Database) throws {
		try database.modify(User.self) { users in
			users.delete("latestIP")
			users.int("level")
			users.bool("hasSetUsername")
		}
	}
	static func revert(_ database: Database) throws {}
}
//Add isShadowBanned field
struct UserModify2: Preparation {
	static func prepare(_ database: Database) throws {
		try database.modify(User.self) { users in
			users.bool("isShadowBanned")
		}
	}
	static func revert(_ database: Database) throws {}
}
//Add maxTiles field
struct WhyDoIKeepForgettingThese: Preparation {
	static func prepare(_ database: Database) throws {
		try database.modify(User.self) { users in
			users.int("maxTiles")
		}
	}
	static func revert(_ database: Database) throws {}
}
