//
//  VideoCacheManager.swift
//  GSPlayer
//
//  Created by Gesen on 2019/4/20.
//  Copyright © 2019 Gesen. All rights reserved.
//

import Foundation

private let directory = NSTemporaryDirectory().appendingPathComponent("GSPlayer")

public enum VideoCacheManager {
    
    public static func cachedFilePath(for url: URL) -> String {
        return directory
            .appendingPathComponent(url.absoluteString.md5)
            .appendingPathExtension(url.pathExtension)!
    }
    
    public static func cachedConfiguration(for url: URL) throws -> VideoCacheConfiguration {
        return try VideoCacheConfiguration
            .configuration(for: cachedFilePath(for: url))
    }
    
    public static func calculateCachedSize() -> UInt {
        let fileManager = FileManager.default
        let resourceKeys: Set<URLResourceKey> = [.totalFileAllocatedSizeKey]
        
        let fileContents = (try? fileManager.contentsOfDirectory(at: URL(fileURLWithPath: directory), includingPropertiesForKeys: Array(resourceKeys), options: .skipsHiddenFiles)) ?? []
        
        return fileContents.reduce(0) { size, fileContent in
            guard
                let resourceValues = try? fileContent.resourceValues(forKeys: resourceKeys),
                resourceValues.isDirectory != true,
                let fileSize = resourceValues.totalFileAllocatedSize
                else { return size }
            
            return size + UInt(fileSize)
        }
    }
    
    public static func cleanAllCache(beforeTimestamp timestamp: Int64) throws {
        let fileManager = FileManager.default
        let fileContents = try fileManager.contentsOfDirectory(atPath: directory)
        
        for fileContent in fileContents {
            let filePath = directory.appendingPathComponent(fileContent)
            let fileAttributes = try fileManager.attributesOfItem(atPath: filePath) as [FileAttributeKey:Any]
            let fileCreationDate = fileAttributes[.creationDate] as! Date
            if (Int64(fileCreationDate.timeIntervalSince1970) < timestamp) {
                try fileManager.removeItem(atPath: filePath)
            }
        }
    }
    
    public static func deleteFile(for url: URL) throws {
        let fileManager = FileManager.default
        let filePath = cachedFilePath(for: url)
        if fileManager.fileExists(atPath: filePath) {
            try fileManager.removeItem(atPath: filePath)
            try fileManager.removeItem(atPath: VideoCacheConfiguration.configurationFilePath(for: filePath))
        }
    }
}

@objc public class VideoCacheManagerUtils : NSObject {
    @objc public static func cachedFilePath(for url: URL) -> String {
        return VideoCacheManager.cachedFilePath(for: url);
    }
    
    @objc public static func calculateCachedSize() -> UInt {
        VideoCacheManager.calculateCachedSize();
    }
    
    @objc public static func cleanAllCache(beforeTimestamp timestamp: Int64) throws {
        try VideoCacheManager.cleanAllCache(beforeTimestamp: timestamp);
    }
    
    @objc public static func deleteFile(for url: URL) throws {
        try VideoCacheManager.deleteFile(for: url);
    }
}
