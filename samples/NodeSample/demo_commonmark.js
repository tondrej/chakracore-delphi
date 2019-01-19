console.log('***** commonmark demo *****');

var commonmark = require('commonmark');

var reader = new commonmark.Parser();
var writer = new commonmark.HtmlRenderer();
var md = 'Hello, *world*!\n\nfrom [chakracore-delphi](https://github.com/tondrej/chakracore-delphi)';
var parsed = reader.parse(md); // parsed is a 'Node' tree
// transform parsed if you like...
var result = writer.render(parsed); // result is a String
console.log('md: ', JSON.stringify(md));
console.log('result: ', JSON.stringify(result));
