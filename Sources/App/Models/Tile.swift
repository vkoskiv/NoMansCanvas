//
//  Tile.swift
//  place
//
//  Created by Valtteri Koskivuori on 18/06/2017.
//
//

import Vapor

class Coord {
	var x: Int = 0
	var y: Int = 0
	
	init(x: Int, y: Int) {
		self.x = x
		self.y = y
	}
}

class Tile {
	var pos: Coord
	var color: TileColor
	var placeTime: Date
	var placer: User
	
	init() {
		pos = Coord(x: 0, y: 0)
		color = TileColor()
		placeTime = Date()
		placer = User(uuid: "")
	}
}
