# Subnet Calculator (AutoHotkey v2)

A comprehensive subnet calculator with ISP gateway calculations, built with AutoHotkey v2. Features automatic clipboard detection, comprehensive input validation, and support for special network types including /31 (point-to-point) and /32 (host route) networks.

## Features

- **Multiple Input Formats**
  - CIDR notation: `192.168.1.0/24`
  - IP + Subnet Mask: `192.168.1.0 255.255.255.0`
  - Automatic clipboard detection

- **Comprehensive Calculations**
  - Network and broadcast addresses
  - Usable IP range and count
  - ISP gateway configuration
  - Customer-available IP ranges

- **Special Network Support**
  - `/32` networks (single host routes)
  - `/31` networks (point-to-point links per RFC 3021)
  - Full range from `/0` to `/32`

- **Robust Input Validation**
  - IP address octet range validation (0-255)
  - CIDR range validation (0-32)
  - Subnet mask format validation
  - Comprehensive error handling

## Requirements

- AutoHotkey v2.0 or later
- Windows operating system

## Installation

1. Install [AutoHotkey v2](https://www.autohotkey.com/v2/)
2. Download `main.ahk`
3. Double-click `main.ahk` to run the script

## Usage

### Hotkeys

- **Ctrl+Alt+S**: Launch subnet calculator
- **Ctrl+Alt+Q**: Exit script

### Quick Start

1. Copy a subnet (e.g., `192.168.1.0/24`) to your clipboard
2. Press **Ctrl+Alt+S**
3. The calculator will automatically detect and parse the clipboard content
4. View the results in the GUI window

### Manual Input

1. Press **Ctrl+Alt+S** without a valid subnet in clipboard
2. Enter subnet in one of the supported formats:
   - CIDR: `192.168.1.0/24`
   - IP + Mask: `192.168.1.0 255.255.255.0`
3. Click **OK** to calculate

### Example Calculations

#### Standard /24 Network
```
Input: 192.168.1.0/24

NETWORK INFORMATION:
Network Address: 192.168.1.0
Broadcast Address: 192.168.1.255
Usable IP Range: 192.168.1.1 - 192.168.1.254
Total Usable IPs: 254

ISP PUBLIC IP SETUP:
Network IP: 192.168.1.0
ISP Gateway: 192.168.1.1
ISP Usable Range: 192.168.1.2 - 192.168.1.254
ISP Total Usable IPs: 253
Broadcast IP: 192.168.1.255
```

#### /31 Point-to-Point Network (RFC 3021)
```
Input: 10.0.0.0/31

NETWORK INFORMATION:
Network Address: 10.0.0.0
Broadcast Address: 10.0.0.1
Usable IP Range: 10.0.0.0 - 10.0.0.1
Total Usable IPs: 2
```

#### /32 Host Route
```
Input: 10.0.0.1/32

NETWORK INFORMATION:
Network Address: 10.0.0.1
Broadcast Address: 10.0.0.1
Usable IP Range: 10.0.0.1 - 10.0.0.1
Total Usable IPs: 1
```

## ISP Gateway Assumptions

The ISP gateway calculations assume a standard ISP public IP allocation scheme:

- **Network Address** (.0): Unusable, network identifier
- **ISP Gateway** (.1): ISP router, first usable IP
- **Customer IPs** (.2 to .254): Available for customer devices
- **Broadcast** (.255): Unusable, broadcast address

**Note**: Different ISPs may use different allocation schemes. These calculations represent the most common configuration.

## Validation

The script performs comprehensive validation:

- ✅ IP address octets must be in range 0-255
- ✅ CIDR values must be 0-32
- ✅ Subnet masks must have contiguous 1s
- ✅ All input formats are validated before calculation
- ✅ Error handling prevents crashes on malformed input

## Supported Network Ranges

| CIDR | Subnet Mask | Usable IPs | Use Case |
|------|-------------|------------|----------|
| /32 | 255.255.255.255 | 1 | Host route |
| /31 | 255.255.255.254 | 2 | Point-to-point link |
| /30 | 255.255.255.252 | 2 | Point-to-point (traditional) |
| /24 | 255.255.255.0 | 254 | Small LAN |
| /16 | 255.255.0.0 | 65,534 | Large network |
| /8 | 255.0.0.0 | 16,777,214 | Class A network |
| /0 | 0.0.0.0 | 4,294,967,294 | Entire IPv4 space |

## Troubleshooting

### Invalid Input Errors
- Ensure IP octets are between 0-255
- Verify CIDR is between 0-32
- Check subnet mask has contiguous 1s (e.g., 255.255.255.0, not 255.255.240.15)

### Script Won't Start
- Verify AutoHotkey v2.0 or later is installed
- Check that no other scripts are using the same hotkeys
- Run as administrator if clipboard access fails

### Hotkey Conflicts
- If Ctrl+Alt+S or Ctrl+Alt+Q conflict with other software, edit `main.ahk` lines 33 and 36 to change hotkeys

## Technical Details

### Architecture
- Written in AutoHotkey v2 scripting language
- Uses bitwise operations for efficient IP calculations
- Implements RFC 3021 for /31 network support
- Comprehensive error handling with try-catch blocks

### Code Quality
- Full JSDoc-style documentation
- Input validation at all entry points
- No global state variables
- Modular function design

## Testing

The script has been validated against these test cases:

**Valid Inputs:**
- ✓ `192.168.1.0/24` (standard network)
- ✓ `10.0.0.0/8` (large network)
- ✓ `172.16.0.0 255.255.0.0` (IP + mask format)
- ✓ `0.0.0.0/0` (entire internet)
- ✓ `255.255.255.255/32` (single host)
- ✓ `192.168.1.0/31` (point-to-point)

**Invalid Inputs (correctly rejected):**
- ✗ `256.1.1.1/24` (invalid octet > 255)
- ✗ `192.168.1.0/33` (invalid CIDR > 32)
- ✗ `192.168.1.0 255.255.240.15` (invalid subnet mask)
- ✗ `abc.def.ghi.jkl/24` (non-numeric input)
- ✗ `192.168.1/24` (incomplete IP address)

## Contributing

This is a personal utility script. Feel free to fork and modify for your needs.

## License

This project is provided as-is for educational and personal use.

## Version History

- **v2.0** (2025-11-22)
  - Complete rewrite with comprehensive validation
  - Added /31 and /32 network support
  - Improved error handling and bounds checking
  - Removed global variables
  - Added extensive documentation
  - Fixed all critical bugs from code review

- **v1.0** (2025-01-23)
  - Initial release
  - Basic CIDR and IP+Mask support
  - ISP gateway calculations

## References

- [RFC 3021](https://tools.ietf.org/html/rfc3021) - Using 31-Bit Prefixes on IPv4 Point-to-Point Links
- [CIDR Notation](https://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing)
- [Subnet Masks](https://en.wikipedia.org/wiki/Subnetwork)
