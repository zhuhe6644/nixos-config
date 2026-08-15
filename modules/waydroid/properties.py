"""Force a set of Android properties into Waydroid's mutable state.

Invoked as `properties.py <json-file>`, where the JSON is a flat {key: value}
map. Writes both files that can carry an override:

  * waydroid.cfg [properties] - merged over the autodetected values whenever
    `waydroid init` or `waydroid upgrade` regenerates the base props, so the
    overrides survive a regeneration.
  * waydroid_base.prop        - read verbatim when the container starts, so
    writing it directly makes the overrides effective without an upgrade run.
"""

import configparser
import json
import os
import sys

WORK = "/var/lib/waydroid"

with open(sys.argv[1]) as handle:
    properties = json.load(handle)

config_path = os.path.join(WORK, "waydroid.cfg")
config = configparser.ConfigParser(interpolation=None)
config.read(config_path)
if not config.has_section("properties"):
    config.add_section("properties")
for key, value in properties.items():
    config.set("properties", key, value)
with open(config_path, "w") as handle:
    config.write(handle)

prop_path = os.path.join(WORK, "waydroid_base.prop")
lines = []
if os.path.exists(prop_path):
    with open(prop_path) as handle:
        lines = [
            line
            for line in handle.read().splitlines()
            if line.partition("=")[0] not in properties
        ]
lines += [f"{key}={value}" for key, value in properties.items()]
with open(prop_path, "w") as handle:
    handle.write("\n".join(lines) + "\n")
