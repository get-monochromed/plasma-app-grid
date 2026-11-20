# SPDX-License-Identifier: GPL-2.0-or-later

import argparse
import json
from pathlib import Path
from shutil import copytree


def main() -> None:
    parser = argparse.ArgumentParser(description="Build the six-column Plasma App Grid package.")
    parser.add_argument("destination", type=Path, help="New directory for the Plasma widget package")
    destination = parser.parse_args().destination.resolve()

    source = Path(__file__).resolve().parents[1] / "package"
    if destination == source or source in destination.parents:
        parser.error("choose a destination outside the source package")
    if destination.exists():
        parser.error(f"destination already exists: {destination}")

    copytree(source, destination)
    metadata_path = destination / "metadata.json"
    metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
    plugin = metadata["KPlugin"]
    plugin["Id"] += ".six_columns"
    plugin["Name"] += " (6 Columns)"
    metadata_path.write_text(json.dumps(metadata, indent=4, ensure_ascii=False) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
