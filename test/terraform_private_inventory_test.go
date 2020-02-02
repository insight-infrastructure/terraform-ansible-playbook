package test



import (
	"fmt"
	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"log"
	"os"
	"path"
	"testing"
)

func TestTerraformPlaybookPrivateInventory(t *testing.T)  {
	t.Parallel()

	exampleFolder := test_structure.CopyTerraformFolderToTemp(t, "../", "examples/private-inventory")
	uniqueID := random.UniqueId()
	instanceName := fmt.Sprintf("terratest-private-%s", uniqueID)
	awsRegion := aws.GetRandomStableRegion(t, nil, nil)

	cwd, err :=  os.Getwd()
	if err != nil {
		log.Println(err)
	}

	fixturesDir := path.Join(cwd, "fixtures")

	terraformOptions := &terraform.Options{
		TerraformDir: exampleFolder,

		Vars: map[string]interface{}{
			"aws_region":    awsRegion,
			"instance_name": instanceName,
			"public_key_path" :  path.Join(fixturesDir, "keys", "testing.pub"),
			"private_key_path" : path.Join(fixturesDir, "keys", "testing"),
			"user": "ubuntu",
			"playbook_file_path" : path.Join(fixturesDir, "ansible", "basic.yml"),

		},
	}

	defer test_structure.RunTestStage(t, "teardown", func() {
		terraform.Destroy(t, terraformOptions)
	})

	test_structure.RunTestStage(t, "setup", func() {
		terraform.InitAndApply(t, terraformOptions)
	})
}