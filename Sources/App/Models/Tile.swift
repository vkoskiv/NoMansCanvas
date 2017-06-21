//
//  Tile.swift
//  place
//
//  Created by Valtteri Koskivuori on 18/06/2017.
//
//

import Vapor
import Foundation
import FluentProvider

final class Coord {
	var x: Int = 0
	var y: Int = 0
	
	init() {
		self.x = 0
		self.y = 0
	}
	
	init(x: Int, y: Int) {
		self.x = x
		self.y = y
	}
}

final class Tile: Model {
	var pos = Coord()
	var color: Int //Color ID
	var placeTime = String() //YYYY-mm-dd
	var placer = User()
	
	let storage = Storage()
	
	//New
	init() {
		pos = Coord(x: 0, y: 0)
		color = 3
		placeTime = String()
		placer = User()
	}
	
	//From DB
	required init(row: Row) throws {
		self.pos.x = try row.get("X")
		self.pos.y = try row.get("Y")
		self.color = try row.get("colorID")
		//TODO: get full user with UUID here
		self.placer.uuid = try row.get("lastModifier")
	}
	
	/*func getDateString() -> String {
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "YYYY-mm-dd"
		
	}*/
	
	func makeRow() throws -> Row {
		var row = Row()
		try row.set("X", pos.x)
		try row.set("Y", pos.y)
		try row.set("colorID", color)
		try row.set("lastModifier", placer.uuid)
		return row
	}
}

//Database preparation
extension Tile: Preparation {
	static func prepare(_ database: Database) throws {
		try database.create(self) { tiles in
			tiles.id()
			tiles.int("X")
			tiles.int("Y")
			tiles.int("colorID")
			tiles.string("lastModifier")
		}
	}
	
	static func revert(_ database: Database) throws {
		try database.delete(self)
	}
}
