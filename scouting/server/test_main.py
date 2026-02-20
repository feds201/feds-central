import pytest
import sys
import os

# Add the current directory to sys.path so we can import main
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from main import flatten_json

def test_flatten_json_simple():
    data = {"a": 1}
    expected = {"a": 1}
    assert flatten_json(data) == expected

def test_flatten_json_nested():
    data = {"a": {"b": 2}}
    expected = {"a_b": 2}
    assert flatten_json(data) == expected

def test_flatten_json_triple_nested():
    data = {"a": {"b": {"c": 3}}}
    expected = {"a_b_c": 3}
    assert flatten_json(data) == expected

def test_flatten_json_list():
    data = {"a": [1, 2]}
    expected = {"a_0": 1, "a_1": 2}
    assert flatten_json(data) == expected

def test_flatten_json_list_of_dicts():
    data = {"a": [{"b": 1}, {"b": 2}]}
    expected = {"a_0_b": 1, "a_1_b": 2}
    assert flatten_json(data) == expected

def test_flatten_json_complex():
    data = {
        "a": 1,
        "b": {"c": 2, "d": [3, 4]},
        "e": [{"f": 5}]
    }
    expected = {
        "a": 1,
        "b_c": 2,
        "b_d_0": 3,
        "b_d_1": 4,
        "e_0_f": 5
    }
    assert flatten_json(data) == expected

def test_flatten_json_empty_dict():
    assert flatten_json({}) == {}

def test_flatten_json_empty_nested():
    assert flatten_json({"a": {}}) == {}
    assert flatten_json({"a": []}) == {}

def test_flatten_json_mixed_types():
    data = {
        "str": "hello",
        "int": 10,
        "bool": True,
        "null": None
    }
    expected = {
        "str": "hello",
        "int": 10,
        "bool": True,
        "null": None
    }
    assert flatten_json(data) == expected
