console.log('***** moment demo *****');

var moment = require('moment');

var now = moment();
var fmt = 'dddd MMMM Do YYYY, h:mm:ss a';
console.log(JSON.stringify(now.format(fmt)), JSON.stringify(now.utc().format(fmt)), 'UTC');
