import os.path
import yaml
import json

directory = os.path.dirname(__file__)
fn_in = os.path.join(directory, "test_docs.yml")
fn_out = os.path.join(directory, "..", "js", "specs_test_docs.js")

with open(fn_in) as f_in:
    with open(fn_out, "w") as f_out:
        docs = yaml.load(f_in)
        f_out.write("var test_docs = ");
        json.dump(docs, f_out);
        f_out.write(";\n")
