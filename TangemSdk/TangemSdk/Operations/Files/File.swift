//
//  File.swift
//  TangemSdk
//
//  Created by Andrew Son on 10/6/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

@available (iOS 13, *)
public struct File: JSONStringConvertible {
    public let data: Data
    public let index: Int
    public let settings: FileSettings
}

@available (iOS 13, *)
extension File {
    init?(response: ReadFileResponse) {
        guard response.size != nil, let settings = response.settings else {
            return nil //empty read file response. No files on the card
        }
        
        self.data = response.fileData
        self.index = response.fileIndex
        self.settings = settings
    }
}

@available(iOS 13.0, *)
public struct NamedFile {
    public let name: String
    public let payload: Data
    public let counter: Int?
    public let signature: Data?
    
    public init(name: String, payload: Data, counter: Int? = nil, signature: Data? = nil) {
        self.name = name
        self.payload = payload
        self.counter = counter
        self.signature = signature
    }
    
    public init? (tlvData: Data) throws {
        guard let tlv = Tlv.deserialize(tlvData) else {
           return nil
        }
        
        let decoder = TlvDecoder(tlv: tlv)
        
        name = try decoder.decode(.fileTypeName)
        payload = try decoder.decode(.fileData)
        counter = try decoder.decode(.fileCounter)
        signature = try decoder.decode(.fileSignature)
    }
    
    public func serialize() throws -> Data {
        let tlvBuilder = try TlvBuilder()
            .append(.fileTypeName, value: name)
            .append(.fileData, value: payload)
            
        if let counter = self.counter {
            try tlvBuilder.append(.fileCounter, value: counter)
        }
        
        if let signature = self.signature {
            try tlvBuilder.append(.fileSignature, value: signature)
        }
        
        return tlvBuilder.serialize()
    }
}

/// File data to write by the user or file  owner.
@available (iOS 13.0, *)
public enum FileToWrite: Decodable {
    /// Write file protected by the user with security delay or user code if set
    ///   - data: Data to write
    ///   - fileVisibility: Optional visibility setting for the file. COS 4.0+
    ///   - walletPublicKey: Optional link to the card's wallet. COS 4.0+
    case byUser(data: Data, fileVisibility: FileVisibility?, walletPublicKey: Data?)
    /// Write file protected by the file owner with two signatures and counter
    ///   - data: Data to write
    ///   - startingSignature: Starting signature of the file data. You can use `FileHashHelper` to generate signatures or use it as a reference to create the signature yourself
    ///   - finalizingSignature: Finalizing signature of the file data. You can use `FileHashHelper` to generate signatures or use it as a reference to create the signature yourself
    ///   - counter: File counter to prevent replay attack
    ///   - fileVisibility: Optional visibility setting for the file. COS 4.0+
    ///   - walletPublicKey: Optional link to the card's wallet. COS 4.0+
    case byFileOwner(data: Data, startingSignature: Data, finalizingSignature: Data, counter: Int,
                     fileVisibility: FileVisibility?, walletPublicKey: Data?)
    
    public init(from decoder: Decoder) throws {
        do {
            let file = try OwnerFile(from: decoder)
            self = .byFileOwner(data: file.data,
                                startingSignature: file.startingSignature,
                                finalizingSignature: file.finalizingSignature,
                                counter: file.counter,
                                fileVisibility: file.fileVisibility,
                                walletPublicKey: file.walletPublicKey)
        } catch {
            let file = try UserFile(from: decoder)
            self = .byUser(data: file.data,
                           fileVisibility: file.fileVisibility,
                           walletPublicKey: file.walletPublicKey)
        }
    }
    
    private struct UserFile: Decodable {
        let data: Data
        let fileVisibility: FileVisibility?
        let walletPublicKey: Data?
    }
    
    private struct OwnerFile: Decodable {
        let data: Data
        let startingSignature: Data
        let finalizingSignature: Data
        let counter: Int
        let fileVisibility: FileVisibility?
        let walletPublicKey: Data?
    }
}
