#!/usr/bin/env bash
set -euo pipefail

PROJECT_REF="znmfjbyvmiumctouolde"
PROJECT_URL="https://${PROJECT_REF}.supabase.co"
DIRECT_DB_HOST="db.${PROJECT_REF}.supabase.co"
BACKUP_ROOT="${HOME}/supabase_backup_${PROJECT_REF}_$(date +%Y%m%d_%H%M%S)"

need() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Thiếu lệnh: $1"
    echo "Cài bằng: brew install supabase/tap/supabase postgresql jq awscli"
    exit 1
  }
}

need supabase
need psql
need pg_dump
need jq
need aws
need shasum
need tar

echo "==> Backup sẽ lưu tại:"
echo "    $BACKUP_ROOT"
mkdir -p "$BACKUP_ROOT"/{database,functions,storage/objects,project_meta,workdir}

read -rsp "Nhập Database password: " DB_PASSWORD
echo

encoded_password=$(jq -rn --arg val "$DB_PASSWORD" '$val|@uri')

export SUPABASE_DB_PASSWORD="$DB_PASSWORD"
export PGPASSWORD="$DB_PASSWORD"
export DB_URL="postgresql://postgres.${PROJECT_REF}:${encoded_password}@aws-1-ap-northeast-2.pooler.supabase.com:5432/postgres"

cat > "$BACKUP_ROOT/project_meta/project_info.txt" <<EOF
PROJECT_REF=$PROJECT_REF
PROJECT_URL=$PROJECT_URL
DIRECT_DB_HOST=$DIRECT_DB_HOST
BACKUP_CREATED_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
EOF

cd "$BACKUP_ROOT/workdir"

echo "==> Khởi tạo workdir Supabase local"
supabase init >/dev/null 2>&1 || true

echo "==> Link project"
supabase link --project-ref "$PROJECT_REF"

echo "==> Bỏ qua supabase db pull vì migration history đang mismatch"
mkdir -p "$BACKUP_ROOT/project_meta/migrations_from_db_pull"
echo "db pull skipped due to migration history mismatch" > "$BACKUP_ROOT/project_meta/migrations_from_db_pull/README.txt"
if [ -f supabase/config.toml ]; then
  cp supabase/config.toml "$BACKUP_ROOT/project_meta/config.toml"
fi

echo "==> Dump roles / schema / data phần app"
supabase db dump --db-url "$DB_URL" -f "$BACKUP_ROOT/database/roles.sql" --role-only
supabase db dump --db-url "$DB_URL" -f "$BACKUP_ROOT/database/schema.sql"
supabase db dump --db-url "$DB_URL" -f "$BACKUP_ROOT/database/data.sql" --use-copy --data-only -x "storage.buckets_vectors" -x "storage.vector_indexes"

echo "==> Dump auth schema / data"
if ! supabase db dump --db-url "$DB_URL" -f "$BACKUP_ROOT/database/auth_schema.sql" --schema auth; then
  echo "supabase db dump auth schema thất bại, fallback sang pg_dump..."
  pg_dump "$DB_URL" --schema=auth --schema-only > "$BACKUP_ROOT/database/auth_schema.sql"
fi

if ! supabase db dump --db-url "$DB_URL" -f "$BACKUP_ROOT/database/auth_data.sql" --use-copy --data-only --schema auth; then
  echo "supabase db dump auth data thất bại, fallback sang pg_dump..."
  pg_dump "$DB_URL" --schema=auth --data-only > "$BACKUP_ROOT/database/auth_data.sql"
fi

echo "==> Dump migration history"
supabase db dump --db-url "$DB_URL" -f "$BACKUP_ROOT/database/history_schema.sql" --schema supabase_migrations
supabase db dump --db-url "$DB_URL" -f "$BACKUP_ROOT/database/history_data.sql" --use-copy --data-only --schema supabase_migrations

echo "==> Diff các thay đổi custom trong auth/storage"
if ! supabase db diff --linked --schema auth,storage > "$BACKUP_ROOT/database/changes_auth_storage.sql"; then
  echo "-- Không tạo được diff auth/storage trên CLI hiện tại" > "$BACKUP_ROOT/database/changes_auth_storage.sql"
fi

echo "==> Export bucket metadata"
psql "$DB_URL" -Atqc "select row_to_json(b) from (select * from storage.buckets order by name) b;" > "$BACKUP_ROOT/storage/buckets.ndjson"

echo "==> List và download Edge Functions"
if supabase functions list --project-ref "$PROJECT_REF" -o json > "$BACKUP_ROOT/functions/functions_list.json"; then
  :
else
  echo "[]" > "$BACKUP_ROOT/functions/functions_list.json"
fi

