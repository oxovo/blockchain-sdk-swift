//
//  TONCell.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 18.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import CryptoSwift
import Foundation

let reachBocMagicPrefix = Data(hex: "b5ee9c72").bytes
let leanBocMagicPrefix = Data(hex: "68ff65f3").bytes
let leanBocMagicPrefixCRC = Data(hex: "acc3a728").bytes

public final class TONCell {
    
    // MARK: - Properties
    
    var raw: TonCellRaw
    var refs: Array<TONCell>
    var isExotic: Bool
    
    // MARK: - Init
    
    init(raw: TonCellRaw = .init(), refs: Array<TONCell> = [], isExotic: Bool = false) {
        self.raw = raw
        self.refs = refs
        self.isExotic = isExotic
    }
    
    // MARK: - Static
    
    static func oneFromBoc(_ serializedBoc: Array<UInt8>) throws -> TONCell {
        let cells = try deserializeBoc(serializedBoc)
        
        guard !cells.isEmpty else {
            throw NSError()
        }
        
        return cells[0]
    }
    
    /**
     * @param serializedBoc  {string | Uint8Array} hex or bytearray
     * @return {Cell[]} root cells
     */
    static func deserializeBoc(_ serializedBoc: Array<UInt8>) throws -> [TONCell] {
        let header = try parseBocHeader(serializedBoc: serializedBoc)
        var cells_data = header.cells_data
        var cells_array: Array<TONCell> = []
        
        for _ in 0..<header.cells_num {
            let dd = try deserializeCellData(cells_data, header.size_bytes);
            cells_data = dd.1;
            cells_array.append(dd.0);
        }
        
        for ci in stride(from: header.cells_num - 1, to: -1, by: -1) {
            let c = cells_array[ci]
            for ri in 0..<c.refs.count {
                if let r = c.refs[ri].raw.bytes.first {
                    if r < ci {
                        throw NSError()
                    }
                
                    let refValue = cells_array[Int(r)]
                    c.refs[ri] = refValue
                }
            }
        }
        
        var root_cells: Array<TONCell> = []
        
        for ri in header.root_list {
            root_cells.append(cells_array[ri])
        }
        
        return root_cells
    }
    
    static func deserializeCellData(_ cellData: Array<UInt8>, _ referenceIndexSize: Int) throws -> (TONCell, Array<UInt8>) {
        if cellData.count < 2 {
            throw NSError()
        }
        
        var cellData = cellData
        
        let d1 = cellData[0]
        let d2 = cellData[1]
        cellData = Array(cellData[2..<cellData.count])
        
        let isExotic = d1 & 8
        let refNum = d1 % 8
        let dataBytesize = Int(ceilf(Float(d2) / 2))
        let fullfilledBytes = ((d2 % 2) == 0);
        
        let cell = TONCell(raw: .init())
        cell.isExotic = isExotic != 0
        
        let compareValue = dataBytesize + referenceIndexSize * Int(refNum)
        
        if cellData.count < compareValue {
            throw NSError()
        }
        
        try cell.raw.setTopUppedArray(Array(cellData[0..<dataBytesize]), fullfilledBytes: fullfilledBytes)
        cellData = Array(cellData[dataBytesize..<cellData.count])
        
        for _ in 0..<refNum {
            cell.refs.append(
                .init(
                    raw: .init([UInt8(readNBytesUIntFromArray(referenceIndexSize, cellData))])
                )
            )
            cellData = Array(cellData[referenceIndexSize..<cellData.count])
        }
        
        return (cell, cellData)
    }
    
}

extension TONCell {
    
