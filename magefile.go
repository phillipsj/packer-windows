//+build mage

package main

import (
	"github.com/phillipsj/packer-windows/buildtools"
	"github.com/magefile/mage/mg"
)

var Default = Validate
var sourceDir = "."
var packer = buildtools.PackerDefault(sourceDir)

func Init() error {
	return packer.Init()
}

func Validate() error {
	mg.Deps(Init)
	return packer.Validate()
}
