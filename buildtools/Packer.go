package buildtools

import (
	"log"
	"os"
	"strings"

	"github.com/magefile/mage/sh"
)

type Packer struct {
	Directory string
	Extension string
}

func PackerDefault(dir string) *Packer {
	return &Packer{
		Directory: dir,
		Extension: ".pkr.hcl",
	}
}

func (p *Packer) Init() error {
	files, err := getPackerFiles(p.Directory, p.Extension)
	if err != nil {
		log.Fatal(err)
	}
	for _, file := range files {
		if err := sh.Run("packer", "init", file); err != nil {
			return err
		}
	}
	return nil
}

func (p *Packer) Validate() error {
	files, err := getPackerFiles(p.Directory, p.Extension)
	if err != nil {
		log.Fatal(err)
	}
	for _, file := range files {
		if err := sh.Run("packer", "validate", file); err != nil {
			return err
		}
	}
	return nil
}

func getPackerFiles(d string, e string) ([]string, error) {
	var pf []string
	f, err := os.Open(d)
	if err != nil {
		return nil, err
	}
	files, err := f.Readdir(-1)
	f.Close()
	if err != nil {
		return nil, err
	}

	for _, file := range files {
		if strings.Contains(file.Name(), e) {
			pf = append(pf, file.Name())
		}
	}

	return pf, nil
}
