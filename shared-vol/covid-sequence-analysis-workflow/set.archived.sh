#!/usr/bin/env bash

dataset_name=${1:-'sarscov2_metadata'}
project_id=${2:-'prj-int-dev-covid19-nf-gls'}

# DIR where the current script resides
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

output_dir="${DIR}/results"; mkdir -p "${output_dir}"

###########################################################
# Get all analyses archived under parent_study = PRJEB45555: PRJEB55347, PRJEB55357
###########################################################
echo ""
echo "** Updating ${dataset_name}.analysis_archived table. **"

curl -X POST -H "Content-Type: application/x-www-form-urlencoded" -d 'result=analysis&query=parent_study%3D%22PRJEB55347%22&fields=sample_accession%2Crun_ref%2Canalysis_date%2Csubmitted_bytes&format=tsv&limit=0' \
  "https://www.ebi.ac.uk/ena/portal/api/search" > "${output_dir}/analysis_archived.tsv"
gsutil -m cp "${output_dir}/analysis_archived.tsv" "gs://${dataset_name}/analysis_archived.tsv" && \
  bq --project_id="${project_id}" load --source_format=CSV --replace=true --skip_leading_rows=1 --field_delimiter=tab \
  --autodetect "${dataset_name}.analysis_archived" "gs://${dataset_name}/analysis_archived.tsv" \
  "analysis_accession:STRING,sample_accession:STRING,run_ref:STRING,analysis_date:DATE,submitted_bytes:NUMERIC"
curl -X POST -H "Content-Type: application/x-www-form-urlencoded" -d 'result=analysis&query=parent_study%3D%22PRJEB55357%22&fields=sample_accession%2Crun_ref%2Canalysis_date%2Csubmitted_bytes&format=tsv&limit=0' \
  "https://www.ebi.ac.uk/ena/portal/api/search" > "${output_dir}/analysis_archived.tsv"
gsutil -m cp "${output_dir}/analysis_archived.tsv" "gs://${dataset_name}/analysis_archived.tsv" && \
  bq --project_id="${project_id}" load --source_format=CSV --replace=false --skip_leading_rows=1 --field_delimiter=tab \
  --autodetect "${dataset_name}.analysis_archived" "gs://${dataset_name}/analysis_archived.tsv" \
  "analysis_accession:STRING,sample_accession:STRING,run_ref:STRING,analysis_date:DATE,submitted_bytes:NUMERIC"

#################################
# delete runs from sra_processing
#################################
echo ""
echo "** Updating ${dataset_name}.sra_processing table. **"

sql="DELETE FROM ${dataset_name}.sra_processing T1 WHERE T1.run_accession IN (SELECT T2.run_accession FROM ${dataset_name}.submission_metadata T2) OR T1.run_accession IN (SELECT T3.run_ref FROM ${dataset_name}.analysis_archived T3)"
bq --project_id="${project_id}" --format=csv query --use_legacy_sql=false "${sql}"
