import os
import unittest
import subprocess

class TestAccreditationPackageGeneration(unittest.TestCase):
    def setUp(self):
        self.repo_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        self.accreditation_dir = os.path.join(self.repo_root, "docs", "accreditation")
        self.generator_script = os.path.join(self.repo_root, "scripts", "generate_ato_package.py")

    def test_generator_script_execution(self):
        result = subprocess.run(["python3", self.generator_script], capture_output=True, text=True, cwd=self.repo_root)
        self.assertEqual(result.returncode, 0, f"Generator failed: {result.stderr}")
        self.assertIn("ACCREDITATION ARTIFACT PACKAGE GENERATED", result.stdout)

    def test_required_accreditation_documents_exist(self):
        required_files = [
            "01_System_Security_Plan_SSP.md",
            "02_Security_Assessment_Report_SAR.md",
            "03_Continuous_Monitoring_Plan_ConMon.md",
            "04_Plan_of_Action_and_Milestones_POAM.md",
            "README.md"
        ]
        for fname in required_files:
            fpath = os.path.join(self.accreditation_dir, fname)
            self.assertTrue(os.path.exists(fpath), f"Missing required ATO document: {fname}")
            self.assertGreater(os.path.getsize(fpath), 100, f"ATO document {fname} is unexpectedly empty")

    def test_ssp_contains_all_nist_controls(self):
        ssp_path = os.path.join(self.accreditation_dir, "01_System_Security_Plan_SSP.md")
        with open(ssp_path, "r") as f:
            content = f.read().upper()
        
        required_controls = ["AC-3", "AC-4", "IA-2", "SC-8", "SC-13", "SC-28", "SI-4"]
        for cid in required_controls:
            self.assertIn(f"CONTROL {cid}", content, f"SSP missing section for control: {cid}")

    def test_sar_contains_assessment_verdicts(self):
        sar_path = os.path.join(self.accreditation_dir, "02_Security_Assessment_Report_SAR.md")
        with open(sar_path, "r") as f:
            content = f.read()
        
        self.assertIn("PASS / APPROVED FOR ATO", content)
        self.assertIn("Continuous Authorization to Operate", content)

if __name__ == "__main__":
    unittest.main()
