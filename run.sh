#!/usr/bin/env bash

set -eu -o pipefail

: "${LINKCHECKERRC:?}" "${CUSTOM_JQ_FILTER:?}" "${CUSTOM_JQ_FILTER_POST:?}" "${RETRIES:?}"

echo "::group::Setup temporary directory"
tmpdir=$(mktemp -d)
echo "dir=$tmpdir" >> "$GITHUB_OUTPUT"
cd "$tmpdir"
echo "::endgroup::"

echo "$LINKCHECKERRC" > linkcheckerrc

echo 'include "linkchecker";' > filter.jq
echo "$CUSTOM_JQ_FILTER" >> filter.jq

echo 'include "linkchecker";' > filter-post.jq
echo "$CUSTOM_JQ_FILTER_POST" >> filter-post.jq

echo "::group::Find linkchecker's create.sql"
pip_show=$(pipx runpip LinkChecker show -f LinkChecker)
create_sql_loc1=$(grep -P -o '^Location:\s+\K.*' <<<"$pip_show")
create_sql_loc2=$(grep -P -o '^\s+\K.*/create\.sql$' <<<"$pip_show")
[[ "$create_sql_loc1" && "$create_sql_loc2" ]]
create_sql_loc="$create_sql_loc1/$create_sql_loc2"
[[ -e "$create_sql_loc" ]]
sed -e '/^drop table /Id' "$create_sql_loc" > create.sql
echo "::endgroup::"

for ((try=1; try <= RETRIES; ++try)); do
	echo "::group::Attempt $try"

	sql=try"$try".sql
	json=try"$try".json

	# run linkchecker, continue if its return value is 0 (success) or 1 (warnings/errors)
	linkchecker --config=linkcheckerrc --file-output=sql/"$sql" "$@" || [[ $? == 1 ]]

	# convert output to json
	sqlite3 "" \
		".read create.sql" \
		".read $sql" \
		".mode json" \
		"SELECT * FROM linksdb" \
		> "$json"
	[[ -s "$json" ]] || echo "[]" > "$json"

	# invoke custom filter, if any
	jq -c -L "$GITHUB_ACTION_PATH" -f filter.jq "$json" > result.json

	# retry if there are any errors
	if jq -e 'all(.valid != 0)' result.json; then
		break
	else
		sleep 30
	fi

	echo "::endgroup::"
done

echo "::group::Invoking custom post filter"
# invoke custom filter, if any
jq -c -L "$GITHUB_ACTION_PATH" -f filter-post.jq result.json > result-post.json
echo "::endgroup::"

echo "::group::Results"
jq -L "$GITHUB_ACTION_PATH" -f "$GITHUB_ACTION_PATH"/output.jq -r result-post.json
echo "::endgroup::"

jq -e 'all(.valid != 0)' result-post.json
