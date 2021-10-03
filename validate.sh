#!/bin/bash

for template in $(ls -1 *.pkr.hcl); do
  echo $template
  packer validate $template
done
