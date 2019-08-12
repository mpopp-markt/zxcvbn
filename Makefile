.PHONY: patch sign publish install test

build:
	npm run build

patch:
	npm version patch

sign:
	pkgsign sign --signer pgp --pgp-private-key-path /home/zaur/.gnupg/qutorial.asc --pgp-private-key-passphrase `kwalletcli -f terminal-creds -e npm-sign` .

publish: sign
	npm publish

install:
	npm i

test: build
	npm test
