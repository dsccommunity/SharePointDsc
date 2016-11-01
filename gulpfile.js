var gulp = require("gulp");
var through2 = require("through2");
var markdownlint = require("markdownlint");
var fs = require('fs');

gulp.task("default", function task() {
  return gulp.src("*.md", { "read": false })
    .pipe(through2.obj(function obj(file, enc, next) {
      markdownlint(
        { "files": [ file.path ] },
        function callback(err, result) {
          var resultString = (result || "").toString();
          if (resultString) {
            fs.writeFile('markdownissues.txt', resultString, null);
          }
          next(err, file);
        });
    }))
});
