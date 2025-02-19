#!/usr/bin/python3
import sys
import json
import re


def find_json_objects(text):
    # Track opening and closing braces to handle nesting
    objects = []
    start_pos = None
    brace_count = 0

    for i, char in enumerate(text):
        if char == "{" and (start_pos is None or brace_count > 0):
            if start_pos is None:
                start_pos = i
            brace_count += 1
        elif char == "}" and start_pos is not None:
            brace_count -= 1
            if brace_count == 0:
                try:
                    json_str = text[start_pos:i + 1]
                    # Verify it is valid JSON
                    json_obj = json.loads(json_str)
                    objects.append((start_pos, i + 1, json_str))
                except:
                    pass
                start_pos = None

    return objects


for line in sys.stdin:
    json_objects = find_json_objects(line)
    if not json_objects:
        print(line, end="")
        continue

    result = ""
    last_end = 0

    for start, end, json_str in json_objects:
        # Add text before the JSON object
        result += line[last_end:start]

        # Add pretty-printed JSON
        try:
            parsed = json.loads(json_str)
            pretty = json.dumps(parsed, indent=4)
            result += "\n" + pretty + "\n"
        except:
            result += json_str

        last_end = end

    # Add any remaining text after the last JSON object
    result += line[last_end:]

    print(result, end="")
