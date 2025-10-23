; AutoHotkey v2 Script - Subnet Calculator
; Created: 2025-01-23
; Description: CIDR subnet calculator with ISP gateway calculations

; Set the script to use AutoHotkey v2 syntax
#Requires AutoHotkey v2.0

; Main hotkey: Ctrl+Alt+S for subnet calculator
^!s::SubnetCalculator()

; Exit script with Ctrl+Alt+Q
^!q::ExitApp()

; Main subnet calculator function
SubnetCalculator() {
    ; Check clipboard for CIDR or IP + subnet mask
    clipboardText := A_Clipboard
    inputText := ""
    
    ; Try to parse clipboard content
    if (ParseSubnetInput(clipboardText)) {
        inputText := clipboardText
    } else {
        ; Show input dialog
        inputText := GetSubnetInput()
        if (inputText = "") {
            return ; User cancelled
        }
    }
    
    ; Parse and calculate subnet information
    subnetInfo := CalculateSubnetInfo(inputText)
    if (!subnetInfo) {
        MsgBox("Invalid subnet input format!", "Error", "OK")
        return
    }
    
    ; Display results
    ShowSubnetResults(subnetInfo)
}

; Parse subnet input (CIDR or IP + subnet mask)
ParseSubnetInput(input) {
    ; Check for CIDR format (e.g., 192.168.1.0/24)
    if (RegExMatch(input, "^\s*(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/(\d{1,2})\s*$", &match)) {
        return true
    }
    
    ; Check for IP + subnet mask format (e.g., 192.168.1.0 255.255.255.0)
    if (RegExMatch(input, "^\s*(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\s+(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\s*$", &match)) {
        return true
    }
    
    return false
}

; Global variables
InputDialogCancelled := false

; Get subnet input from user
GetSubnetInput() {
    global InputDialogCancelled
    InputDialogCancelled := false
    inputTextVal := ""
    inputGui := Gui("+Resize", "Subnet Calculator Input")
    inputGui.SetFont("s10")
    
    inputGui.AddText("w400", "Enter subnet in one of these formats:")
    inputGui.AddText("w400", "• CIDR: 192.168.1.0/24")
    inputGui.AddText("w400", "• IP + Subnet: 192.168.1.0 255.255.255.0")
    
    inputEdit := inputGui.AddEdit("w400", "")
    inputEdit.Focus()
    
    ; Create button click handlers
    okButton := inputGui.AddButton("w100 x10", "OK")
    cancelButton := inputGui.AddButton("w100 x120", "Cancel")
    
    okButton.OnEvent("Click", (*) => (
        InputDialogCancelled := false,
        inputTextVal := inputEdit.Value,
        inputGui.Destroy()
    ))
    cancelButton.OnEvent("Click", (*) => (
        InputDialogCancelled := true,
        inputGui.Destroy()
    ))
    
    inputGui.Show()
    
    ; Wait for user input
    WinWaitClose(inputGui)
    
    ; Check if cancelled
    if (InputDialogCancelled) {
        return ""
    }
    
    return inputTextVal
}

