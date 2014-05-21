({
    baseUrl: "../compiled/js",
		/*
    paths: {
        jquery: "some/other/jquery"
    },
		*/
    name: "main",
	findNestedDependencies: true,

	/* sourcemaps - start */
	// see http://www.thecssninja.com/javascript/multi-level-sourcemaps also?
	optimize: "uglify2",
	/*
	useSourceUrl: true,
	uglify2: {
	},
	*/
	generateSourceMaps: true,
	preserveLicenseComments: false,
	/* sourcemaps - end */

    out: "../dist/barndoors-optimized.js"
})
