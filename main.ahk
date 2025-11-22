; AutoHotkey v2 Script - Subnet Calculator
; Created: 2025-01-23
; Updated: 2025-11-22
; Description: CIDR subnet calculator with ISP gateway calculations
;
; Features:
; - CIDR notation support (e.g., 192.168.1.0/24)
; - Subnet mask notation support (e.g., 192.168.1.0 255.255.255.0)
; - ISP gateway calculations
; - Support for /31 (point-to-point) and /32 (host) networks
; - Comprehensive input validation
;
; Hotkeys:
; - Ctrl+Alt+S: Launch subnet calculator
; - Ctrl+Alt+Q: Exit script

; Set the script to use AutoHotkey v2 syntax
#Requires AutoHotkey v2.0

; ============================================================================
; CONSTANTS
; ============================================================================

; Regex patterns for input validation
global CIDR_PATTERN := "^\s*(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/(\d{1,2})\s*$"
global SUBNET_PATTERN := "^\s*(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\s+(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\s*$"

; ============================================================================
; HOTKEYS
; ============================================================================

; Main hotkey: Ctrl+Alt+S for subnet calculator
^!s::SubnetCalculator()

; Exit script with Ctrl+Alt+Q
^!q::ExitApp()

; ============================================================================
; MAIN FUNCTION
; ============================================================================

; Main subnet calculator function
; Handles clipboard parsing, user input, calculation, and display
SubnetCalculator() {
    ; Check clipboard for CIDR or IP + subnet mask
    clipboardText := A_Clipboard
    inputText := ""

    ; Try to parse clipboard content
    if (ParseSubnetInput(clipboardText)) {
        inputText := clipboardText
    } else {
        ; Show input dialog
        result := GetSubnetInput()
        if (result["cancelled"]) {
            return ; User cancelled
        }
        inputText := result["value"]
    }

    ; Parse and calculate subnet information
    subnetInfo := CalculateSubnetInfo(inputText)
    if (!subnetInfo) {
        MsgBox("Invalid subnet input format!", "Error", "OK Icon16")
        return
    }

    ; Display results
    ShowSubnetResults(subnetInfo)
}

; ============================================================================
; VALIDATION FUNCTIONS
; ============================================================================

; Validate IP address octets are in range 0-255
; @param ip String - IP address in dotted decimal notation
; @return Boolean - True if valid, false otherwise
ValidateIP(ip) {
    parts := StrSplit(ip, ".")
    if (parts.Length != 4) {
        return false
    }

    for part in parts {
        ; Check if part is numeric
        if (!IsInteger(part)) {
            return false
        }

        try {
            val := Integer(part)
            if (val < 0 || val > 255) {
                return false
            }
        } catch {
            return false
        }
    }
    return true
}

; Check if a string represents an integer
; @param str String - String to check
; @return Boolean - True if string is an integer
IsInteger(str) {
    return RegExMatch(str, "^\d+$")
}

; ============================================================================
; INPUT PARSING
; ============================================================================

; Parse subnet input (CIDR or IP + subnet mask)
; @param input String - Input string to parse
; @return Boolean - True if input matches expected format and has valid IP
ParseSubnetInput(input) {
    global CIDR_PATTERN, SUBNET_PATTERN

    ; Check for CIDR format (e.g., 192.168.1.0/24)
    if (RegExMatch(input, CIDR_PATTERN, &match)) {
        return ValidateIP(match[1])
    }

    ; Check for IP + subnet mask format (e.g., 192.168.1.0 255.255.255.0)
    if (RegExMatch(input, SUBNET_PATTERN, &match)) {
        return ValidateIP(match[1]) && ValidateIP(match[2])
    }

    return false
}

; ============================================================================
; USER INTERFACE - INPUT DIALOG
; ============================================================================

; Get subnet input from user via GUI dialog
; @return Map - Map with "cancelled" (Boolean) and "value" (String) keys
GetSubnetInput() {
    ; Local state for dialog
    result := Map("cancelled", false, "value", "")
    dialogClosed := false

    inputGui := Gui("+Resize", "Subnet Calculator Input")
    inputGui.SetFont("s10")

    inputGui.AddText("w400", "Enter subnet in one of these formats:")
    inputGui.AddText("w400", "• CIDR: 192.168.1.0/24")
    inputGui.AddText("w400", "• IP + Subnet: 192.168.1.0 255.255.255.0")

    inputEdit := inputGui.AddEdit("w400", "")
    inputEdit.Focus()

    ; Create button click handlers using closures
    okButton := inputGui.AddButton("w100 x10", "OK")
    cancelButton := inputGui.AddButton("w100 x120", "Cancel")

    okButton.OnEvent("Click", (*) => (
        result["cancelled"] := false,
        result["value"] := inputEdit.Value,
        inputGui.Destroy()
    ))
    cancelButton.OnEvent("Click", (*) => (
        result["cancelled"] := true,
        inputGui.Destroy()
    ))

    inputGui.Show()

    ; Wait for user input with timeout (60 seconds)
    WinWaitClose(inputGui, , 60)

    return result
}