    static func parseBocHeader(serializedBoc: Array<UInt8>) throws -> TONCellBocHeader {
        var serializedBoc = serializedBoc
        let inputData = serializedBoc // Save copy for crc32
        let prefix = Array(serializedBoc[0...3])
        
        serializedBoc = Array(serializedBoc[4..<serializedBoc.count])
        
        var has_idx: UInt8 = 0
        var hash_crc32: UInt8 = 0
        var has_cache_bits: UInt8 = 0
        var flags: UInt8 = 0
        var size_bytes: Int = 0
        
        if compareBytes(prefix, reachBocMagicPrefix) {
            let flags_byte = serializedBoc[0]
            has_idx = flags_byte & 128
            hash_crc32 = flags_byte & 64
            has_cache_bits = flags_byte & 32
            flags = (flags_byte & 16) * 2 + (flags_byte & 8)
            size_bytes = Int(flags_byte % 8)
        }
        
        if (compareBytes(Array(prefix), leanBocMagicPrefix)) {
            has_idx = 1
            hash_crc32 = 0
            has_cache_bits = 0
            flags = 0
            size_bytes = Int(serializedBoc[0])
        }
        
        if (compareBytes(Array(prefix), leanBocMagicPrefixCRC)) {
            has_idx = 1
            hash_crc32 = 1
            has_cache_bits = 0
            flags = 0
            size_bytes = Int(serializedBoc[0])
        }
        
        serializedBoc = Array(serializedBoc[1..<serializedBoc.count])
        
        if serializedBoc.count < (1 + 5 * size_bytes) {
            throw NSError()
        }
        
        let offset_bytes = Int(serializedBoc[0])
        serializedBoc = Array(serializedBoc[size_bytes..<serializedBoc.count])
        let cells_num = readNBytesUIntFromArray(size_bytes, serializedBoc);
        serializedBoc = Array(serializedBoc[size_bytes..<serializedBoc.count])
        let roots_num = readNBytesUIntFromArray(size_bytes, serializedBoc);
        serializedBoc = Array(serializedBoc[size_bytes..<serializedBoc.count])
        let absent_num = readNBytesUIntFromArray(size_bytes, serializedBoc);
        serializedBoc = Array(serializedBoc[size_bytes..<serializedBoc.count])
        let tot_cells_size = readNBytesUIntFromArray(offset_bytes, serializedBoc)
        serializedBoc = Array(serializedBoc[offset_bytes..<serializedBoc.count])
        
        if serializedBoc.count < roots_num * size_bytes {
            throw NSError()
        }
        
        var root_list: [Int] = []
        
        for _ in 0..<roots_num {
            root_list.append(readNBytesUIntFromArray(size_bytes, serializedBoc))
            serializedBoc = Array(serializedBoc[size_bytes..<serializedBoc.count])
        }
        
        let index = false
        
        if has_idx != 0 {
            if serializedBoc.count < offset_bytes * cells_num {
                throw NSError()
            }
            
            var index: [Int] = []
            
            for _ in 0..<cells_num {
                index.append(readNBytesUIntFromArray(offset_bytes, serializedBoc))
                serializedBoc = Array(serializedBoc[offset_bytes..<serializedBoc.count])
            }
        }
        
        if serializedBoc.count < tot_cells_size {
            throw NSError()
        }
        
        let cells_data = Array(serializedBoc[0..<tot_cells_size])
        serializedBoc = Array(serializedBoc[tot_cells_size..<serializedBoc.count])
        
        if hash_crc32 != 0 {
            if serializedBoc.count < 4 {
                throw NSError()
            }
            
            let crc32 = Checksum.crc32c(Array(inputData[0..<inputData.count - 4]))
            let byteCrcUInt8 = Array(withUnsafeBytes(of: crc32.bigEndian) { Array($0) }.reversed())
            
            if (!compareBytes(byteCrcUInt8, Array(serializedBoc[0..<4]))) {
                throw NSError()
            }
            
            serializedBoc = Array(serializedBoc[4..<serializedBoc.count])
            
        }
        
        if serializedBoc.count > 0 {
            throw NSError()
        }
        
        return TONCellBocHeader(
            has_idx: has_idx,
            hash_crc32: hash_crc32,
            has_cache_bits: has_cache_bits,
            flags: flags,
            size_bytes: size_bytes,
            off_bytes: offset_bytes,
            cells_num: cells_num,
            roots_num: roots_num,
            absent_num: absent_num,
            tot_cells_size: tot_cells_size,
            root_list: root_list,
            index: index,
            cells_data: cells_data
        )
        
        
    }
    
    private static func compareBytes(_ a: Array<UInt8>, _ b: Array<UInt8>) -> Bool {
        return a.toHexString() == b.toHexString()
    }
    
    private static func readNBytesUIntFromArray(_ n: Int, _ ui8array: Array<UInt8>) -> Int {
        var res = 0
        for c in 0..<n {
            res *= 256
            res += Int(ui8array[c])
        }
        return res
    }
    
}

extension TONCell {
    
    func hash() throws -> Array<UInt8> {
        return try getRepr().sha256()
    }
    
    /**
     * @return {Promise<Uint8Array>}
     */
    func getRepr() throws -> Array<UInt8> {
        var reprArray = [[UInt8]]()
        
        try reprArray.append(getDataWithDescriptors())
        
        for ref in refs {
            try reprArray.append(ref.getMaxDepthAsArray())
        }
        
        for ref in refs {
            let hashValue = try ref.hash()
            reprArray.append(hashValue)
        }
        
        var x = Array<UInt8>()
        
        for k in reprArray {
            x = concatBytes(x, k)
        }
        
        return x
    }
    
    /**
     * @private
     * @return {Uint8Array}
     */
    func getMaxDepthAsArray() throws -> Array<UInt8> {
        let maxDepth = getMaxDepth()
        var d = [UInt8](repeating: 0, count: 2)
        d[1] = UInt8(maxDepth % 256)
        d[0] = UInt8(floor(Double(maxDepth / 256)))
        return d
    }
    
    /**
     * @return {Uint8Array}
     */
    func getDataWithDescriptors() throws -> Array<UInt8> {
        let d1 = try getRefsDescriptor()
        let d2 = try getBitsDescriptor()
        let tuBits = try raw.getTopUppedArray()
        let result = concatBytes(concatBytes(d1, d2), tuBits)
        return result
    }
    
    func getRefsDescriptor() throws -> Array<UInt8> {
        var d1 = [UInt8](repeating: 0, count: 1)
        let value = UInt8(refs.count + ((isExotic ? 1 : 0) * 8) + getMaxLevel() * 32)
        d1[0] = value
        return d1
    }
    
    /**
     * @return {Uint8Array}
     */
    func getBitsDescriptor() throws -> Array<UInt8> {
        var d2 = [UInt8](repeating: 0, count: 1)
        let lround = ceilf(Float(raw.cursor) / 8)
        let floor = floor(Float(raw.cursor / 8))
        d2[0] = UInt8(lround) + UInt8(floor)
        return d2
    }
    
    /**
     * @return {number}
     */
    func getMaxLevel() -> Int {
        var maxLevel = 0
        
        for r in refs {
            if r.getMaxLevel() > maxLevel {
                maxLevel = r.getMaxLevel()
            }
        }
        
        return maxLevel
    }
    
    func getMaxDepth() -> Int {
        var maxDepth = 0
        
        if refs.count > 0 {
            for ref in refs {
                if (ref.getMaxDepth() > maxDepth) {
                    maxDepth = ref.getMaxDepth()
                }
            }
            
            maxDepth = maxDepth + 1
        }
        
        return maxDepth
    }
    
}