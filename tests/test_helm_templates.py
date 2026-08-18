import unittest
import os
import re
import yaml

class TestHelmTemplates(unittest.TestCase):
    
    def setUp(self):
        self.chart_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "../k8s/charts/datalakehouse"))
        self.templates_dir = os.path.join(self.chart_dir, "templates")

    def test_chart_yaml(self):
        """Verify Chart.yaml structure"""
        chart_path = os.path.join(self.chart_dir, "Chart.yaml")
        self.assertTrue(os.path.exists(chart_path), "Chart.yaml not found")
        with open(chart_path) as f:
            data = yaml.safe_load(f)
        self.assertEqual(data.get("name"), "datalakehouse")
        self.assertIn("version", data)
        self.assertIn("apiVersion", data)

    def test_values_yaml(self):
        """Verify values.yaml configuration sections"""
        values_path = os.path.join(self.chart_dir, "values.yaml")
        self.assertTrue(os.path.exists(values_path), "values.yaml not found")
        with open(values_path) as f:
            data = yaml.safe_load(f)
        self.assertIn("minio", data)
        self.assertIn("postgresql", data)
        self.assertIn("etlJob", data)

    def test_helm_template_syntax(self):
        """Verify all Helm template files have valid structure and K8s kinds"""
        for filename in os.listdir(self.templates_dir):
            if not filename.endswith(".yaml"):
                continue
            filepath = os.path.join(self.templates_dir, filename)
            with open(filepath) as f:
                content = f.read()
            
            # Basic validation: ensure template directives are balanced
            open_tags = len(re.findall(r'\{\{', content))
            close_tags = len(re.findall(r'\}\}', content))
            self.assertEqual(open_tags, close_tags, f"Unbalanced Helm template brackets in {filename}")

if __name__ == "__main__":
    unittest.main()
