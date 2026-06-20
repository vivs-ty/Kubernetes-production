import json
import os

def load_json_config(filepath):
    if not os.path.exists(filepath):
        raise FileNotFoundError(f"Configuration file not found: {filepath}")

    try:
        with open(filepath, 'r') as file:
            data = json.load(file)
            return data
    except json.JSONDecodeError as e:
        raise ValueError(f"Invalid JSON structure in {filepath}: {e}")
        