; ============================================================================
; SUBNET CALCULATION
; ============================================================================

; Calculate subnet information from input string
; @param input String - Input in CIDR or IP+Mask format
; @return Map - Subnet information map, or false if invalid
CalculateSubnetInfo(input) {
    global CIDR_PATTERN, SUBNET_PATTERN
    subnetInfo := Map()

    ; Parse CIDR format
    if (RegExMatch(input, CIDR_PATTERN, &match)) {
        ip := match[1]

        ; Validate IP address
        if (!ValidateIP(ip)) {
            return false
        }

        ; Parse and validate CIDR with error handling
        try {
            cidr := Integer(match[2])
        } catch {
            return false
        }

        if (cidr < 0 || cidr > 32) {
            return false
        }

        subnetInfo["type"] := "CIDR"
        subnetInfo["ip"] := ip
        subnetInfo["cidr"] := cidr
        subnetInfo["subnetMask"] := CidrToSubnetMask(cidr)
    }
    ; Parse IP + subnet mask format
    else if (RegExMatch(input, SUBNET_PATTERN, &match)) {
        ip := match[1]
        subnetMask := match[2]

        ; Validate both IP addresses
        if (!ValidateIP(ip) || !ValidateIP(subnetMask)) {
            return false
        }

        cidr := SubnetMaskToCidr(subnetMask)
        if (cidr = -1) {
            return false
        }

        subnetInfo["type"] := "IP+Subnet"
        subnetInfo["ip"] := ip
        subnetInfo["cidr"] := cidr
        subnetInfo["subnetMask"] := subnetMask
    }
    else {
        return false
    }

    ; Calculate network information
    networkAddr := CalculateNetworkAddress(subnetInfo["ip"], subnetInfo["cidr"])
    broadcastAddr := CalculateBroadcastAddress(subnetInfo["ip"], subnetInfo["cidr"])
    usableIPs := CalculateUsableIPs(subnetInfo["cidr"])

    subnetInfo["network"] := networkAddr
    subnetInfo["broadcast"] := broadcastAddr
    subnetInfo["usableIPs"] := usableIPs

    ; Handle first/last usable based on network type
    if (subnetInfo["cidr"] == 32) {
        ; /32 is a single host - the host itself is the only usable IP
        subnetInfo["firstUsable"] := networkAddr
        subnetInfo["lastUsable"] := networkAddr
    } else if (subnetInfo["cidr"] == 31) {
        ; /31 point-to-point - both IPs are usable (RFC 3021)
        subnetInfo["firstUsable"] := networkAddr
        subnetInfo["lastUsable"] := broadcastAddr
    } else {
        ; Standard networks - exclude network and broadcast
        subnetInfo["firstUsable"] := IncrementIP(networkAddr)
        subnetInfo["lastUsable"] := DecrementIP(broadcastAddr)
    }

    ; Calculate ISP gateway information
    ispInfo := CalculateISPInfo(subnetInfo["ip"], subnetInfo["cidr"])
    subnetInfo["ispGateway"] := ispInfo["gateway"]
    subnetInfo["ispFirstUsable"] := ispInfo["firstUsable"]
    subnetInfo["ispLastUsable"] := ispInfo["lastUsable"]
    subnetInfo["ispUsableCount"] := ispInfo["usableCount"]

    return subnetInfo
}

; ============================================================================
; CONVERSION FUNCTIONS
; ============================================================================

; Convert CIDR notation to subnet mask
; @param cidr Integer - CIDR value (0-32)
; @return String - Subnet mask in dotted decimal notation (e.g., "255.255.255.0")
CidrToSubnetMask(cidr) {
    ; Create mask with 'cidr' number of 1s from the left
    ; Using bitwise AND with 0xFFFFFFFF to ensure 32-bit result
    mask := (0xFFFFFFFF << (32 - cidr)) & 0xFFFFFFFF
    return Format("{}.{}.{}.{}",
        (mask >> 24) & 0xFF,
        (mask >> 16) & 0xFF,
        (mask >> 8) & 0xFF,
        mask & 0xFF)
}

