import os
import Darwin
import IOKit.hid
import Foundation

// MARK: - Logger

func debug(_ message: String = "",
           fileID: String = #fileID,
           function: String = #function) {
    if Preferences.debug {
        Logger().debug("\(fileID, privacy: .public): \(function, privacy: .public) \(message, privacy: .public)")
    }
}

func notice(_ message: String = "",
            fileID: String = #fileID,
            function: String = #function) {
    Logger().notice("\(fileID, privacy: .public): \(function, privacy: .public) \(message, privacy: .public)")
}

func warning(_ message: String = "",
             fileID: String = #fileID,
             function: String = #function) {
    Logger().warning("\(fileID, privacy: .public): \(function, privacy: .public) \(message, privacy: .public)")
}

// MARK: - Array & Dictionary

@inlinable func flip<T>(_ array: [T]) -> [T: Int] { Dictionary(uniqueKeysWithValues: zip(array, 0..<array.count)) }
@inlinable func flip<T, U>(_ dictionary: [T: U]) -> [U: T] { dictionary.reduce(into: [:]) { $0[$1.value] = $1.key } }

// MARK: - OS AbsoluteTime

// https://developer.apple.com/library/archive/qa/qa1398/
private var sTimebaseInfo = mach_timebase_info()
func ms(since: UInt64) -> Int64 {
    debug("\(since)")

    let current = mach_absolute_time()

    if sTimebaseInfo.denom == 0 {
        guard mach_timebase_info(&sTimebaseInfo) == KERN_SUCCESS else {
            return 0
        }
    }

    let diff = Int64(current) - Int64(since)
    let nsec = diff * Int64(sTimebaseInfo.numer) / Int64(sTimebaseInfo.denom)

    return nsec / Int64(NSEC_PER_MSEC)
}

func ms(absolute: UInt64) -> UInt64 {
    debug("\(absolute)")

    if sTimebaseInfo.denom == 0 {
        guard mach_timebase_info(&sTimebaseInfo) == KERN_SUCCESS else {
            return 0
        }
    }

    let nsec = UInt64(absolute) * UInt64(sTimebaseInfo.numer) / UInt64(sTimebaseInfo.denom)

    return nsec / UInt64(NSEC_PER_MSEC)
}

// MARK: - Modifier Mapping

private func getModifierMappingPairs_Registry(_ device: IOHIDDevice) -> [[String: UInt64]]? {
    debug()

    var entry = IOHIDDeviceGetService(device)

    while entry != 0 {
        if let properties = IORegistryEntryCreateCFProperty(
            entry,
            "HIDEventServiceProperties" as CFString,
            kCFAllocatorDefault,
            .zero
        )?.takeUnretainedValue() as? [String: Any],
           let maps = properties["HIDKeyboardModifierMappingPairs"] as? [[String: UInt64]] {
            return maps
        }

        var child: io_registry_entry_t = 0
        IORegistryEntryGetChildEntry(entry, kIOServicePlane, &child)
        entry = child
    }

    warning("HIDKeyboardModifierMappingPairs 없음")
    return nil
}

private func getModifierMappingPairs_UserDefaults(_ device: IOHIDDevice) -> [[String: UInt64]]? {
    debug()

    guard let vendor = IOHIDDeviceGetProperty(device, kIOHIDVendorIDKey as CFString) as? Int,
          let product = IOHIDDeviceGetProperty(device, kIOHIDProductIDKey as CFString) as? Int else {
        warning("VendorID 또는 ProductID 없음")
        return nil
    }

    let key = "com.apple.keyboard.modifiermapping.\(vendor)-\(product)-0"
    let maps = UserDefaults.standard.object(forKey: key) as? [[String: UInt64]]

    guard let maps else {
        warning("com.apple.keyboard.modifiermapping 없음")
        return nil
    }

    return maps
}

/**
 "보조 키(Modifier Keys)" 매핑 설정에 맞는 usage 값 반환
 @see https://developer.apple.com/library/archive/technotes/tn2450/
 @see https://stackoverflow.com/a/37648516
 */
