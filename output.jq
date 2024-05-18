#!/usr/bin/env -S jq -r -f

# undo linkcheck.logger.sql.sqlify
def un_sqlify:
	gsub("\\\\n"; "\n");

# escape GitHub Actions command data
# https://github.com/actions/toolkit/blob/ae38557bb0dba824cdda26ce787bd6b66cf07a83/packages/core/src/command.ts#L80-L85
# (yes, they escape % and \r as well, but then they fail to unescape it on display :facepalm:)
def gh_escape:
	gsub("\n"; "%0A");

def format_link:
	"\(.parentname | un_sqlify) → \(.urlname | un_sqlify)" +
	(if .name then " (\"\(.name | un_sqlify)\")" else "" end);

def format_error:
	"\(format_link): \(.result | un_sqlify)" |
	"::error::\(. | gh_escape)";

def format_warning:
	"\(format_link): \(.result | un_sqlify), but \(.warning | un_sqlify)" |
	"::warning::\(. | gh_escape)";

(.[] | select(.valid == 0) | format_error),
(.[] | select(.valid == 1 and .warning) | format_warning)
