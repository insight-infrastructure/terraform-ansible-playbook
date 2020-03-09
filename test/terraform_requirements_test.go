package test

import (
	"fmt"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"log"
	"os"
	"path"
	"testing"
)

func TestTerraformPlaybookRequirements(t *testing.T) {
	t.Parallel()

	exampleFolder := test_structure.CopyTerraformFolderToTemp(t, "../", "examples/requirements")
	uniqueID := random.UniqueId()
	instanceName := fmt.Sprintf("terratest-private-%s", uniqueID)
	//awsRegion := aws.GetRandomStableRegion(t, nil, nil)

	cwd, err := os.Getwd()
	if err != nil {
		log.Println(err)
	}

	fixturesDir := path.Join(cwd, "fixtures")

	privateKeyPath := path.Join(fixturesDir, "./keys/id_rsa_test")
	publicKeyPath := path.Join(fixturesDir, "./keys/id_rsa_test.pub")
	generateKeys(privateKeyPath, publicKeyPath)

	terraformOptions := &terraform.Options{
		TerraformDir: exampleFolder,
		Vars: map[string]interface{}{
			//"aws_region":         awsRegion,
			"aws_region":         "us-east-1",
			"instance_name":      instanceName,
			"public_key_path":    publicKeyPath,
			"private_key_path":   privateKeyPath,
			"user":               "ubuntu",
			"playbook_file_path": path.Join(fixturesDir, "ansible", "requirements-playbook.yml"),
			"create": true,
		},
	}

	defer test_structure.RunTestStage(t, "teardown", func() {
		terraform.Destroy(t, terraformOptions)
	})

	test_structure.RunTestStage(t, "setup", func() {
		terraform.InitAndApply(t, terraformOptions)
	})
}
