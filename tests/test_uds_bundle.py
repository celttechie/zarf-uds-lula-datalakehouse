import unittest
import os
import yaml

class TestUDSBundle(unittest.TestCase):

    def setUp(self):
        self.repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
        self.uds_bundle_path = os.path.join(self.repo_root, "uds-bundle.yaml")
        self.uds_config_path = os.path.join(self.repo_root, "uds-config.yaml")
        self.zarf_yaml_path = os.path.join(self.repo_root, "zarf.yaml")
        self.peer_auth_path = os.path.join(self.repo_root, "k8s/mesh/peer-authentication.yaml")
        self.authz_policy_path = os.path.join(self.repo_root, "k8s/mesh/authorization-policy.yaml")

    def test_uds_bundle_yaml_exists_and_valid(self):
        """Verify uds-bundle.yaml exists and is a valid UDSBundle definition"""
        self.assertTrue(os.path.exists(self.uds_bundle_path), "uds-bundle.yaml not found in repository root")
        with open(self.uds_bundle_path, "r") as f:
            data = yaml.safe_load(f)

        self.assertIsInstance(data, dict, "uds-bundle.yaml must parse as a dictionary")
        self.assertEqual(data.get("kind"), "UDSBundle", "Bundle kind must be UDSBundle")
        self.assertIn("metadata", data, "uds-bundle.yaml missing 'metadata' section")
        self.assertIn("packages", data, "uds-bundle.yaml missing 'packages' section")

    def test_uds_bundle_metadata(self):
        """Verify uds-bundle.yaml metadata properties"""
        with open(self.uds_bundle_path, "r") as f:
            data = yaml.safe_load(f)

        metadata = data.get("metadata", {})
        self.assertEqual(metadata.get("name"), "il5-data-lakehouse-bundle")
        self.assertEqual(metadata.get("version"), "0.4.0")
        self.assertEqual(metadata.get("architecture"), "amd64")
        self.assertIn("description", metadata)
        self.assertTrue(metadata.get("description"))
        self.assertIn("authors", metadata)

    def test_uds_bundle_packages_and_overrides(self):
        """Verify package definitions and component overrides for datalakehouse"""
        with open(self.uds_bundle_path, "r") as f:
            data = yaml.safe_load(f)

        packages = data.get("packages", [])
        self.assertIsInstance(packages, list)
        self.assertGreater(len(packages), 0, "uds-bundle.yaml must define at least one package")

        # Check il5-data-lakehouse package
        dlh_pkg = next((p for p in packages if p.get("name") == "il5-data-lakehouse"), None)
        self.assertIsNotNone(dlh_pkg, "il5-data-lakehouse package reference not found in uds-bundle.yaml")
        self.assertEqual(dlh_pkg.get("path"), ".")
        self.assertEqual(dlh_pkg.get("namespace"), "datalakehouse")

        # Check overrides
        overrides = dlh_pkg.get("overrides", {})
        self.assertIn("datalakehouse-core", overrides, "datalakehouse-core component override missing")

        core_overrides = overrides["datalakehouse-core"]
        self.assertIn("datalakehouse", core_overrides, "datalakehouse chart override missing")

        chart_overrides = core_overrides["datalakehouse"]
        values = chart_overrides.get("values", [])
        value_paths = {v.get("path"): v.get("value") for v in values}
        self.assertEqual(value_paths.get("minio.enabled"), True)
        self.assertEqual(value_paths.get("postgresql.enabled"), True)
        self.assertEqual(value_paths.get("etlJob.enabled"), True)

    def test_uds_config_yaml_valid(self):
        """Verify uds-config.yaml structure and configuration parameters"""
        self.assertTrue(os.path.exists(self.uds_config_path), "uds-config.yaml not found in repository root")
        with open(self.uds_config_path, "r") as f:
            config = yaml.safe_load(f)

        self.assertIsInstance(config, dict, "uds-config.yaml must parse as a dictionary")
        self.assertIn("variables", config, "uds-config.yaml missing 'variables' section")

        dlh_vars = config["variables"].get("il5-data-lakehouse", {})
        self.assertEqual(dlh_vars.get("NAMESPACE"), "datalakehouse")
        self.assertEqual(dlh_vars.get("DOMAIN"), "datalake.local")
        self.assertEqual(dlh_vars.get("STORAGE_CLASS"), "local-path")
        self.assertEqual(dlh_vars.get("SECURITY_PROFILE"), "il5-strict")

    def test_istio_peer_authentication_manifest(self):
        """Verify Istio PeerAuthentication enforces STRICT mTLS in datalakehouse namespace"""
        self.assertTrue(os.path.exists(self.peer_auth_path), "peer-authentication.yaml not found in k8s/mesh/")
        with open(self.peer_auth_path, "r") as f:
            manifest = yaml.safe_load(f)

        self.assertIsInstance(manifest, dict)
        self.assertEqual(manifest.get("kind"), "PeerAuthentication")
        self.assertIn(manifest.get("apiVersion"), ["security.istio.io/v1beta1", "security.istio.io/v1"])

        metadata = manifest.get("metadata", {})
        self.assertEqual(metadata.get("namespace"), "datalakehouse")

        spec = manifest.get("spec", {})
        mtls = spec.get("mtls", {})
        self.assertEqual(mtls.get("mode"), "STRICT", "Istio PeerAuthentication must enforce STRICT mTLS mode")

    def test_istio_authorization_policy_manifest(self):
        """Verify Istio AuthorizationPolicy manifest configures zero-trust access control"""
        self.assertTrue(os.path.exists(self.authz_policy_path), "authorization-policy.yaml not found in k8s/mesh/")
        with open(self.authz_policy_path, "r") as f:
            manifest = yaml.safe_load(f)

        self.assertIsInstance(manifest, dict)
        self.assertEqual(manifest.get("kind"), "AuthorizationPolicy")
        self.assertIn(manifest.get("apiVersion"), ["security.istio.io/v1beta1", "security.istio.io/v1"])

        metadata = manifest.get("metadata", {})
        self.assertEqual(metadata.get("namespace"), "datalakehouse")

        spec = manifest.get("spec", {})
        self.assertEqual(spec.get("action"), "ALLOW")

        rules = spec.get("rules", [])
        self.assertGreater(len(rules), 0, "AuthorizationPolicy must define least-privilege access rules")

        # Verify allowed ports (MinIO S3: 9000/9001, Postgres: 5432)
        all_ports = []
        for rule in rules:
            for to_op in rule.get("to", []):
                all_ports.extend(to_op.get("operation", {}).get("ports", []))

        self.assertIn("9000", all_ports, "MinIO API port 9000 must be secured via AuthorizationPolicy")
        self.assertIn("9001", all_ports, "MinIO Console port 9001 must be secured via AuthorizationPolicy")
        self.assertIn("5432", all_ports, "PostgreSQL port 5432 must be secured via AuthorizationPolicy")

    def test_uds_zarf_package_compatibility(self):
        """Verify component and namespace alignment between uds-bundle.yaml and zarf.yaml"""
        with open(self.uds_bundle_path, "r") as f:
            uds_data = yaml.safe_load(f)
        with open(self.zarf_yaml_path, "r") as f:
            zarf_data = yaml.safe_load(f)

        # Ensure datalakehouse-core component exists in zarf.yaml
        zarf_components = [c.get("name") for c in zarf_data.get("components", [])]
        dlh_pkg = next(p for p in uds_data.get("packages", []) if p.get("name") == "il5-data-lakehouse")
        overridden_components = list(dlh_pkg.get("overrides", {}).keys())

        for comp in overridden_components:
            self.assertIn(comp, zarf_components, f"Overridden component '{comp}' in UDS bundle does not exist in zarf.yaml")

        # Ensure namespace match
        self.assertEqual(dlh_pkg.get("namespace"), "datalakehouse")

    def test_uds_local_package_excludes_repository(self):
        """Verify local package in UDS bundle does not declare conflicting repository field"""
        with open(self.uds_bundle_path, "r") as f:
            uds_data = yaml.safe_load(f)
        for pkg in uds_data.get("packages", []):
            if "path" in pkg:
                self.assertNotIn("repository", pkg, f"Package '{pkg.get('name')}' declares both 'path' and 'repository'")

    def test_uds_bundle_authors_is_string(self):
        """Verify authors field in UDS bundle metadata is a string, not a list"""
        with open(self.uds_bundle_path, "r") as f:
            uds_data = yaml.safe_load(f)
        authors = uds_data.get("metadata", {}).get("authors")
        self.assertIsInstance(authors, str, "UDS Bundle metadata.authors must be a string")

    def test_uds_config_overlays_valid(self):
        """Verify cloud configuration overlays (AWS K3s and AWS EKS) exist and specify correct storage classes"""
        k3s_cfg_path = os.path.join(self.repo_root, "uds-config-aws-k3s.yaml")
        eks_cfg_path = os.path.join(self.repo_root, "uds-config-aws-eks.yaml")

        self.assertTrue(os.path.exists(k3s_cfg_path), "uds-config-aws-k3s.yaml missing")
        self.assertTrue(os.path.exists(eks_cfg_path), "uds-config-aws-eks.yaml missing")

        with open(k3s_cfg_path) as f:
            k3s_data = yaml.safe_load(f)
        with open(eks_cfg_path) as f:
            eks_data = yaml.safe_load(f)

        self.assertEqual(k3s_data["variables"]["il5-data-lakehouse"]["STORAGE_CLASS"], "local-path")
        self.assertEqual(eks_data["variables"]["il5-data-lakehouse"]["STORAGE_CLASS"], "gp3")
        self.assertEqual(eks_data["shared"]["STORAGE_CLASS"], "gp3")

if __name__ == "__main__":
    unittest.main()
