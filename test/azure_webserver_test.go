package test

import (
    "testing"

    "github.com/gruntwork-io/terratest/modules/azure"
    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/stretchr/testify/assert"
)

// Updated with your actual Azure subscription ID
var subscriptionID string = "e415d340-1457-4f20-9088-b1fca5e591f1"

func TestAzureLinuxVMCreation(t *testing.T) {
    terraformOptions := &terraform.Options{
        // The path to where our Terraform code is located
        TerraformDir: "../",
        // Override the default terraform variables
        Vars: map[string]interface{}{
            "labelPrefix": "hoss0113",       // Your college ID
            "region":      "eastus",         // Forces East US to bypass the WestUS3 capacity issue!
        },
    }

    defer terraform.Destroy(t, terraformOptions)

    // Run `terraform init` and `terraform apply`. Fail the test if there are any errors.
    terraform.InitAndApply(t, terraformOptions)

    // Run `terraform output` to get the value of output variables
    // Note: We don't have a "vm_name" output in outputs.tf, so we construct it the same way main.tf does.
    vmName := "hoss0113-webserver" 
    resourceGroupName := terraform.Output(t, terraformOptions, "resource_group_name")

    // Confirm VM exists
    assert.True(t, azure.VirtualMachineExists(t, vmName, resourceGroupName, subscriptionID))
}