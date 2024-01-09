import yaml
import sys

yaml_path = sys.argv[1]
ext = len(sys.argv) > 2 and sys.argv[2] == "ext" 

data = {}
with open(yaml_path, "r") as f:
    data = yaml.safe_load(f)

if ext:
    print(data["commit"])
    exit(0)

sources = []

if "modules" in data:
    for module in data["modules"]:
        if "name" in module and module["name"] == "Inochi-Creator":
            if "sources" in module:
                sources = module["sources"]
                break

for source in sources:
    if "type" in source and source["type"] == "git":
        if "url" in source and "inochi-creator" in source["url"]:
            if "commit" in source:
                print(source["commit"])
                break
