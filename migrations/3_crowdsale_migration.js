var crowdsale = artifacts.require("crowdsale");

module.exports = function(deployer) {
	deployer.deploy(crowdsale);
};
