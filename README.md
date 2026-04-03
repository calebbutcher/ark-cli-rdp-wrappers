# ark-cli RDP Wrappers

Interactive wrappers around the [CyberArk ark CLI](https://docs.cyberark.com/identity-security-platform/Content/Developer/cli-overview.htm) that fetch a short-lived RDP file and immediately open it — available for both Bash (macOS/Linux) and PowerShell (Windows).

## Prerequisites

- [ark CLI](https://docs.cyberark.com/identity-security-platform/Content/Developer/cli-overview.htm) installed
- **Bash version:** macOS or Linux with Bash 4+; uses `open` to launch the RDP file (macOS default)
- **PowerShell version:** Windows PowerShell 5.1+ or PowerShell 7+

## Configuration

Before using either script, open it and fill in the four variables at the top:

| Variable | Description |
|---|---|
| `PROFILE_NAME` / `$ProfileName` | Default ark profile name (can be overridden at runtime) |
| `DEFAULT_USER` / `$DefaultUser` | Default RDP username (used for Standing / Privilege Elevation) |
| `DEFAULT_DOMAIN` / `$DefaultDomain` | Default domain (used for Standing / Privilege Elevation) |
| `OUTPUT_DIR` / `$OutputDir` | Directory where the `.rdp` file will be written |

## Usage

### Bash

```bash
chmod +x ark-rdp.sh
./ark-rdp.sh -h <target_host>
```

### PowerShell

```powershell
.\ark-rdp.ps1 -TargetHost <target_host>
```

## Interactive prompts

Both scripts walk through the same prompts after you supply the target host:

1. **Profile name** — press Enter to accept the default configured in the script
2. **Connection type:**
   - `1` — ZSP (no credentials required)
   - `2` — Standing (prompts for username + domain)
   - `3` — Privilege Elevation (prompts for username + domain, adds `-ep` flag)

After `ark` fetches the file, the script opens the most recently written `.rdp` file in the output directory automatically.

## Example session

```
$ ./ark-rdp.sh -h myserver.example.com

Profile name [my-profile]:

Connection type:
  1) ZSP                 (no credentials required)
  2) Standing            (username + domain required)
  3) Privilege Elevation (username + domain required)

Select [1/2/3]: 2
Username [jdoe]:
Domain [example.com]:

Fetching RDP file for myserver.example.com...
Opening /tmp/rdp/myserver_20260101_120000.rdp
```

## License

MIT — see [LICENSE](LICENSE).
