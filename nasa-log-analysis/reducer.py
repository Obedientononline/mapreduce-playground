#!/usr/bin/env python3
import sys
from collections import defaultdict, Counter

current_key = None
records = []

def process_traffic_group(key, recs):
    parts = key.split('|')
    if len(parts) != 3:
        return
    host, date, hour = parts
    url_stats = defaultdict(lambda: {'count': 0, 'bytes': 0, 'errors': 0})
    for rec in recs:
        fields = rec.split('|')
        if len(fields) < 4:
            continue
        url, status, byte_str, method = fields[0], fields[1], fields[2], fields[3]
        try:
            byt = int(byte_str)
        except:
            byt = 0
        url_stats[url]['count'] += 1
        url_stats[url]['bytes'] += byt
        if status in ('404', '500', '503', '403', '401'):
            url_stats[url]['errors'] += 1
    for url, stats in url_stats.items():
        print(f"TRAFFIC,{host},{date},{hour},{url},"
              f"{stats['count']},{stats['bytes']},{stats['errors']}")

def process_security_group(key, recs):
    parts = key.split('|')
    if len(parts) != 3:
        return
    _, host, date = parts
    total_requests = len(recs)
    status_counts = Counter()
    curr_consec = 0
    max_consec_401 = 0
    for rec in recs:
        fields = rec.split('|')
        if len(fields) < 3:
            continue
        status = fields[0]
        status_counts[status] += 1
        if status == '401':
            curr_consec += 1
            max_consec_401 = max(max_consec_401, curr_consec)
        else:
            curr_consec = 0
    total_401s = status_counts.get('401', 0)
    total_404s = status_counts.get('404', 0)
    flags = []
    if total_requests > 500:     flags.append('BOT_SUSPECTED')
    if max_consec_401 >= 3:      flags.append('BRUTE_FORCE_LOGIN')
    if total_404s > 50:          flags.append('SCANNER_SUSPECTED')
    if not flags:                flags.append('NORMAL')
    print(f"SECURITY,{host},{date},{total_requests},"
          f"{total_401s},{max_consec_401},{total_404s},{'|'.join(flags)}")

for line in sys.stdin:
    line = line.strip()
    if not line:
        continue
    try:
        key, value = line.split('\t', 1)
    except ValueError:
        continue
    if key != current_key:
        if current_key is not None:
            if current_key.startswith('SEC|'):
                process_security_group(current_key, records)
            else:
                process_traffic_group(current_key, records)
        current_key = key
        records = [value]
    else:
        records.append(value)

if current_key:
    if current_key.startswith('SEC|'):
        process_security_group(current_key, records)
    else:
        process_traffic_group(current_key, records)
