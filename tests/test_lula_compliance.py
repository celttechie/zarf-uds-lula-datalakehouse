import os
import unittest
import yaml
import subprocess
import re

class TestLulaOSCALCompliance(unittest.TestCase):
    def setUp(self):
        self.repo_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        self.oscal_path = os.path.join(self.repo_root, "oscal-il5.yaml")
        self.exporter_bin = os.path.join(self.repo_root, "bin", "compliance_exporter")

    def test_oscal_file_exists_and_parses(self):
        self.assertTrue(os.path.exists(self.oscal_path), "oscal-il5.yaml must exist in repository root")
        with open(self.oscal_path, "r") as f:
            data = yaml.safe_load(f)
        self.assertIn("component-definition", data)
        comp_def = data["component-definition"]
        self.assertEqual(comp_def["metadata"]["oscal-version"], "1.1.2")

    def test_oscal_uuid_rfc4122_compliance(self):
        uuid_pattern = re.compile(r"^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[45][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$")
        with open(self.oscal_path, "r") as f:
            data = yaml.safe_load(f)
        
        comp_def = data["component-definition"]
        self.assertTrue(uuid_pattern.match(comp_def["uuid"]), f"Invalid root UUID: {comp_def['uuid']}")
        
        for comp in comp_def.get("components", []):
            self.assertTrue(uuid_pattern.match(comp["uuid"]), f"Invalid component UUID: {comp['uuid']}")
            for ci in comp.get("control-implementations", []):
                self.assertTrue(uuid_pattern.match(ci["uuid"]), f"Invalid control-impl UUID: {ci['uuid']}")
                for req in ci.get("implemented-requirements", []):
                    self.assertTrue(uuid_pattern.match(req["uuid"]), f"Invalid req UUID: {req['uuid']}")

    def test_required_nist_controls_present(self):
        required_controls = {"ac-3", "ac-4", "ia-2", "sc-8", "sc-13", "sc-28", "si-4"}
        with open(self.oscal_path, "r") as f:
            data = yaml.safe_load(f)
        
        implemented_controls = set()
        for comp in data["component-definition"].get("components", []):
            for ci in comp.get("control-implementations", []):
                for req in ci.get("implemented-requirements", []):
                    implemented_controls.add(req["control-id"].lower())
        
        missing = required_controls - implemented_controls
        self.assertEqual(len(missing), 0, f"Missing required NIST controls: {missing}")

    def test_compliance_exporter_binary_execution(self):
        if not os.path.exists(self.exporter_bin):
            subprocess.run(["go", "build", "-o", self.exporter_bin, "src/compliance_exporter/main.go"], cwd=self.repo_root, check=True)
        
        result = subprocess.run([self.exporter_bin, self.oscal_path], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, f"Exporter execution failed: {result.stderr}")
        self.assertIn("DoD IMPACT LEVEL 5", result.stdout)

if __name__ == "__main__":
    unittest.main()