; Convert subnet mask to CIDR notation
; @param subnetMask String - Subnet mask in dotted decimal (e.g., "255.255.255.0")
; @return Integer - CIDR value (0-32), or -1 if invalid
SubnetMaskToCidr(subnetMask) {
    parts := StrSplit(subnetMask, ".")
    if (parts.Length != 4) {
        return -1
    }

    ; Convert to 32-bit integer with error handling
    mask := 0
    for part in parts {
        try {
            val := Integer(part)
            if (val < 0 || val > 255) {
                return -1
            }
            mask := (mask << 8) | val
        } catch {
            return -1
        }
    }

    ; Count consecutive 1s from the left
    cidr := 0
    temp := mask
    while (temp & 0x80000000) {
        cidr++
        temp := temp << 1
    }

    ; Validate that mask has contiguous 1s (proper subnet mask)
    ; Create expected mask and compare
    expectedMask := (0xFFFFFFFF << (32 - cidr)) & 0xFFFFFFFF
    if (mask != expectedMask) {
        return -1
    }

    return cidr
}

; ============================================================================
; NETWORK CALCULATIONS
; ============================================================================

; Calculate network address from IP and CIDR
; @param ip String - IP address
; @param cidr Integer - CIDR value (0-32)
; @return String - Network address
CalculateNetworkAddress(ip, cidr) {
    ipInt := IPToInt(ip)
    mask := (0xFFFFFFFF << (32 - cidr)) & 0xFFFFFFFF
    networkInt := ipInt & mask
    return IntToIP(networkInt)
}

; Calculate broadcast address from IP and CIDR
; @param ip String - IP address
; @param cidr Integer - CIDR value (0-32)
; @return String - Broadcast address
CalculateBroadcastAddress(ip, cidr) {
    ipInt := IPToInt(ip)
    mask := (0xFFFFFFFF << (32 - cidr)) & 0xFFFFFFFF
    ; Invert mask and OR with IP to get broadcast
    broadcastInt := ipInt | ((0xFFFFFFFF >> cidr) & 0xFFFFFFFF)
    return IntToIP(broadcastInt)
}

; Calculate number of usable IPs in a network
; @param cidr Integer - CIDR value (0-32)
; @return Integer - Number of usable IP addresses
; Note: Usable IPs exclude network and broadcast addresses (except /31, /32)
CalculateUsableIPs(cidr) {
    if (cidr == 32) {
        return 1  ; Single host - the IP itself is usable
    }
    if (cidr == 31) {
        return 2  ; Point-to-point link (RFC 3021) - both IPs usable
    }
    ; Standard networks: total IPs minus network and broadcast addresses
    return (2 ** (32 - cidr)) - 2
}

; ============================================================================
; ISP GATEWAY CALCULATIONS
; ============================================================================

; Calculate ISP gateway information
; @param ip String - IP address
; @param cidr Integer - CIDR value (0-32)
; @return Map - ISP information with gateway, firstUsable, lastUsable, usableCount
;
; Assumes standard ISP allocation scheme:
; - Network address: .0 (unusable, network identifier)
; - ISP Gateway: .1 (ISP router, first usable IP)
; - Customer IPs: .2 to .254 (available for customer use)
; - Broadcast: .255 (unusable, broadcast address)
;
; Note: /31 and /32 networks have special handling
CalculateISPInfo(ip, cidr) {
    networkAddr := CalculateNetworkAddress(ip, cidr)
    broadcastAddr := CalculateBroadcastAddress(ip, cidr)

    ; Handle edge cases
    if (cidr == 32) {
        ; /32 single host - no gateway concept
        return Map(
            "gateway", networkAddr,
            "firstUsable", networkAddr,
            "lastUsable", networkAddr,
            "usableCount", 0
        )
    }

    if (cidr == 31) {
        ; /31 point-to-point - typically first IP is gateway
        return Map(
            "gateway", networkAddr,
            "firstUsable", broadcastAddr,
            "lastUsable", broadcastAddr,
            "usableCount", 1
        )
    }

    ; Standard networks
    ; ISP gateway is typically the first usable IP (network + 1)
    gateway := IncrementIP(networkAddr)

    ; First usable IP for customer is gateway + 1
    firstUsable := IncrementIP(gateway)

    ; Last usable IP is broadcast - 1
    lastUsable := DecrementIP(broadcastAddr)

    ; Count ISP usable IPs (customer-available IPs)
    ispUsableCount := (IPToInt(lastUsable) - IPToInt(firstUsable) + 1)

    return Map(
        "gateway", gateway,
        "firstUsable", firstUsable,
        "lastUsable", lastUsable,
        "usableCount", ispUsableCount
    )
}

