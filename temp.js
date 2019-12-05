let sinon = require('sinon');
let inc = require('./inc');

let stub = sinon.stub(inc, "func").returns({ test: 'test'});
console.log(inc.func(7));
stub.restore();
console.log(inc.func(7));