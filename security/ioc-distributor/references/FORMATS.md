# IOC Output Formats

Documentation for all supported IOC export formats.

## CSV Format

Simple comma-separated values for import into spreadsheets or SIEMs.

**Structure:**
```csv
type,value,confidence,valid_from,valid_until,description,labels
ipv4-addr,192.0.2.1,85,2026-03-17T10:00:00.000Z,2026-04-17T10:00:00.000Z,Known C2 server,malware;apt41
domain-name,evil.example.com,90,2026-03-17T12:00:00.000Z,,Phishing domain,phishing;credential-theft
file-hash,a1b2c3d4e5f6...,95,2026-03-16T08:00:00.000Z,,Ransomware payload,ransomware;lockbit
url,https://malicious.com/payload,80,2026-03-17T14:00:00.000Z,,Malware download URL,malware
```

**Fields:**
- `type` — IOC type (ipv4-addr, domain-name, file-hash, url, email-addr)
- `value` — IOC value (IP, domain, hash, URL, email)
- `confidence` — Confidence score 0-100
- `valid_from` — IOC validity start (ISO 8601)
- `valid_until` — IOC expiration (ISO 8601, empty if no expiration)
- `description` — Human-readable description
- `labels` — Semicolon-separated tags

**Usage:**
- Import into SIEM (Splunk, Elastic, Sentinel)
- Bulk operations with spreadsheets
- Custom scripts/parsers

---

## JSON Format

Structured JSON with metadata for programmatic consumption.

**Structure:**
```json
{
  "metadata": {
    "exported_at": "2026-03-17T19:00:00Z",
    "source": "opencti",
    "confidence_threshold": 70,
    "days": 7
  },
  "indicators": [
    {
      "type": "ipv4-addr",
      "value": "192.0.2.1",
      "confidence": 85,
      "valid_from": "2026-03-17T10:00:00.000Z",
      "valid_until": "2026-04-17T10:00:00.000Z",
      "description": "Known C2 server for APT41 operations",
      "labels": ["malware", "apt41", "c2"],
      "id": "indicator--a1b2c3d4-5678-90ab-cdef-1234567890ab"
    }
  ]
}
```

**Usage:**
- API integrations
- SOAR playbooks
- Custom automation scripts
- Machine-readable format

---

## STIX 2.1 Format

Structured Threat Information Expression (STIX) for threat intelligence sharing.

**Structure:**
```json
{
  "type": "bundle",
  "id": "bundle--12345678-90ab-cdef-1234-567890abcdef",
  "spec_version": "2.1",
  "objects": [
    {
      "type": "indicator",
      "spec_version": "2.1",
      "id": "indicator--a1b2c3d4-5678-90ab-cdef-1234567890ab",
      "created": "2026-03-17T10:00:00.000Z",
      "modified": "2026-03-17T10:00:00.000Z",
      "name": "Malicious IP Address",
      "description": "Known C2 server for APT41 operations",
      "pattern": "[ipv4-addr:value = '192.0.2.1']",
      "pattern_type": "stix",
      "valid_from": "2026-03-17T10:00:00.000Z",
      "valid_until": "2026-04-17T10:00:00.000Z",
      "confidence": 85,
      "labels": ["malware", "apt41"]
    }
  ]
}
```

**STIX Pattern Types:**
- IPv4: `[ipv4-addr:value = '192.0.2.1']`
- Domain: `[domain-name:value = 'evil.example.com']`
- File Hash: `[file:hashes.'SHA-256' = 'abc123...']`
- URL: `[url:value = 'https://malicious.com/payload']`

**Usage:**
- MISP integration
- TAXII feeds
- OpenCTI import/export
- Cross-organization sharing

---

## Suricata Rules

IDS/IPS rules for Suricata network security monitoring.

**Structure:**
```
# Suricata rules generated from OpenCTI
# Generated: 2026-03-17T19:00:00Z
# Confidence threshold: 70

alert ip any any -> 192.0.2.1 any (msg:"OpenCTI IOC: Suspicious IP 192.0.2.1"; sid:9000001; rev:1;)
alert ip 192.0.2.1 any -> any any (msg:"OpenCTI IOC: Suspicious IP 192.0.2.1 (src)"; sid:9000002; rev:1;)

alert dns any any -> any any (msg:"OpenCTI IOC: Suspicious domain evil.example.com"; dns.query; content:"evil.example.com"; nocase; sid:9000003; rev:1;)

alert http any any -> any any (msg:"OpenCTI IOC: Malicious URL download"; http.uri; content:"/payload"; sid:9000004; rev:1;)
```

