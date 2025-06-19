#!/bin/bash

tuist generate
cd Example/ && pod install

# Before use it, in the first time, you must guarantee some running permissions:
# chmod +x run.sh
#
# After that, you just need to run:
# ./run.sh