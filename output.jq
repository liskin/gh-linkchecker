include "linkchecker";

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
	, "(\"\(.name | un_sqlify)\")"?
	] | join(" ");

def format_multiline:
	gsub("\n"; "\n    ");

def format_result:
	[ "\(format_link):"
	, (.result | un_sqlify | format_multiline | "Result: " + .)?
	, (.warning | un_sqlify | format_multiline | "Warning: " + .)?
	, (.info | un_sqlify | format_multiline | "Info: " + .)?
	] | join("\n");

# NB: GitHub Actions only shows the first 10 annotations of each kind
sort_by(.parentname, .urlname) |
.[] |
if is_error then
	format_result | gh_error
elif is_warning then
	format_result | gh_warning
elif is_info then
	format_result | gh_notice
else
	error
end
