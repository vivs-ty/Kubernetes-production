import sys
import os
# Add the src/python directory to the system path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../../src/python')))

from config_loader import load_json_config
import pytest
import json


def test_load_valid_json_config(tmp_path):
    # tmp_path is a built-in pytest fixture for creating temporary files
    config_file = tmp_path / "valid_config.json"
    valid_data = {"server": "istiod", "port": 15012, "mtls_enabled": True}
    config_file.write_text(json.dumps(valid_data))

    # Action
    result = load_json_config(str(config_file))

    # Assert
    assert result["server"] == "istiod"
    assert result["mtls_enabled"] is True

def test_load_invalid_json_raises_error(tmp_path):
    config_file = tmp_path / "broken_config.json"
    config_file.write_text("{ server: istiod, missing_quotes_and_brackets")

    # Assert that the custom exception is raised when parsing fails
    with pytest.raises(ValueError, match="Invalid JSON structure"):
        load_json_config(str(config_file))

def test_missing_file_raises_error():
    with pytest.raises(FileNotFoundError):
        load_json_config("/path/that/does/not/exist.json")
      
