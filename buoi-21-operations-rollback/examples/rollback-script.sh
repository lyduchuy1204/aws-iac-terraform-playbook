#!/usr/bin/env bash
# rollback-script.sh — backup state, restore version cũ từ S3, plan trước khi apply.
#
# Cách dùng:
#   ./rollback-script.sh <state-bucket> <state-key> [old-version-id]
#
# - <state-bucket>: tên S3 bucket lưu Terraform state.
# - <state-key>: key (path) trong bucket, ví dụ envs/dev/terraform.tfstate.
# - <old-version-id>: VersionId muốn restore. Nếu bỏ trống, script sẽ list ra để bạn chọn.
#
# Yêu cầu: aws CLI v2 đã configure đúng account, jq cài sẵn, terraform >= 1.11.

set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <state-bucket> <state-key> [old-version-id]" >&2
  exit 1
fi

BUCKET="$1"
KEY="$2"
VERSION_ID="${3:-}"

TS="$(date +%Y%m%d-%H%M%S)"
LOCAL_BACKUP="state-backup-${TS}.tfstate"

echo "==> [1/5] Backup state HIỆN TẠI từ S3 về local: ${LOCAL_BACKUP}"
aws s3 cp "s3://${BUCKET}/${KEY}" "${LOCAL_BACKUP}"

# Backup luôn qua terraform CLI (đảm bảo state đang load đúng).
if command -v terraform >/dev/null 2>&1; then
  echo "==> [1b/5] Backup thêm bằng terraform state pull"
  terraform state pull > "state-pull-${TS}.tfstate" || echo "(bỏ qua nếu chưa init)"
fi

if [[ -z "${VERSION_ID}" ]]; then
  echo "==> [2/5] Liệt kê version cũ của object (chọn 1 VersionId rồi chạy lại với arg thứ 3):"
  aws s3api list-object-versions \
    --bucket "${BUCKET}" \
    --prefix "${KEY}" \
    --output table \
    --query 'Versions[].{VersionId:VersionId,LastModified:LastModified,IsLatest:IsLatest,Size:Size}'
  exit 0
fi

echo "==> [3/5] Restore version ${VERSION_ID} của ${KEY} (copy đè làm version mới)"
aws s3api copy-object \
  --bucket "${BUCKET}" \
  --key "${KEY}" \
  --copy-source "${BUCKET}/${KEY}?versionId=${VERSION_ID}" \
  --metadata-directive COPY

echo "==> [4/5] terraform init -reconfigure + plan để xem diff"
terraform init -reconfigure -input=false -no-color
terraform plan -no-color -out=rollback.tfplan

echo
echo "==> [5/5] Đọc kỹ plan ở trên."
echo "    Nếu OK, chạy:  terraform apply rollback.tfplan"
echo "    Nếu KHÔNG OK, restore lại bản ${LOCAL_BACKUP} bằng:"
echo "      aws s3 cp ${LOCAL_BACKUP} s3://${BUCKET}/${KEY}"