func getMappedModifierUsage(_ usage: UInt32, _ device: IOHIDDevice) -> UInt32 {
    debug("\(usage) \(device)")

    guard let maps = getModifierMappingPairs_Registry(device) ?? getModifierMappingPairs_UserDefaults(device) else {
        warning("보조 키 매핑이 없음")
        return usage
    }

    for map in maps {
        guard let src = map["HIDKeyboardModifierMappingSrc"],
              let dst = map["HIDKeyboardModifierMappingDst"] else {
            continue
        }

        // 설정에 매핑되어 있으면 맞는 값 반환
        if src & 0xFF == usage {
            debug("\(String(format: "0x%X", src)) -> \(String(format: "0x%X", dst))")

            return UInt32(dst & 0xFF)
        }
    }

    // 설정은 있으나 매핑이 없으면 그대로 반환
    return usage
}

// MARK: - Etc

/**
 연결된 모든 HID 키보드에 대해 Caps Lock 상태와 LED 조정
 @see https://github.com/busyloop/maclight
 */
private var block = DispatchWorkItem { }
func setKeyboardCapsLock(enabled: Bool) {
    debug("\(enabled)")

    block.cancel()
    block = DispatchWorkItem {
        let hid = IOHIDManagerCreate(kCFAllocatorDefault, 0)

        /** HID 키보드 찾기 */
        IOHIDManagerSetDeviceMatching(hid, [
            kIOHIDDeviceUsagePageKey: kHIDPage_GenericDesktop, // Generic Desktop Page (0x01)
            kIOHIDDeviceUsageKey: kHIDUsage_GD_Keyboard        // Keyboard (0x06, Collection Application)
        ] as CFDictionary)

        guard IOHIDManagerOpen(hid, 0) == kIOReturnSuccess else {
            warning("IOHIDManagerOpen 실패")
            return
        }

        guard let devs = IOHIDManagerCopyDevices(hid) as? Set<IOHIDDevice> else {
            warning("IOHIDManagerCopyDevices 실패")
            return
        }

        for dev in devs {
            /** Caps Lock 상태 */
            let serv = IOHIDDeviceGetService(dev)
            var conn = io_connect_t()

            guard IOServiceOpen(serv, mach_task_self_, UInt32(kIOHIDParamConnectType), &conn) == KERN_SUCCESS else {
                warning("IOServiceOpen 실패: \(serv)")
                continue
            }
            defer { IOServiceClose(conn) }

            guard IOHIDSetModifierLockState(conn, Int32(kIOHIDCapsLockState), enabled) == KERN_SUCCESS else {
                warning("IOHIDSetModifierLockState 실패: \(conn)")
                continue
            }

            debug("IOHIDSetModifierLockState 성공: \(dev)")

            /** Caps Lock LED */
            guard let elems = IOHIDDeviceCopyMatchingElements(dev, [
                kIOHIDElementUsagePageKey: kHIDPage_LEDs,     // LED Page (0x08)
                kIOHIDElementUsageKey: kHIDUsage_LED_CapsLock // Caps Lock (0x02)
            ] as CFDictionary, 0) as? [IOHIDElement] else {
                warning("IOHIDDeviceCopyMatchingElements 실패: \(dev)")
                continue
            }

            let time = mach_absolute_time()
            for elem in elems {
                let val = IOHIDValueCreateWithIntegerValue(kCFAllocatorDefault, elem, time, enabled ? 1 : 0)
                guard IOHIDDeviceSetValue(dev, elem, val) == kIOReturnSuccess else {
                    warning("IOHIDDeviceSetValue 실패: \(elem)")
                    continue
                }
            }

            debug("IOHIDDeviceSetValue 성공: \(dev)")
        }
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200), execute: block)
    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300), execute: block)
}

func getKeyboardCapsLock() -> Bool {
    debug()

    var conn = io_connect_t()
    let serv = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching(kIOHIDSystemClass))

    guard IOServiceOpen(serv, mach_task_self_, UInt32(kIOHIDParamConnectType), &conn) == KERN_SUCCESS else {
        warning("IOServiceOpen 실패: \(serv)")
        return false
    }
    defer { IOServiceClose(conn) }

    var enabled = false
    guard IOHIDGetModifierLockState(conn, Int32(kIOHIDCapsLockState), &enabled) == KERN_SUCCESS else {
        warning("IOHIDGetModifierLockState 실패: \(conn)")
        return false
    }

    debug("IOHIDGetModifierLockState 성공: \(conn) \(enabled)")

    return enabled
}
