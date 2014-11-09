build:
	cp pkg/META.in pkg/META
	ocaml pkg/build.ml native=true native-dynlink=true

test: build
	rm _build/src_test/ -rf
	ocamlbuild -classic-display -use-ocamlfind src_test/test_protobuf.byte --

doc:
	ocamlbuild -use-ocamlfind doc/api.docdir/index.html \
						 -docflags -t -docflag "API reference for protobuf" \
						 -docflags '-colorize-code -short-functors -charset utf-8' \
						 -docflags '-css-style style.css'
	cp doc/style.css api.docdir/

clean:
	ocamlbuild -clean

.PHONY: build test doc clean

gh-pages: doc
	git clone `git config --get remote.origin.url` .gh-pages --reference .
	git -C .gh-pages checkout --orphan gh-pages
	git -C .gh-pages reset
	git -C .gh-pages clean -dxf
	cp -t .gh-pages/ api.docdir/*
	git -C .gh-pages add .
	git -C .gh-pages commit -m "Update Pages"
	git -C .gh-pages push origin gh-pages -f
	rm -rf .gh-pages

release: gh-pages
	@if [ -z "$(VERSION)" ] || [ -z "$(OPAMREPO)" ]; then \
		echo "Usage: make release VERSION=1.0 OPAMREPO=~/opam-repository"; exit 1; fi
	@echo ">>>>>> Releasing the package"
	git tag -a v$(VERSION) -m "Version $(VERSION)."
	git push origin v$(VERSION)
	@echo ">>>>>> Updating OPAM repository"
	repo="$$(git config remote.origin.url | cut -d: -f2)" \
	 user="$$(echo $${repo} | cut -d/ -f1)" \
	 pkg="$$(echo $${repo} | cut -d/ -f2 | sed s/.git//)" \
	 url="https://github.com/$${repo}/archive/v$(VERSION).tar.gz" \
	 opam="$(OPAMREPO)/packages/$${pkg}/$${pkg}.$(VERSION)"; \
	 set +e; \
	 mkdir -p $${opam}; \
	 cp descr opam $${opam}; \
	 echo $${pkg} >$${opam}/findlib; \
	 echo "archive: \"$${url}\"" >$${opam}/url; \
	 echo "checksum: \"$$(curl -sL $${url} | md5sum | cut -d' ' -f1)\"" >>$${opam}/url; \
	 git -C $(OPAMREPO) pull --rebase git@github.com:ocaml/opam-repository master; \
	 git -C $(OPAMREPO) add packages/$${pkg}/$${pkg}.$(VERSION); \
	 git -C $(OPAMREPO) commit -m "+$${pkg}.$(VERSION)"; \
	 git -C $(OPAMREPO) push --force origin

.PHONY: gh-pages release
