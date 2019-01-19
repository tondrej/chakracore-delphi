console.log('***** lodash demo *****');

var lodash = require('lodash');

var users = [
  { 'user': 'fred',   'age': 48 },
  { 'user': 'barney', 'age': 36 },
  { 'user': 'fred',   'age': 40 },
  { 'user': 'barney', 'age': 34 }
];
 
console.log('users: ', JSON.stringify(users));
console.log('by user: ', JSON.stringify(_.sortBy(users, ['user'])));
console.log('by age: ', JSON.stringify(_.sortBy(users, ['age'])));