; ============================================================================
; IP ADDRESS UTILITY FUNCTIONS
; ============================================================================

; Convert IP address string to 32-bit integer
; @param ip String - IP address in dotted decimal notation (e.g., "192.168.1.1")
; @return Integer - 32-bit integer representation
; @throws Error if IP format is invalid
IPToInt(ip) {
    parts := StrSplit(ip, ".")

    ; Bounds checking
    if (parts.Length != 4) {
        throw ValueError("Invalid IP address format: expected 4 octets, got " . parts.Length)
    }

    ; Convert with error handling
    try {
        return (Integer(parts[1]) << 24) | (Integer(parts[2]) << 16) | (Integer(parts[3]) << 8) | Integer(parts[4])
    } catch as err {
        throw ValueError("Invalid IP address format: " . err.Message)
    }
}

; Convert 32-bit integer to IP address string
; @param ipInt Integer - 32-bit integer representation of IP
; @return String - IP address in dotted decimal notation
IntToIP(ipInt) {
    ; Ensure value is within 32-bit range
    ipInt := ipInt & 0xFFFFFFFF

    return Format("{}.{}.{}.{}",
        (ipInt >> 24) & 0xFF,
        (ipInt >> 16) & 0xFF,
        (ipInt >> 8) & 0xFF,
        ipInt & 0xFF)
}

; Increment IP address by 1
; @param ip String - IP address to increment
; @return String - Next IP address
IncrementIP(ip) {
    ipInt := IPToInt(ip)
    return IntToIP(ipInt + 1)
}

; Decrement IP address by 1
; @param ip String - IP address to decrement
; @return String - Previous IP address
DecrementIP(ip) {
    ipInt := IPToInt(ip)
    return IntToIP(ipInt - 1)
}

; ============================================================================
; USER INTERFACE - RESULTS DISPLAY
; ============================================================================

; Show subnet calculation results in GUI
; @param subnetInfo Map - Subnet information to display
ShowSubnetResults(subnetInfo) {
    resultsGui := Gui("+Resize", "Subnet Calculator Results")
    resultsGui.SetFont("s10")

    ; Create results text with consistent formatting
    results := "SUBNET CALCULATION RESULTS`n`n"
    results .= "Input: " . subnetInfo["ip"] . "/" . subnetInfo["cidr"] . "`n"
    results .= "Subnet Mask: " . subnetInfo["subnetMask"] . "`n`n"

    results .= "NETWORK INFORMATION:`n"
    results .= "Network Address: " . subnetInfo["network"] . "`n"
    results .= "Broadcast Address: " . subnetInfo["broadcast"] . "`n"
    results .= "Usable IP Range: " . subnetInfo["firstUsable"] . " - " . subnetInfo["lastUsable"] . "`n"
    results .= "Total Usable IPs: " . subnetInfo["usableIPs"] . "`n`n"

    results .= "ISP PUBLIC IP SETUP:`n"
    results .= "Network IP: " . subnetInfo["network"] . "`n"
    results .= "ISP Gateway: " . subnetInfo["ispGateway"] . "`n"
    results .= "ISP Usable Range: " . subnetInfo["ispFirstUsable"] . " - " . subnetInfo["ispLastUsable"] . "`n"
    results .= "ISP Total Usable IPs: " . subnetInfo["ispUsableCount"] . "`n"
    results .= "Broadcast IP: " . subnetInfo["broadcast"] . "`n"

    ; Add editable control for easy selection/copy
    textControl := resultsGui.AddEdit("w600 h400 ReadOnly vResultsText", results)

    ; Add copy button
    copyButton := resultsGui.AddButton("w100 x10", "Copy All")
    copyButton.OnEvent("Click", (*) => CopyResults(results))

    ; Add close button
    closeButton := resultsGui.AddButton("w100 x120", "Close")
    closeButton.OnEvent("Click", (*) => resultsGui.Destroy())

    resultsGui.Show()
}

; Copy results to clipboard and show notification
; @param results String - Results text to copy
CopyResults(results) {
    A_Clipboard := results
    ToolTip("Results copied to clipboard!")
    SetTimer(() => ToolTip(), -2000)
}