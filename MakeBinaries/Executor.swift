//
//  Executor.swift
//  MakeBinaries
//
//  Created by Shane Whitehead on 31/8/18.
//  Copyright © 2018 KaiZen. All rights reserved.
//

import Foundation

typealias ExecutorConsumer = (Data) -> Void

class Executor {
	static func execute(currentDirectory: URL? = nil,
											arguments args: [String],
		consumer: ExecutorConsumer? = nil) {
		let task = Process()
		task.launchPath = "/usr/bin/env"
		task.arguments = args
		if let currentDirectory = currentDirectory {
			task.currentDirectoryURL = currentDirectory
		}
		
		let pipe = Pipe()
		task.standardOutput = pipe
		task.standardError = pipe
		
		let handle = pipe.fileHandleForReading
		if let consumer = consumer {
			handle.readabilityHandler = { pipe in
				consumer(pipe.availableData)
			}
		}
		
		task.launch()
		
		if consumer == nil {
			// Consume it to be safe
			_ = pipe.fileHandleForReading.readDataToEndOfFile()
		}
		task.waitUntilExit()
	}
	static func execute(currentDirectory: URL? = nil,
											arguments args: String...,
											consumer: ExecutorConsumer? = nil) {
		Executor.execute(currentDirectory: currentDirectory, arguments: args.map({$0}), consumer: consumer)
		
	}
}
