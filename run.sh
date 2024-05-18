#!/usr/bin/env bash

set -eu -o pipefail

: "${LINKCHECKERRC:?}" "${RETRIES:?}"

echo "::group::Preparing config"
cfg=$(mktemp)
echo "$LINKCHECKERRC" > "$cfg"
echo "::endgroup::"

echo "::group::Finding linkchecker's create.sql"
pip_show=$(pipx runpip LinkChecker show -f LinkChecker)
create_sql_loc1=$(grep -P -o '^Location:\s+\K.*' <<<"$pip_show")
create_sql_loc2=$(grep -P -o '^\s+\K.*/create\.sql$' <<<"$pip_show")
[[ "$create_sql_loc1" && "$create_sql_loc2" ]]
create_sql_loc="$create_sql_loc1/$create_sql_loc2"
[[ -e "$create_sql_loc" ]]
echo "::endgroup::"

db=
for ((try=1; try <= RETRIES; ++try)); do
  echo "::group::Attempt $try"

  sql=$(mktemp)
  db=$(mktemp)
  sed -e '/^drop table /Id' "$create_sql_loc" | sqlite3 "$db"
  linkchecker --config="$cfg" --file-output=sql/"$sql" "$@" || [[ $? == 1 ]]
  sqlite3 "$db" < "$sql"

  errors=$(sqlite3 "$db" "SELECT COUNT(*) FROM linksdb WHERE NOT valid")
  if [[ $errors == 0 ]]; then
    break
  else
    sleep 30
  fi

  echo "::endgroup::"
done

sqlite3 "$db" '.mode json' 'SELECT * FROM linksdb' | "$GITHUB_ACTION_PATH"/output.jq

[[ $errors == 0 ]]
