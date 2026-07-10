from enum import Enum

from pydantic import AnyUrl


def convert_enums_to_values(data):
    """
    This function takes a dictionary and converts any Enum values to their corresponding string values.
    """
    for key, val in data.items():
        if isinstance(val, Enum):
            data[key] = val.value
        elif isinstance(val, AnyUrl):
            data[key] = str(val)
    return data