**Rule Components:**
- `alert` — Action (alert, drop, reject)
- `ip/tcp/udp/dns/http` — Protocol
- `any any -> 192.0.2.1 any` — Source → Destination
- `msg` — Alert message
- `sid` — Signature ID (9000000+ for custom rules)
- `content` — Pattern matching
- `dns.query` / `http.uri` — Protocol-specific matching

**Usage:**
- Suricata IDS/IPS
- Network security monitoring
- Threat hunting in packet captures

---

## YARA Rules

Signature-based detection rules for files and memory.

**Structure:**
```yara
/*
 * YARA rules generated from OpenCTI
 * Generated: 2026-03-17T19:00:00Z
 * Confidence threshold: 70
 */

import "pe"
import "hash"

rule OpenCTI_Ransomware_LockBit_0
{
    meta:
        description = "LockBit ransomware payload detected"
        source = "OpenCTI"
        confidence = 95
        hash = "a1b2c3d4e5f67890abcdef1234567890"
    
    condition:
        hash.md5(0, filesize) == "a1b2c3d4e5f67890abcdef1234567890" or
        hash.sha1(0, filesize) == "abc123..." or
        hash.sha256(0, filesize) == "def456..."
}

rule OpenCTI_Malware_Strings_1
{
    meta:
        description = "Suspicious strings indicating APT41 malware"
        source = "OpenCTI"
        confidence = 80
    
    strings:
        $str1 = "C:\\ProgramData\\temp.exe" ascii
        $str2 = "192.0.2.1:443" ascii
        $str3 = {6A 40 68 00 30 00 00}  // Binary pattern
    
    condition:
        2 of ($str*)
}
```

**Usage:**
- File scanning (on-access, on-demand)
- Memory scanning for running processes
- Malware analysis
- EDR integration (CrowdStrike, SentinelOne)

---

## Format Conversion

Use `convert-format.sh` to convert between formats:

```bash
# CSV → JSON
./scripts/convert-format.sh /tmp/iocs.csv --to json --output /tmp/iocs.json

# JSON → STIX
./scripts/convert-format.sh /tmp/iocs.json --to stix --output /tmp/iocs.stix

# CSV → Suricata
./scripts/convert-format.sh /tmp/iocs.csv --to suricata --output /tmp/iocs.rules
```

---

## Best Practices

### Confidence Scores
- **90-100:** High confidence, production use
- **70-89:** Medium confidence, alert/monitor
- **50-69:** Low confidence, hunt/investigate
- **< 50:** Very low, ignore or manual review

### Expiration (TTL)
- **IP addresses:** 30-90 days (infrastructure changes frequently)
- **Domains:** 60-180 days (may be sinkholed or taken down)
- **File hashes:** 365+ days (files don't change)
- **URLs:** 30-60 days (pages change or are removed)

### Deduplication
Always deduplicate IOCs before distribution to avoid:
- Duplicate alerts in SIEM
- Performance impact on IDS/IPS
- Unnecessary rule processing

### Validation
Validate IOCs before distribution:
- **IPs:** Valid format, not private/reserved ranges
- **Domains:** Valid DNS format, not internal TLDs
- **Hashes:** Valid length (MD5: 32, SHA1: 40, SHA256: 64)
- **URLs:** Valid URI format, not localhost

### Performance
- **Suricata:** Limit to < 10,000 rules per file
- **YARA:** Limit to < 1,000 rules per file
- **SIEM:** Batch uploads, don't send 1 IOC at a time
- **Updates:** Daily for high-confidence, weekly for low-confidence

---

## References

- **STIX 2.1:** https://docs.oasis-open.org/cti/stix/v2.1/
- **Suricata Rules:** https://docs.suricata.io/en/latest/rules/
- **YARA Documentation:** https://yara.readthedocs.io/
- **OpenCTI API:** https://docs.opencti.io/latest/deployment/integrations/