rm -rf supabase/functions
mkdir -p supabase/functions
if supabase functions download --project-ref "$PROJECT_REF" --use-api; then
  if [ -d supabase/functions ]; then
    cp -R supabase/functions "$BACKUP_ROOT/functions/source"
  fi
else
  mkdir -p "$BACKUP_ROOT/functions/source"
fi

echo "==> Lưu inventory Edge Function secrets"
if supabase secrets list --project-ref "$PROJECT_REF" -o json > "$BACKUP_ROOT/project_meta/secrets_inventory.json"; then
  :
else
  echo "[]" > "$BACKUP_ROOT/project_meta/secrets_inventory.json"
fi

cat > "$BACKUP_ROOT/project_meta/functions_secrets.env.template" <<'EOF'
# Dán lại các secret values thật của Edge Functions vào đây.
# Sau này restore:
# supabase secrets set --env-file functions_secrets.env.template --project-ref NEW_PROJECT_REF
EOF

echo "==> Backup Storage objects về local"
echo "Chuẩn bị 3 giá trị từ Dashboard > Storage > S3 access keys / settings:"
echo "(Nhấn Enter để trống phần Access Key ID nếu muốn BỎ QUA backup Storage)"
read -rp "S3 Access Key ID: " AWS_ACCESS_KEY_ID

if [ -z "$AWS_ACCESS_KEY_ID" ]; then
  echo "==> Bỏ qua backup Storage objects theo yêu cầu."
else
  read -rsp "S3 Secret Access Key: " AWS_SECRET_ACCESS_KEY
  echo
  read -rp "S3 Region [ap-northeast-2]: " AWS_DEFAULT_REGION
  AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-ap-northeast-2}"

  export AWS_ACCESS_KEY_ID
  export AWS_SECRET_ACCESS_KEY
  export AWS_DEFAULT_REGION
  export AWS_EC2_METADATA_DISABLED=true

  BUCKET_FILE="$BACKUP_ROOT/storage/buckets.ndjson"
  if [ ! -s "$BUCKET_FILE" ]; then
    echo "Không có bucket nào."
  else
    while IFS= read -r line; do
      [ -z "$line" ] && continue
      bucket="$(printf '%s' "$line" | jq -r '.name')"
      [ -z "$bucket" ] && continue
      mkdir -p "$BACKUP_ROOT/storage/objects/$bucket"
      echo "   -> Download bucket: $bucket"
      aws s3 sync "s3://$bucket" "$BACKUP_ROOT/storage/objects/$bucket" \
        --endpoint-url "https://${PROJECT_REF}.storage.supabase.co/storage/v1/s3" \
        --no-progress
    done < "$BUCKET_FILE"
  fi
fi

cat > "$BACKUP_ROOT/RESTORE_NOTES.txt" <<'EOF'
1) Tạo project Supabase mới.
2) Nếu app cũ dùng extensions / webhooks / Realtime publications, bật lại trong project mới.
3) Restore database theo thứ tự:
   psql \
     --single-transaction \
     --variable ON_ERROR_STOP=1 \
     --file database/roles.sql \
     --file database/auth_schema.sql \
     --file database/schema.sql \
     --command 'SET session_replication_role = replica' \
     --file database/auth_data.sql \
     --file database/data.sql \
     --dbname "NEW_DB_URL"

4) Nếu muốn giữ migration history:
   psql \
     --single-transaction \
     --variable ON_ERROR_STOP=1 \
     --file database/history_schema.sql \
     --file database/history_data.sql \
     --dbname "NEW_DB_URL"

5) Review và apply thêm database/changes_auth_storage.sql nếu bạn có custom auth/storage.
6) Recreate buckets dựa trên storage/buckets.ndjson, rồi upload lại file trong storage/objects/.
7) Deploy lại code trong functions/source.
8) Restore lại Edge Function secrets từ file .env riêng của bạn.
9) Nếu muốn user đang đăng nhập không bị đá ra, dùng lại JWT secret cũ ở project mới.
10) Nếu bạn có custom LOGIN roles, đặt lại password thủ công sau khi restore.
EOF

echo "==> Tạo checksum"
(
  cd "$BACKUP_ROOT"
  find . -type f ! -name "SHA256SUMS.txt" -print0 | xargs -0 shasum -a 256 > SHA256SUMS.txt
)

echo "==> Nén thành tar.gz"
tar -czf "${BACKUP_ROOT}.tar.gz" -C "$(dirname "$BACKUP_ROOT")" "$(basename "$BACKUP_ROOT")"

echo
echo "================ DONE ================"
echo "Folder backup : $BACKUP_ROOT"
echo "File archive  : ${BACKUP_ROOT}.tar.gz"
echo "======================================"
