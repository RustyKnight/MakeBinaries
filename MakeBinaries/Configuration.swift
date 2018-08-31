//
//  Configuration.swift
//  MakeBinaries
//
//  Created by Shane Whitehead on 31/8/18.
//  Copyright © 2018 KaiZen. All rights reserved.
//

import Foundation

class Configuration {
	static var isCurrentOnly = false
	static var isDebug = false
	static var skipBuildIfExists = false
	static var help = false
	
	static var xcode: Xcode = Xcode()
}

class Xcode {
	var version: String = ""
	var build: String = ""
}
