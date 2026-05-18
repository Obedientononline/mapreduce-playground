#!/usr/bin/env python3
import sys

def reduce_sales(stream):
    current_key = None
    total_sales = 0.0
    count = 0

    def emit(key, total, n):
        avg = total / n if n > 0 else 0
        print(f"{key}\t| total=${total:,.2f}\t| transactions={n}\t| avg=${avg:,.2f}")

    for line in stream:
        line = line.strip()
        if not line:
            continue
        parts = line.split("\t", 1)
        if len(parts) != 2:
            print(f"SKIPPED malformed reducer input: {line}", file=sys.stderr)
            continue
        key, value = parts
        try:
            price = float(value)
        except ValueError:
            print(f"SKIPPED invalid value: {line}", file=sys.stderr)
            continue
        if key == current_key:
            total_sales += price
            count += 1
        else:
            if current_key is not None:
                emit(current_key, total_sales, count)
            current_key = key
            total_sales = price
            count = 1

    if current_key is not None:
        emit(current_key, total_sales, count)

if __name__ == "__main__":
    reduce_sales(sys.stdin)
