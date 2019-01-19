console.log('***** graphql demo *****');

var graphql = require('graphql');

var schema = new graphql.GraphQLSchema({
  query: new graphql.GraphQLObjectType({
    name: 'RootQueryType',
    fields: {
      hello: {
        type: graphql.GraphQLString,
        resolve() {
          return 'world';
        }
      }
    }
  })
});

function run(query) {
  graphql.graphql(schema, query).then(result => {
    console.log('schema: ', JSON.stringify(schema));
    console.log('query: ', JSON.stringify(query));
    console.info('result: ', JSON.stringify(result));
	console.log();
  }).catch(e => {
    console.log('schema: ', JSON.stringify(schema));
    console.log('query: ', JSON.stringify(query));
    console.error('error: ', JSON.stringify(e));
	console.log();
  });
};

run('{ hello }');
run('{ boyhowdy }'); // schema error
