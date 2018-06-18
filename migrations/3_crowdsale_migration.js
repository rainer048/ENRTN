var crowdsale = artifacts.require("crowdsale.sol");

module.exports = function(deployer) {
	deployer.deploy(crowdsale);
};
