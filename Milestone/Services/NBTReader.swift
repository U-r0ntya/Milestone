import Foundation

// NBT の値（12種類）
// indirect：自分の中に自分（リストや入れ子）を持てるようにするための印
indirect enum NBTValue {
    case byte(Int8)
    case short(Int16)
    case int(Int32)
    case long(Int64)
    case float(Float)
    case double(Double)
    case byteArray([Int8])
    case string(String)
    case list([NBTValue])
    case compound([String: NBTValue])
    case intArray([Int32])
    case longArray([Int64])

    // 整数ならどの大きさでも Int64 で取り出す（そうでなければ nil）
    var intValue: Int64? {
        switch self {
        case .byte(let value): return Int64(value)
        case .short(let value): return Int64(value)
        case .int(let value): return Int64(value)
        case .long(let value): return value
        default: return nil
        }
    }

    // 文字なら取り出す
    var stringValue: String? {
        if case .string(let value) = self {
            return value
        }
        return nil
    }

    // リストなら取り出す
    var listValue: [NBTValue]? {
        if case .list(let value) = self {
            return value
        }
        return nil
    }
}

enum NBTError: Error {
    case unexpectedEnd          // 途中でデータが終わった
    case unknownTag(UInt8)      // 知らない種類の番号が出てきた
    case invalidString          // 文字に変換できなかった
    case notCompound            // 一番外側がまとまり（compound）ではなかった
}

// 統合版（リトルエンディアン）の NBT を読む係
struct NBTReader {
    private let bytes: [UInt8]
    private var position = 0     // 今どこまで読んだか

    init(bytes: [UInt8]) {
        self.bytes = bytes
    }

    // level.dat を読む：先頭の8バイト（形式の番号と長さ）を飛ばして、残りを NBT として読む
    static func readLevelDat(_ data: Data) throws -> [String: NBTValue] {
        let all = [UInt8](data)
        guard all.count > 8 else {
            throw NBTError.unexpectedEnd
        }
        var reader = NBTReader(bytes: Array(all[8...]))
        return try reader.readRoot()
    }

    // 一番外側のまとまり（compound）を読む
    mutating func readRoot() throws -> [String: NBTValue] {
        let tag = try readByte()
        _ = try readString()     // 一番外側の名前（ふつうは空）は使わない
        guard case .compound(let root) = try readPayload(tag: tag) else {
            throw NBTError.notCompound
        }
        return root
    }

    // MARK: - 中身の読み方

    // 種類の番号に合わせて、値を1つ読む
    private mutating func readPayload(tag: UInt8) throws -> NBTValue {
        switch tag {
        case 1:
            return .byte(Int8(bitPattern: try readByte()))
        case 2:
            return .short(Int16(truncatingIfNeeded: try readUnsigned(byteCount: 2)))
        case 3:
            return .int(Int32(truncatingIfNeeded: try readUnsigned(byteCount: 4)))
        case 4:
            return .long(Int64(bitPattern: try readUnsigned(byteCount: 8)))
        case 5:
            return .float(Float(bitPattern: UInt32(truncatingIfNeeded: try readUnsigned(byteCount: 4))))
        case 6:
            return .double(Double(bitPattern: try readUnsigned(byteCount: 8)))
        case 7:
            let count = try readCount()
            return .byteArray(try readBytes(count).map { Int8(bitPattern: $0) })
        case 8:
            return .string(try readString())
        case 9:
            // リスト：中身の種類 → 個数 → 値をその数だけ
            let elementTag = try readByte()
            let count = try readCount()
            var list: [NBTValue] = []
            for _ in 0..<count {
                list.append(try readPayload(tag: elementTag))
            }
            return .list(list)
        case 10:
            // まとまり：「種類 → 名前 → 値」を、種類が 0（終わりの印）になるまでくり返す
            var compound: [String: NBTValue] = [:]
            while true {
                let childTag = try readByte()
                if childTag == 0 {
                    break
                }
                let name = try readString()
                compound[name] = try readPayload(tag: childTag)
            }
            return .compound(compound)
        case 11:
            let count = try readCount()
            var values: [Int32] = []
            for _ in 0..<count {
                values.append(Int32(truncatingIfNeeded: try readUnsigned(byteCount: 4)))
            }
            return .intArray(values)
        case 12:
            let count = try readCount()
            var values: [Int64] = []
            for _ in 0..<count {
                values.append(Int64(bitPattern: try readUnsigned(byteCount: 8)))
            }
            return .longArray(values)
        default:
            throw NBTError.unknownTag(tag)
        }
    }

    // MARK: - バイトの読み方

    // 決まった数のバイトを取り出して、読んだ場所を進める
    private mutating func readBytes(_ count: Int) throws -> [UInt8] {
        guard count >= 0, position + count <= bytes.count else {
            throw NBTError.unexpectedEnd
        }
        let result = Array(bytes[position..<(position + count)])
        position += count
        return result
    }

    private mutating func readByte() throws -> UInt8 {
        try readBytes(1)[0]
    }

    // 小さい桁が先（リトルエンディアン）の順で並んだバイトを、1つの数にする
    private mutating func readUnsigned(byteCount: Int) throws -> UInt64 {
        let part = try readBytes(byteCount)
        var value: UInt64 = 0
        for (index, byte) in part.enumerated() {
            value |= UInt64(byte) << (8 * UInt64(index))
        }
        return value
    }

    // 配列やリストの個数（4バイト）
    private mutating func readCount() throws -> Int {
        Int(Int32(truncatingIfNeeded: try readUnsigned(byteCount: 4)))
    }

    // 文字：長さ（2バイト）→ その長さの UTF-8 の文字
    private mutating func readString() throws -> String {
        let length = Int(try readUnsigned(byteCount: 2))
        let part = try readBytes(length)
        guard let text = String(bytes: part, encoding: .utf8) else {
            throw NBTError.invalidString
        }
        return text
    }
}
