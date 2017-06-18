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
}

class Tile {
	var pos: Coord
	var color: TileColor
	var placeTime: Date
	var placer: User
	
	init() {
		pos = Coord()
		color = TileColor()
		placeTime = Date()
		placer = User()
	}
}
