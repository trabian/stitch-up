## stitch-up

Stitch-up is a CommonJS packaging tool adding package.json support to
[Stitch](https://github.com/sstephenson/stitch).

Stitch converts a CommonJS module into a single JS file that can be
included in the browser or, in the case of [titanium-backbone](https://github.com/trabian/titanium-backbone), in a Titanium project. The purpose of stitch-up is to allow the paths, dependencies, and output location for the Stitch packager to be specified in package.json both within the primary project and within any dependent modules.

Unlike Stitch, stitch-up also provides a way of copying files as-is from
node modules into a customizable (via package.json) location in the primary project. This serves as a simple asset pipeline for including files such as jquery.js that would make a stitched file too big or need to be included separately for any other reason. This could later be extended to non-JS files to allow copying of images, stylesheets, or others.

See the [package.json for titanium-backbone](https://github.com/trabian/titanium-backbone/blob/master/package.json) for an example.

### Current status

This project is still in early stages, but it works.
