#!/usr/bin/env -S jq -r -f

# undo linkcheck.logger.sql.sqlify
def un_sqlify:
	gsub("\\\\n"; "\n");

# escape GitHub Actions command data
# https://github.com/actions/toolkit/blob/ae38557bb0dba824cdda26ce787bd6b66cf07a83/packages/core/src/command.ts#L80-L85
# (yes, they escape % and \r as well, but then they fail to unescape it on display :facepalm:)
def gh_escape:
	gsub("\n"; "%0A");

def gh_error:
	"::error::\(. | gh_escape)";
def gh_warning:
	"::warning::\(. | gh_escape)";
def gh_notice:
	"::notice::\(. | gh_escape)";

def format_link:
	[ "\(.parentname | un_sqlify) → \(.urlname | un_sqlify)"
	, " (\"\(.name | un_sqlify)\")"?
	] | values | join("\n");

def format_multiline:
	gsub("\n"; "\n    ");

def format_result:
	[ "\(format_link):"
	, (.result | un_sqlify | format_multiline | "Result: " + .)?
	, (.warning | un_sqlify | format_multiline | "Warning: " + .)?
	, (.info | un_sqlify | format_multiline | "Info: " + .)?
	] | values | join("\n");

# output in order of severity as GitHub Actions only show the first 10 annotations
(.[] | select(.valid == 0) | format_result | gh_error),
(.[] | select(.valid == 1 and .warning) | format_result | gh_warning),
(.[] | select(.valid == 1 and .info) | format_result | gh_notice)
