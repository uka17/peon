let objectId = 0;
const connectionEngine = require('../../app/engine/connection');
const assert  = require('chai').assert;

describe('connection engine', function() {
    it('execute job', (done) => {
        connectionEngine.getConnection(objectId)
            .then(resolve => { assert.isNull(resolve); done() }, reject => { assert.isNull(reject); done() })
    });                                          
});
