import json
import os
from pathlib import Path
from typing import Any, Optional
from anki import collection, db

PROFILE_DB = "prefs21.db"

# need to determine which profile to use before we can reference this
COLLECTION_DB = "collection.anki2"


def get_base_path() -> Optional[str]:
    """Get base path on current system"""
    # If base_path not defined: Look in environment variables
    if path_as_str := os.environ.get("APY_BASE"):
        return path_as_str

    if path_as_str := os.environ.get("ANKI_BASE"):
        return path_as_str

    # Otherwise look in usual paths:
    # https://docs.ankiweb.net/files.html#file-locations
    if xdg_data_home := os.environ.get("XDG_DATA_HOME"):
        if (path := Path(xdg_data_home) / "Anki2").exists():
            return str(path)

    if (path := Path.home() / ".local/share/Anki2").exists():
        return str(path)

    if (path := Path.home() / "Library/Application Support/Anki2").exists():
        return str(path)

    return None


profile_db_path = Path(get_base_path()) / PROFILE_DB
_db = db.DB(profile_db_path)
profile_names = _db.list('select name from profiles where name != "_global"')
collection_db_path = Path(get_base_path()) / profile_names[0] / COLLECTION_DB
col = collection.Collection(collection_db_path)
import ipdb; ipdb.set_trace()