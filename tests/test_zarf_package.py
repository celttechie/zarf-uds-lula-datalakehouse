import unittest
import os
import yaml

class TestZarfPackage(unittest.TestCase):

    def setUp(self):
        self.repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
        self.zarf_yaml_path = os.path.join(self.repo_root, "zarf.yaml")
        self.zarf_config_path = os.path.join(self.repo_root, "zarf-config.yaml")
        self.chart_dir = os.path.join(self.repo_root, "k8s/charts/datalakehouse")
        self.chart_yaml_path = os.path.join(self.chart_dir, "Chart.yaml")
        self.values_yaml_path = os.path.join(self.chart_dir, "values.yaml")

    def test_zarf_yaml_exists_and_valid(self):
        """Verify zarf.yaml exists and is valid Zarf package YAML structure"""
        self.assertTrue(os.path.exists(self.zarf_yaml_path), "zarf.yaml not found in repository root")
        with open(self.zarf_yaml_path, "r") as f:
            data = yaml.safe_load(f)
        
        self.assertIsInstance(data, dict, "zarf.yaml must parse as a dictionary")
        self.assertEqual(data.get("kind"), "ZarfPackageConfig", "Package kind must be ZarfPackageConfig")
        self.assertIn("metadata", data, "zarf.yaml missing 'metadata' section")
        self.assertIn("components", data, "zarf.yaml missing 'components' section")

    def test_zarf_metadata(self):
        """Verify zarf.yaml metadata fields"""
        with open(self.zarf_yaml_path, "r") as f:
            data = yaml.safe_load(f)
        
        metadata = data.get("metadata", {})
        self.assertEqual(metadata.get("name"), "il5-data-lakehouse")
        self.assertIn("version", metadata, "Metadata must contain version")
        self.assertTrue(metadata.get("version"), "Version must not be empty")
        self.assertIn("description", metadata, "Metadata must contain description")
        self.assertIn("architecture", metadata, "Metadata must contain architecture")

    def test_zarf_components_and_helm_chart(self):
        """Verify components structure, Helm chart references, and local path validity"""
        with open(self.zarf_yaml_path, "r") as f:
            data = yaml.safe_load(f)
        
        components = data.get("components", [])
        self.assertIsInstance(components, list)
        self.assertGreater(len(components), 0, "zarf.yaml must define at least one component")

        # Check datalakehouse-core component
        core_component = next((c for c in components if c.get("name") == "datalakehouse-core"), None)
        self.assertIsNotNone(core_component, "datalakehouse-core component not found in zarf.yaml")
        self.assertTrue(core_component.get("required"), "datalakehouse-core should be required")

        # Validate Helm chart definition
        charts = core_component.get("charts", [])
        self.assertGreater(len(charts), 0, "datalakehouse-core must contain at least one chart")
        lakehouse_chart = next((ch for ch in charts if ch.get("name") == "datalakehouse"), None)
        self.assertIsNotNone(lakehouse_chart, "datalakehouse chart definition not found in component")

        # Validate local chart path
        chart_local_path = os.path.join(self.repo_root, lakehouse_chart.get("localPath", ""))
        self.assertTrue(os.path.isdir(chart_local_path), f"Chart localPath '{chart_local_path}' does not exist")
        self.assertTrue(os.path.exists(os.path.join(chart_local_path, "Chart.yaml")), "Chart.yaml not found in localPath")

        # Verify chart version matches Chart.yaml
        with open(self.chart_yaml_path, "r") as f:
            chart_yaml_data = yaml.safe_load(f)
        self.assertEqual(lakehouse_chart.get("version"), chart_yaml_data.get("version"),
                         "Chart version in zarf.yaml does not match Chart.yaml version")

    def test_zarf_images_match_helm_values(self):
        """Verify that all images in values.yaml are bundled in zarf.yaml with immutable tags"""
        with open(self.values_yaml_path, "r") as f:
            values_data = yaml.safe_load(f)
        
        # Extract images from values.yaml
        expected_images = [
            f"{values_data['minio']['image']['repository']}:{values_data['minio']['image']['tag']}",
            f"{values_data['postgresql']['image']['repository']}:{values_data['postgresql']['image']['tag']}",
            f"{values_data['etlJob']['image']['repository']}:{values_data['etlJob']['image']['tag']}"
        ]

        with open(self.zarf_yaml_path, "r") as f:
            zarf_data = yaml.safe_load(f)

        # Collect all images across components
        zarf_images = []
        for comp in zarf_data.get("components", []):
            zarf_images.extend(comp.get("images", []))

        for img in expected_images:
            self.assertIn(img, zarf_images, f"Image '{img}' from values.yaml missing from zarf.yaml components")

        # Verify no ':latest' unpinned mutable tags
        for img in zarf_images:
            self.assertFalse(img.endswith(":latest"), f"Mutable image tag ':latest' detected in zarf.yaml: {img}")

    def test_zarf_actions_defined(self):
        """Verify Zarf deployment verification actions are defined"""
        with open(self.zarf_yaml_path, "r") as f:
            data = yaml.safe_load(f)
        
        core_component = next((c for c in data.get("components", []) if c.get("name") == "datalakehouse-core"), {})
        actions = core_component.get("actions", {})
        on_deploy = actions.get("onDeploy", {})
        after_actions = on_deploy.get("after", [])
        self.assertGreater(len(after_actions), 0, "Component should define post-deployment verification actions")

    def test_zarf_config_yaml_valid(self):
        """Verify zarf-config.yaml exists and contains valid configuration"""
        self.assertTrue(os.path.exists(self.zarf_config_path), "zarf-config.yaml not found in repository root")
        with open(self.zarf_config_path, "r") as f:
            data = yaml.safe_load(f)
        
        self.assertIsInstance(data, dict, "zarf-config.yaml must parse as a dictionary")
        self.assertIn("package", data, "zarf-config.yaml missing 'package' section")

if __name__ == "__main__":
    unittest.main()