; Calculate subnet information
CalculateSubnetInfo(input) {
    subnetInfo := Map()
    
    ; Parse CIDR format
    if (RegExMatch(input, "^\s*(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/(\d{1,2})\s*$", &match)) {
        ip := match[1]
        cidr := Integer(match[2])
        
        if (cidr < 0 || cidr > 32) {
            return false
        }
        
        subnetInfo["type"] := "CIDR"
        subnetInfo["ip"] := ip
        subnetInfo["cidr"] := cidr
        subnetInfo["subnetMask"] := CidrToSubnetMask(cidr)
    }
    ; Parse IP + subnet mask format
    else if (RegExMatch(input, "^\s*(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\s+(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\s*$", &match)) {
        ip := match[1]
        subnetMask := match[2]
        
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
    subnetInfo["firstUsable"] := IncrementIP(networkAddr)
    subnetInfo["lastUsable"] := DecrementIP(broadcastAddr)
    
    ; Calculate ISP gateway information
    ispInfo := CalculateISPInfo(subnetInfo["ip"], subnetInfo["cidr"])
    subnetInfo["ispGateway"] := ispInfo["gateway"]
    subnetInfo["ispFirstUsable"] := ispInfo["firstUsable"]
    subnetInfo["ispLastUsable"] := ispInfo["lastUsable"]
    subnetInfo["ispUsableCount"] := ispInfo["usableCount"]
    
    return subnetInfo
}

; Convert CIDR to subnet mask
CidrToSubnetMask(cidr) {
    mask := 0xFFFFFFFF << (32 - cidr)
    return Format("{}.{}.{}.{}", 
        (mask >> 24) & 0xFF,
        (mask >> 16) & 0xFF,
        (mask >> 8) & 0xFF,
        mask & 0xFF)
}

; Convert subnet mask to CIDR
SubnetMaskToCidr(subnetMask) {
    parts := StrSplit(subnetMask, ".")
    if (parts.Length != 4) {
        return -1
    }
    
    mask := 0
    for part in parts {
        val := Integer(part)
        if (val < 0 || val > 255) {
            return -1
        }
        mask := (mask << 8) | val
    }
    
    ; Count consecutive 1s from the left
    cidr := 0
    temp := mask
    while (temp & 0x80000000) {
        cidr++
        temp := temp << 1
    }
    
    ; Check if it's a valid subnet mask
    if ((mask << cidr) != 0) {
        return -1
    }
    
    return cidr
}

; Calculate network address
CalculateNetworkAddress(ip, cidr) {
    ipInt := IPToInt(ip)
    mask := 0xFFFFFFFF << (32 - cidr)
    networkInt := ipInt & mask
    return IntToIP(networkInt)
}

; Calculate broadcast address
CalculateBroadcastAddress(ip, cidr) {
    ipInt := IPToInt(ip)
    mask := 0xFFFFFFFF << (32 - cidr)
    broadcastInt := ipInt | (~mask)
    return IntToIP(broadcastInt)
}

; Calculate number of usable IPs
CalculateUsableIPs(cidr) {
    if (cidr >= 31) {
        return 0 ; /31 and /32 have no usable IPs
    }
    return (2 ** (32 - cidr)) - 2
}

; Calculate ISP gateway information
CalculateISPInfo(ip, cidr) {
    networkAddr := CalculateNetworkAddress(ip, cidr)
    broadcastAddr := CalculateBroadcastAddress(ip, cidr)
    
    ; ISP gateway is typically the first usable IP
    gateway := IncrementIP(networkAddr)
    
    ; First usable IP for ISP setup is gateway + 1
    firstUsable := IncrementIP(gateway)
    
    ; Last usable IP is broadcast - 1
    lastUsable := DecrementIP(broadcastAddr)

    ; Count ISP usable IPs inclusive
    ispUsableCount := (IPToInt(lastUsable) - IPToInt(firstUsable) + 1)
    
    return Map("gateway", gateway, "firstUsable", firstUsable, "lastUsable", lastUsable, "usableCount", ispUsableCount)
}

; Convert IP string to integer
IPToInt(ip) {
    parts := StrSplit(ip, ".")
    return (Integer(parts[1]) << 24) | (Integer(parts[2]) << 16) | (Integer(parts[3]) << 8) | Integer(parts[4])
}

; Convert integer to IP string
IntToIP(ipInt) {
    return Format("{}.{}.{}.{}", 
        (ipInt >> 24) & 0xFF,
        (ipInt >> 16) & 0xFF,
        (ipInt >> 8) & 0xFF,
        ipInt & 0xFF)
}

; Increment IP address
IncrementIP(ip) {
    ipInt := IPToInt(ip)
    return IntToIP(ipInt + 1)
}

; Decrement IP address
DecrementIP(ip) {
    ipInt := IPToInt(ip)
    return IntToIP(ipInt - 1)
}

; Show subnet calculation results
ShowSubnetResults(subnetInfo) {
    resultsGui := Gui("+Resize", "Subnet Calculator Results")
    resultsGui.SetFont("s10")
    
    ; Create results text
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
    results .= "ISP Usable Range: " . subnetInfo["ispFirstUsable"] . "-" . subnetInfo["ispLastUsable"] . "`n"
    results .= "ISP Total Usable IPs: " . subnetInfo["ispUsableCount"] . "`n"
    results .= "Broadcast IP: " . subnetInfo["broadcast"] . "`n"
    
    ; Add editable control for easy selection/copy
    textControl := resultsGui.AddEdit("w600 h400 ReadOnly vResultsText", results)
    
    ; Add copy button with separate function
    copyButton := resultsGui.AddButton("w100 x10", "Copy All")
    copyButton.OnEvent("Click", (*) => CopyResults(results))
    
    ; Add close button
    closeButton := resultsGui.AddButton("w100 x120", "Close")
    closeButton.OnEvent("Click", (*) => resultsGui.Destroy())
    
    resultsGui.Show()
}

; Copy results function
CopyResults(results) {
    A_Clipboard := results
    ToolTip("Results copied to clipboard!")
    SetTimer(() => ToolTip(), -2000)
}