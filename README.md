BARNDOORS
This is the README for the slideshow widget deployed onto Carleton.edu's homepage in August, 2014. It is known internally as "barndoors".

INSTALLATION PREREQUISITES
The barndoors widget runs as JavaScript using the Require.js module/file loader, but it is actually written as CoffeeScript and so you need a fairly simple development environment before you can actually modify anything.

Optional:
* Xcode + command line tools: required if you want to use Homebrew, and obviously only if on OSX
* Homebrew (http://brew.sh/): makes other installations easier, but not required
* Apache / your webserver of choice: not strictly necessary; you can access the widget as a local file but will have some broken links "out of the box"
* CoffeeScript (http://coffeescript.org/): install with Node's package manager via "npm install -g coffee-script". If you are going to use Grunt to build the barndoors widget you don't actually need a separate CoffeeScript installation, but if you're going to be doing much CoffeeScript development it's a good idea.

Required:
* Node.js (http://nodejs.org/): install with brew via "brew install node", or using your preferred method 
* Grunt (http://gruntjs.com/): install with Node's package manager via "npm install -g grunt-cli"

GETTING THE CODE
git clone https://github.com/DookTibsCarl/barndoors

INSTALLATION
Run "npm install" at the command line. This fetches the dependencies defined in package.json which are necessary for building the widget.

If you intend to use the "deploy" Grunt task, you'll need to edit gruntProperties.json to point to an appropriate location on your filesystem. If you just want to test locally you can skip this.

WEBSERVER SETUP
If you plan to run the preview in a webserver, add an alias "/barndoor" that points at the installation directory. For instance if using Apache and you cloned the repo into directory "/Users/joetest/barndoor/" you might add entries like:
<Directory "/Users/joetest/barndoor">
        AllowOverride None
        Options None
        Order allow,deny
        Allow from all
</Directory>
Alias /barndoor /Users/joetest/barndoor/

You could change this to require a different alias without very much work; there are just some test images in index.html that point here and possibly some other hardcoded paths you'd need to track down. If you access the preview as a local file instead of through a webserver, there will be busted images on the previous/next/play/pause UI, but everything will function.

COMPILING
From the base directory, just type "grunt" at the command line. This will run the default grunt task defined in Gruntfile.coffee, which compiles the source code and runs the Require.js <a href="http://requirejs.org/docs/optimization.html">optimization</a> process.

At this point you'll have both individual JavaScript files and <a href="http://coffeescript.org/#source-maps">source maps</a> in compiled/js, and a single concatenated/optimized JavaScript file in dist/.

See index.html for examples on how to use either of these - basically you either point the "data-main" attribute of your Require.js call to "compiled/js/main" for the compiled JavaScript, or "dist/barndoors-1.0" for the optimized release. The individual compiled files are nicer for development but the optimized one should be used for production releases.

TESTING THE APP
Depending on how you set up your webserver, you can probably access the widget by going to http://localhost/barndoor/ in your web browser. If you didn't set up a webserver, it would be something like /Users/joetest/barndoor/index.html. Some of the styling is likely to be a little off as compared to what appears on the Carleton homepage, since some of those styles are customized and defined externally.

ALTERNATE APPROACHES
If for whatever reason you don't want to use Grunt to build things, you could alternately use Cake or even just manual shell commands. Install the CoffeeScript compiler and have at it. The included Cakefile is NOT up to date and will likely need some updating but it's a good starting point, and consulting either that or the Gruntfile should show you what sort of manual compiler commands you'd need to issue. 
