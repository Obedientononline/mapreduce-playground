#!/usr/bin/env python3
import sys
import re

LOG_PATTERN = re.compile(
    r'^(\S+)'
    r'\s+\S+\s+\S+'
    r'\s+\[(\d{2}/\w+/\d{4})'
    r':(\d{2}):\d{2}:\d{2}\s+[^\]]+\]'
    r'\s+"(\S+)\s+(\S+)\s*\S*"'
    r'\s+(\d{3})'
    r'\s+(\S+)'
)

MONTH_MAP = {
    'Jan':'01','Feb':'02','Mar':'03','Apr':'04',
    'May':'05','Jun':'06','Jul':'07','Aug':'08',
    'Sep':'09','Oct':'10','Nov':'11','Dec':'12'
}

def parse_date(raw_date):
    try:
        parts = raw_date.split('/')
        return f"{parts[2]}-{MONTH_MAP.get(parts[1], '01')}-{parts[0]}"
    except:
        return '1995-01-01'

def parse_bytes(raw_bytes):
    if raw_bytes == '-':
        return 0
    try:
        return int(raw_bytes)
    except:
        return 0

for line in sys.stdin:
    line = line.strip()
    if not line:
        continue
    match = LOG_PATTERN.match(line)
    if not match:
        continue

    host       = match.group(1)
    raw_date   = match.group(2)
    hour       = match.group(3)
    method     = match.group(4).upper()
    url        = match.group(5)
    status     = match.group(6)
    byte_count = parse_bytes(match.group(7))
    date       = parse_date(raw_date)

    # Record Type 1: Traffic analysis (grouped by host/date/hour)
    traffic_key = f"{host}|{date}|{hour}"
    traffic_val = f"{url}|{status}|{byte_count}|{method}"
    print(f"{traffic_key}\t{traffic_val}")

    # Record Type 2: Security / bot detection (grouped by host/date)
    security_key = f"SEC|{host}|{date}"
    security_val = f"{status}|{hour}|{url}"
    print(f"{security_key}\t{security_val}")
