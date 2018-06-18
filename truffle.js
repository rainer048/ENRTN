module.exports = {
    networks: {
        development: {
            host: "localhost",
            port: 8545,
            network_id: "*" // Match any network id
        },
        coverage: {
            host: 'localhost',
            network_id: '*', // eslint-disable-line camelcase
            port: 8555,
            gas: 0xfffffffffff,
            gasPrice: 0x01,
        },
        ganache: {
            host: 'localhost',
            port: 8545,
            gas: 6000000,
            network_id: "*"
        }
    },
    mocha: {
        enableTimeouts: false
    }
};
