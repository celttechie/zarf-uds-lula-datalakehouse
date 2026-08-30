package main

import (
	"fmt"
	"os"
	"strings"
	"time"

	"gopkg.in/yaml.v3"
)

type AssessmentResults struct {
	AssessmentResults struct {
		Metadata struct {
			Title        string `yaml:"title"`
			LastModified string `yaml:"last-modified"`
			Version      string `yaml:"version"`
		} `yaml:"metadata"`
		Results []struct {
			UUID        string `yaml:"uuid"`
			Title       string `yaml:"title"`
			Description string `yaml:"description"`
			Start       string `yaml:"start"`
			Findings    []struct {
				Target struct {
					TargetID string `yaml:"target-id"`
					Status   struct {
						State  string `yaml:"state"`
						Reason string `yaml:"reason"`
					} `yaml:"status"`
				} `yaml:"target"`
				Description string `yaml:"description"`
				Remarks     string `yaml:"remarks"`
			} `yaml:"findings"`
		} `yaml:"results"`
	} `yaml:"assessment-results"`
}

type ControlSummary struct {
	ControlID   string
	Domain      string
	Title       string
	Status      string
	Description string
}

func getControlDetails(id string) (string, string) {
	switch strings.ToLower(id) {
	case "ac-3":
		return "Access Enforcement", "Least Privilege & Non-Root Container Execution"
	case "ac-4":
		return "Information Flow", "Istio PeerAuthentication STRICT mTLS Enforcement"
	case "ia-2":
		return "Ident & Auth", "SPIFFE Cryptographic Workload Identity Attribution"
	case "sc-8":
		return "Transmission Security", "TLS 1.3 Wire-Level Confidentiality & Integrity"
	case "sc-13":
		return "Cryptographic Protection", "Apache Parquet Snappy Compression & Checksum Integrity"
	case "sc-28":
		return "Data at Rest Protection", "Isolated Volume Storage & Immutable S3 Objects"
	case "si-4":
		return "System Monitoring", "Structured Telemetry Logging & Health Probes"
	default:
		return "General Security", "NIST SP 800-53 Rev 5 Baseline Control"
	}
}

func main() {
	inputFile := "assessment-results.yaml"
	if len(os.Args) > 1 {
		inputFile = os.Args[1]
	}

	data, err := os.ReadFile(inputFile)
	if err != nil {
		fmt.Printf("❌ Error reading assessment results file '%s': %v\n", inputFile, err)
		os.Exit(1)
	}

	var results AssessmentResults
	err = yaml.Unmarshal(data, &results)
	if err != nil {
		fmt.Printf("❌ Error parsing OSCAL YAML: %v\n", err)
		os.Exit(1)
	}

	controlList := []string{"ac-3", "ac-4", "ia-2", "sc-8", "sc-13", "sc-28", "si-4"}
	findingMap := make(map[string]string)

	// Check findings from the latest result set in the OSCAL document
	if len(results.AssessmentResults.Results) > 0 {
		latestResult := results.AssessmentResults.Results[0]
		for _, f := range latestResult.Findings {
			cid := strings.ToLower(f.Target.TargetID)
			state := strings.ToLower(f.Target.Status.State)
			if state != "" {
				findingMap[cid] = state
			}
		}
	}

	var summaries []ControlSummary
	satisfiedCount := 0

	for _, cid := range controlList {
		status := findingMap[cid]
		isSatisfied := (status == "satisfied" || status == "pass")

		if isSatisfied {
			status = "SATISFIED"
			satisfiedCount++
		} else if status == "" {
			status = "NOT-EVALUATED"
		} else {
			status = strings.ToUpper(status)
		}

		domain, title := getControlDetails(cid)
		summaries = append(summaries, ControlSummary{
			ControlID:   strings.ToUpper(cid),
			Domain:      domain,
			Title:       title,
			Status:      status,
			Description: title,
		})
	}

	complianceScore := (float64(satisfiedCount) / float64(len(controlList))) * 100.0

	fmt.Println("==========================================================================================")
	fmt.Println("🛡️  DoD IMPACT LEVEL 5 (IL5) CONTINUOUS COMPLIANCE AUDIT MATRIX")
	fmt.Println("==========================================================================================")
	fmt.Printf(" 📋 Evaluation Source: %s\n", inputFile)
	fmt.Printf(" 🕒 Audit Timestamp:   %s\n", time.Now().UTC().Format(time.RFC3339))
	fmt.Printf(" 🎯 Target Framework: NIST SP 800-53 Rev 5 (DoD IL5 Continuous ATO)\n")
	fmt.Printf(" 📊 Compliance Score:  %.1f%% (%d/%d Controls Satisfied)\n", complianceScore, satisfiedCount, len(controlList))
	fmt.Println("------------------------------------------------------------------------------------------")
	fmt.Printf(" %-10s | %-22s | %-44s | %-10s\n", "CONTROL", "DOMAIN", "SECURITY REQUIREMENT", "STATUS")
	fmt.Println("------------------------------------------------------------------------------------------")

	for _, s := range summaries {
		statusIcon := "🟢"
		if s.Status != "SATISFIED" {
			statusIcon = "🟡"
		}
		fmt.Printf(" %-10s | %-22s | %-44s | %s %-8s\n", s.ControlID, s.Domain, s.Title, statusIcon, s.Status)
	}

	fmt.Println("==========================================================================================")
	if complianceScore >= 80.0 {
		fmt.Println("✅ COMPLIANCE POSTURE: PASS - Meets DoD IL5 Baseline Security Authorization Invariants")
	} else {
		fmt.Println("⚠️  COMPLIANCE POSTURE: ACTION REQUIRED - Remediate unsatisfied controls before ATO sign-off")
	}
	fmt.Println("==========================================================================================")
}
