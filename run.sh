#!/usr/bin/env bash

set -eu -o pipefail

: "${LINKCHECKERRC:?}" "${RETRIES:?}"

echo "::group::Setup temporary directory"
tmpdir=$(mktemp -d)
echo "dir=$tmpdir" >> "$GITHUB_OUTPUT"
cd "$tmpdir"
echo "::endgroup::"

echo "$LINKCHECKERRC" > linkcheckerrc

echo "::group::Find linkchecker's create.sql"
pip_show=$(pipx runpip LinkChecker show -f LinkChecker)
create_sql_loc1=$(grep -P -o '^Location:\s+\K.*' <<<"$pip_show")
create_sql_loc2=$(grep -P -o '^\s+\K.*/create\.sql$' <<<"$pip_show")
[[ "$create_sql_loc1" && "$create_sql_loc2" ]]
create_sql_loc="$create_sql_loc1/$create_sql_loc2"
[[ -e "$create_sql_loc" ]]
sed -e '/^drop table /Id' "$create_sql_loc" > create.sql
echo "::endgroup::"

db=
for ((try=1; try <= RETRIES; ++try)); do
  echo "::group::Attempt $try"

  sql=try"$try".sql
  db=try"$try".db
  sqlite3 "$db" < create.sql
  linkchecker --config=linkcheckerrc --file-output=sql/"$sql" "$@" || [[ $? == 1 ]]
  sqlite3 "$db" < "$sql"

  errors=$(sqlite3 "$db" "SELECT COUNT(*) FROM linksdb WHERE NOT valid")
  if [[ $errors == 0 ]]; then
    break
  else
    sleep 30
  fi

  echo "::endgroup::"
done

[[ $db ]]
sqlite3 "$db" '.mode json' 'SELECT * FROM linksdb' > result.json
"$GITHUB_ACTION_PATH"/output.jq result.json

[[ $errors == 0 ]]
