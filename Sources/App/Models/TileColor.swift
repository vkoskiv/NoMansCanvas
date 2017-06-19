//
//  TileColor
//  place
//
//  Created by Valtteri Koskivuori on 18/06/2017.
//
//

import Vapor

class Color {
	var   red: UInt8
	var green: UInt8
	var  blue: UInt8
	
	init() {
		  self.red = 255
		self.green = 255
		 self.blue = 255
	}
	
	init(with red: UInt8, green: UInt8, blue: UInt8) {
		self.red = red
		self.green = green
		self.blue = blue
	}
}

class TileColor {
	var color: Color
	var ID: Int
	
	init(color: Color, id: Int) {
		self.color = color
		self.ID = id
	}
	
	init() {
		self.color = Color()
		self.ID = 0
	}
}
