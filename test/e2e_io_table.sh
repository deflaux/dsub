#!/bin/bash

# Copyright 2016 Google Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -o errexit
set -o nounset

# Basic end to end test, driven by a --table file.
#
# This test use the default stock image (ubuntu:14.04).
#
# This test is designed to verify that file input and output path
# headers in a table file work correctly.
#
# The actual operation performed here is to download a BAM and compute
# the md5, writing it to <filename>.bam.md5.
#
# An input file (the BAM) is localized to a subdirectory of the default
# data directory.
# An output file (the MD5) is de-localized from a different subdirectory
# of the default data directory.

readonly SCRIPT_DIR="$(dirname "${0}")"

# Do standard test setup
source "${SCRIPT_DIR}/test_setup_e2e.sh"

if [[ "${CHECK_RESULTS_ONLY:-0}" -eq 0 ]]; then

  echo "Launching pipelines..."

  "${DSUB}" \
    --project "${PROJECT_ID}" \
    --logging "${LOGGING}" \
    --zones "us-central1-*" \
    --script "${SCRIPT_DIR}/script_io_test.sh" \
    --table "${TABLE_FILE}" \
    --wait

fi

echo
echo "Checking output..."

declare -a INPUT_BAMS=(
NA12878.chrom9.SOLID.bfast.CEU.high_coverage.20100125.bam
NA12878.chrom1.LS454.ssaha2.CEU.high_coverage.20100311.bam
NA12878.chrom11.SOLID.corona.SRP000032.2009_08.bam
)

declare -a RESULTS_EXPECTED=(
ef67e2b722761296c4905bb13e130674
2f1048d8993a7c7ee2be3f40b7333a91
63489aa4681bf661ec1541ac0a0565b4
)

for ((i=0; i < ${#INPUT_BAMS[@]}; i++)); do
  INPUT_BAM="${INPUT_BAMS[i]}"
  RESULT_EXPECTED="${RESULTS_EXPECTED[i]}"

  OUTPUT_PATH="$(grep "${INPUT_BAM}" "${TABLE_FILE}" | cut -d $'\t' -f 3)"
  OUTPUT_FILE="${OUTPUT_PATH%/*.md5}/$(basename "${INPUT_BAM}").md5"
  RESULT="$(gsutil cat "${OUTPUT_FILE}")"

  if ! diff <(echo "${RESULT_EXPECTED}") <(echo "${RESULT}"); then
    echo "Output file does not match expected"
    exit 1
  fi

  echo
  echo "Output file matches expected:"
  echo "*****************************"
  echo "${RESULT}"
  echo "*****************************"
done

echo "SUCCESS"
