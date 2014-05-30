Installation:
* you'll need NodeJS / Grunt / CoffeeScript / etc.
* once you have the repo, do a "npm install" to get the required dependencies
* to compile, do "grunt" at cmdline

At this point you'll have both individual JavaScript files in compiled/js and
a single concatenated/optimized JavaScript file in dist/. See index.html 
for examples on how to use either of these. The individual files are nicer
for development but the optimized one should be used for production releases.
