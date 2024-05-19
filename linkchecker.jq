def join_sqlified:
	join("\\\\n");

def is_error:
	.valid == 0;

def is_warning:
	.valid == 1 and .warning;

def is_info:
	.valid == 1 and .info;

def to_error:
	.valid = 0;

def to_warning:
	if is_error then
		.valid = 1 |
		.warning = .warning // "(downgraded from error)"
	elif is_info then
		.warning = ([.warning // empty, .info // empty] | join_sqlified) |
		.info = null
	end;

def to_info:
	.valid = 1 |
	.info = ([.warning // empty, .info // empty] | join_sqlified) |
	.warning = null;
