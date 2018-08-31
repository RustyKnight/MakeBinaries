//
//  FileManager+ListFiles.swift
//  MakeBinaries
//
//  Created by Shane Whitehead on 31/8/18.
//  Copyright © 2018 KaiZen. All rights reserved.
//

import Foundation

extension FileManager {
	func filterContents(of path: URL, include: (URL) throws -> Bool) throws -> [URL] {
		let results = try contentsOfDirectory(at: path,
																					includingPropertiesForKeys: [],
																					options: [])
		
		return try results.filter(include)
	}
	
	func exists(directory: URL) -> Bool {
		var isDirectory = ObjCBool(true)
		let exists = FileManager.default.fileExists(atPath: directory.path, isDirectory: &isDirectory)
		return exists && isDirectory.boolValue
	}
}
