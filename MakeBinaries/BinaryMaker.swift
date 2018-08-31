//
//  BinaryMaker.swift
//  MakeBinaries
//
//  Created by Shane Whitehead on 31/8/18.
//  Copyright © 2018 KaiZen. All rights reserved.
//

import Foundation

class BinaryMaker {
	
	private static let logPrefix = "***"
	
	private let path: URL
	
	init(path: URL) {
		self.path = path
	}
	
	func make() throws {
		if !Configuration.skipBuildIfExists {
			try preMake()
		}
		try performCarthageBuildAndArchive()
	}
	
	internal func preMake() throws {
		guard !Configuration.skipBuildIfExists else {
			return
		}
		try removeZipFiles()
		try removeCarthageArtifacts()
	}
	
	var containsFrameworkZipFile: Bool {
		do {
			return try frameworkZipFiles().count > 0
		} catch {
		}
		return false
	}
	
	var containsCarthageArtifacts: Bool {
		do {
			return try carthageArtifacts().count > 0
		} catch {
		}
		return false
	}
	
	internal func frameworkZipFiles() throws -> [URL] {
		let matches = try FileManager.default.filterContents(of: path) { (element) -> Bool in
			guard !element.hasDirectoryPath else {
				return false
			}
			guard element.path.lowercased().hasSuffix(".framework.zip") else {
				return false
			}
			return true
		}
		return matches
	}
	
	internal func removeZipFiles() throws {
		try remove(try frameworkZipFiles())
	}
	
	internal func carthageArtifacts() throws -> [URL] {
		let matches = try FileManager.default.filterContents(of: path) { (element) -> Bool in
			guard element.hasDirectoryPath else {
				return false
			}
			guard element.lastPathComponent.lowercased() == "carthage" else {
				return false
			}
			return try self.containsBuild(element)
		}
		return matches
	}
	
	internal func removeCarthageArtifacts() throws {
		try remove(try carthageArtifacts())
	}
	
	internal func containsBuild(_ path: URL) throws -> Bool {
		let matches = try FileManager.default.filterContents(of: path, include: { (element) -> Bool in
			guard element.hasDirectoryPath else {
				return false
			}
			guard element.lastPathComponent.lowercased() == "build" else {
				return false
			}
			return true
		})
		return matches.count > 0
	}
	
	internal func remove(_ elements: [URL]) throws {
		for element in elements {
			log("***".red, "Delete")
			log("\t\(element.path)".white)
			try FileManager.default.removeItem(at: element)
		}
	}
	
	internal func performCarthageBuildAndArchive() throws {
		let timer = Timer()
		timer.isRunning = true
		if Configuration.skipBuildIfExists && !containsFrameworkZipFile && containsCarthageArtifacts {
			archiveFramework()
		} else if Configuration.skipBuildIfExists && !containsFrameworkZipFile {
			buildFramework()
			if containsCarthageArtifacts {
				archiveFramework()
			}
		}
		
		if !containsCarthageArtifacts {
			log("***".red, "Failed to generate Carthage build artifacts!")
		} else if !containsFrameworkZipFile {
			log("***".red, "Failed to generate Carthage framework archive!")
		} else {
			for archive in try frameworkZipFiles() {
				guard !archive.path.contains("Xcode") else {
					continue
				}
				// Current name
				let name = archive.lastPathComponent
				
				// Parent path
				var path = URL(fileURLWithPath: archive.path)
				path.deleteLastPathComponent()
				
				// Split the name apart
				var nameParts = name.split(separator: ".").map({String($0)})
				// Inject the xcode version
				nameParts.insert("Xcode-\(Configuration.xcode.version)-\(Configuration.xcode.build)", at: 1)
				// Put the name back together
				let newName = nameParts.joined(separator: ".")
				// Append it to the parent path
				path.appendPathComponent(newName)
				// Rename the file
				try FileManager.default.moveItem(at: archive, to: path)
			}
		}
		
		timer.isRunning = false
		log("***".blue, "Took \(durationFormatter.string(from: timer.duration)!) to build/archive \(path.lastPathComponent)".white)
	}
	
	func archiveFramework() {
		log("***".blue, "Generate archive \(path.lastPathComponent)".white)
		_ = Executor.execute(currentDirectory: path, arguments: "carthage", "archive") { data in
			guard var line = String(data: data, encoding: String.Encoding.utf8) else {
				log("***".red, "Error decoding data:")
				log("\t\(data)".magenta)
				return
			}
			
			line = line.trimmingCharacters(in: .whitespacesAndNewlines)
			guard line.count > 0 else {
				return
			}
			for part in line.split(separator: "\n") {
				log("[", part.trimmingCharacters(in: .whitespacesAndNewlines).lightBlack, "]")
			}
		}
	}
	
	func buildFramework() {
		log("***".blue, "Build project \(path.lastPathComponent)".white)
		var command: [String] = ["carthage", "build", "--no-skip-current"]
		if Configuration.isDebug {
			command.append("--configuration")
			command.append("Debug")
		}
		_ = Executor.execute(currentDirectory: path, arguments: command) { data in
			guard var line = String(data: data, encoding: String.Encoding.utf8) else {
				log("***".red, "Error decoding data:")
				log("\t\(data)".magenta)
				return
			}
			
			line = line.trimmingCharacters(in: .whitespacesAndNewlines)
			guard line.count > 0 else {
				return
			}
			for part in line.split(separator: "\n") {
				log("[", part.trimmingCharacters(in: .whitespacesAndNewlines).lightBlack, "]")
			}
		}
	}
}
