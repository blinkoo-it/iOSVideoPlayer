//
//  VideoPreloadManager.swift
//  GSPlayer
//
//  Created by Gesen on 2019/4/20.
//  Copyright © 2019 Gesen. All rights reserved.
//

import Foundation

@objcMembers public class VideoPreloadManager: NSObject {
    
    public static let shared = VideoPreloadManager()
    
    public var preloadByteCount: Int = 1024 * 1024 // = 1M
    
    public var didStart: (() -> Void)?
    public var didPause: (() -> Void)?
    public var didFinish: ((Error?) -> Void)?
    
    private var downloader: VideoDownloader?
    private var isAutoStart: Bool = true
    private var waitingQueue: [URL] = []
    
    @objc public func add(url: URL) {
        if waitingQueue.isEmpty {
            set(waiting: [url])
            return
        }
        waitingQueue.append(url)
        if isAutoStart { start() }
    }
    
    @objc public func set(waiting: [URL]) {
        downloader = nil
        waitingQueue = waiting
        if isAutoStart { start() }
    }
    
    func start() {
        guard downloader == nil, waitingQueue.count > 0 else {
            downloader?.resume()
            return
        }
        
        isAutoStart = true
        
        let url = waitingQueue.removeFirst()
        
        
        
        guard
            !VideoLoadManager.shared.loaderMap.keys.contains(url),
            let cacheHandler = try? VideoCacheHandler(url: url) else {
            return
        }
        
        downloader = VideoDownloader(url: url, cacheHandler: cacheHandler)
        downloader?.delegate = self
        downloader?.download(from: 0, length: preloadByteCount)
        
        if cacheHandler.configuration.downloadedByteCount < preloadByteCount {
            didStart?()
        }
    }
    
    func pause() {
        downloader?.suspend()
        didPause?()
        isAutoStart = false
    }
    
    func remove(url: URL) {
        if let index = waitingQueue.firstIndex(of: url) {
            waitingQueue.remove(at: index)
        }
        
        if downloader?.url == url {
            downloader = nil
        }
    }
    
}

extension VideoPreloadManager: VideoDownloaderDelegate {
    
    public func downloader(_ downloader: VideoDownloader, didReceive response: URLResponse) {
        
    }
    
    public func downloader(_ downloader: VideoDownloader, didReceive data: Data) {
        
    }
    
    public func downloader(_ downloader: VideoDownloader, didFinished error: Error?) {
        self.downloader = nil
        start()
        didFinish?(error)
    }
    
}
