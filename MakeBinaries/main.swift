//
//  main.swift
//  MakeBinaries
//
//  Created by Shane Whitehead on 31/8/18.
//  Copyright © 2018 KaiZen. All rights reserved.
//

import Foundation

func xcodeVersion() {
	Executor.execute(arguments: "xcodebuild", "-version") { (data) in
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
			if part.hasPrefix("Xcode") {
				Configuration.xcode.version = part.split(separator: " ")[1].trimmingCharacters(in: .whitespacesAndNewlines)
			} else if part.hasPrefix("Build") {
				Configuration.xcode.build = part.split(separator: " ")[2].trimmingCharacters(in: .whitespacesAndNewlines)
			}
		}
	}
}

func makeItSo() {
	
	//let currentPath = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
	for command in CommandLine.arguments {
		if command.lowercased() == "--current" {
			Configuration.isCurrentOnly = true
		} else if command.lowercased() == "--debug" {
			Configuration.isDebug = true
		} else if command.lowercased() == "--skip" {
			Configuration.skipBuildIfExists = true
		} else if command.lowercased() == "help" || command == "?" {
			Configuration.help = true
		}
	}
	
	if Configuration.help {
		log("MakeBinaries")
		log("\tby default, search the current directory and build all the subdirectories")
		log("\t--current - Build the current directory")
		log("\t  --debug - Build with debug flag set")
		log("\t   --skip - Skip building projects which already have generated output")
	} else if Configuration.isCurrentOnly {
		xcodeVersion()
		
		guard Configuration.xcode.version != "" && Configuration.xcode.build != "" else {
			log("***".red, "Could not determine Xcode version")
			return
		}
		
		log("***".blue, "Xcode", Configuration.xcode.version.white, Configuration.xcode.build.lightBlack)
		do {
			let pathURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
			log("***".lightBlue, "Make binaries for", "\(pathURL.lastPathComponent)".white)
			let maker = BinaryMaker(path: pathURL)
			try maker.make()
		} catch let error {
			print("\(error).red")
		}
	} else {
		let fileManager = FileManager.default
		let path = fileManager.currentDirectoryPath
		let pathURL = URL(fileURLWithPath: path, isDirectory: true)
		do {
			let directories = try fileManager.filterContents(of: pathURL, include: { $0.hasDirectoryPath} )
			let timer = Timer()
			timer.isRunning = true
			for dir in directories {
				log("***".lightBlue, "Make binaries for", "\(dir.lastPathComponent)".white)
				let maker = BinaryMaker(path: dir)
				do {
					try maker.make()
				} catch let error {
					log("***".red, "\(error)")
				}
			}
			timer.isRunning = false
			print()
			log("***".blue, "Took \(durationFormatter.string(from: timer.duration)!) to complete")
			
		} catch let error {
			log("***".red, "\(error)")
		}
	}
	
}

makeItSo()
