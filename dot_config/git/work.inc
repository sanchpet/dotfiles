# Work identity for repos under ~/IWE/employer-past/ (see ~/.gitconfig includeIf).
# Signing is off here — corporate repos don't use the personal SSH key.
[user]
	name = corp-user
	email = corp-user@employer-past.ru
[commit]
	gpgsign = false
[tag]
	gpgsign = false
