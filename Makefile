
bin = ./node_modules/.bin
coffee = $(bin)/coffee

browserify = $(bin)/browserify -t coffeeify -d --extension=".coffee"
watch = $(coffee) scripts/watch.coffee framer,test/tests
githash = `git rev-parse --short HEAD`

all: build

watch:
	$(watch) make $(cmd)
	# make watch cmd=perf

build:
	make clean
	mkdir -p build
	# $(coffee) scripts/banner.coffee > build/framer.debug.js
	# cat vendor/react.min.js >> build/framer.debug.js
	$(browserify) framer/Framer.coffee >> build/framer.debug.js
	cat build/framer.debug.js | $(bin)/exorcist build/framer.js.map > build/framer.js
	# Build the minimized version
	# cd build; ../$(bin)/uglifyjs \
	# 	--source-map-include-sources \
	# 	--in-source-map framer.js.map \
	# 	--source-map framer.min.js.map \
	# 	framer.js > framer.min.js
	# $(coffee) scripts/fix-sourcemap.coffee
	# Copy the file over to the cactus project
	cp build/framer.js extras/CactusFramer/static/
	cp build/framer.js.map extras/CactusFramer/static/
buildw:
	$(watch) make build

clean:
	rm -rf build


# Testing

test:
	make lint
	make build
	mkdir -p test/lib
	$(browserify) test/init.coffee -o test/init.js
	$(bin)/mocha-phantomjs test/index.html
testw:
	$(watch) make test

safari:
	make build
	mkdir -p test/lib
	$(browserify) test/init.coffee -o test/init.js
	# $(bin)/mocha-phantomjs test/index.html
	open -g -a Safari test/index.html
safariw:
	$(watch) make safari


perf:
	$(browserify) perf/init.coffee -o perf/init.js
	$(bin)/phantomjs perf/runner.js perf/index.html
perfw:
	$(watch) make perf

perf-safari:
	$(browserify) perf/init.coffee -o perf/init.js
	open -g -a Safari perf/index.html
perf-safariw:
	$(watch) make perf-safari


# Building and uploading the site

dist:
	make build
	mkdir -p build/Framer
	cp -R templates/Project build/Framer/Project
	rm -Rf build/Framer/Project/framer
	mkdir -p build/Framer/Project/framer
	cp build/framer.js build/Framer/Project/framer/framer.js
	cp build/framer.js.map build/Framer/Project/framer/framer.js.map
	find build/Framer -name ".DS_Store" -depth -exec rm {} \;
	cd build; zip -r Framer.zip Framer

site%build:
	make dist
	mkdir -p build/builds.framerjs.com
	$(coffee) scripts/site-deploy.coffee build
	cp -R extras/builds.framerjs.com/static build/builds.framerjs.com/static
	mkdir -p build/builds.framerjs.com/latest
	cp build/*.js build/builds.framerjs.com/latest
	cp build/*.map build/builds.framerjs.com/latest
	cp build/*.zip build/builds.framerjs.com/latest
	cp -R build/builds.framerjs.com/latest build/builds.framerjs.com/$(githash)

site%upload:
	make site:build
	$(coffee) scripts/site-deploy.coffee upload

deploy:
	make site:build
	make site:upload

resources%optimize:
	python scripts/optimize.py
	
resources%upload:
	cd extras/resources.framerjs.com; cactus deploy

publish:
	# Todo: update version
	coffee -o lib/ -c framer/
	npm publish

lint:
	./node_modules/.bin/coffeelint -f coffeelint.json -r framer

.PHONY: all build test clean perf watch