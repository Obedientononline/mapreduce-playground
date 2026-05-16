#!/usr/bin/env python3
import sys

def map_sales(stream):
    for line in stream:
        line = line.strip()
        if not line:
            continue
        fields = line.split(",")
        if len(fields) != 6:
            print(f"SKIPPED malformed line: {line}", file=sys.stderr)
            continue
        date, city, category, product, price, customer = fields
        try:
            price = float(price)
        except ValueError:
            print(f"SKIPPED invalid price: {line}", file=sys.stderr)
            continue
        print(f"{category}\t{price}")

if __name__ == "__main__":
    map_sales(sys.stdin)
