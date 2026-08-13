package main

import (
	"encoding/json"
	"fmt"
	"os"
)

// OSCALResult represents the Lula evaluation result output structure
type OSCALResult struct {
	UUID     string `json:"uuid"`
	Title    string `json:"title"`
	Results []struct {
		UUID                   string `json:"uuid"`
		Title                  string `json:"title"`
		Passing                bool   `json:"passing"`
		ControlImplementations []struct {
			ImplementedRequirements []struct {
				ControlID   string `json:"control-id"`
				Description string `json:"description"`
				Passing     bool   `json:"passing"`
			} `json:"implemented-requirements"`
		} `json:"control-implementation"`
	} `json:"results"`
}

func main() {
	filePath := "il5-results.json"
	if len(os.Args) > 1 {
		filePath = os.Args[1]
	}

	data, err := os.ReadFile(filePath)
	if err != nil {
		fmt.Printf("⚠️  Could not read assessment file '%s': %v\n", filePath, err)
		os.Exit(1)
	}

	var assessment OSCALResult
	if err := json.Unmarshal(data, &assessment); err != nil {
		fmt.Printf("❌ Failed to parse OSCAL JSON: %v\n", err)
		os.Exit(1)
	}

	fmt.Println("==========================================================")
	fmt.Println("🛡️   LULA OSCAL COMPLIANCE PARSER (GOLANG EXPORTER)        🛡️")
	fmt.Println("==========================================================")

	for _, res := range assessment.Results {
		statusStr := "❌ FAIL"
		if res.Passing {
			statusStr = "✅ PASS"
		}
		fmt.Printf("Assessment: %s [%s]\n\n", res.Title, statusStr)

		for _, ctrlImpl := range res.ControlImplementations {
			for _, req := range ctrlImpl.ImplementedRequirements {
				reqStatus := "FAIL"
				if req.Passing {
					reqStatus = "PASS"
				}
				fmt.Printf("  • Control [%s]: %s -> Status: %s\n", req.ControlID, req.Description, reqStatus)
			}
		}
	}
	fmt.Println("==========================================================")
}
