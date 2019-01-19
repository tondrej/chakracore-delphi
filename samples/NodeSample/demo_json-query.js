console.log('***** json-query *****');

var jsonQuery = require('json-query');

var data = {
  people: [
    {name: 'Matt', country: 'NZ'},
    {name: 'Pete', country: 'AU'},
    {name: 'Mikey', country: 'NZ'}
  ]
};
var query = 'people[*country=NZ].name';

console.log('data: ', JSON.stringify(data));
console.log('query: ', JSON.stringify(query));
console.log('result: ', JSON.stringify(jsonQuery(query, { data: data })));
