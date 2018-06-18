const ENRTNTokenContract = artifacts.require("./ENRTNToken.sol");
const ENRTNCrowdsaleContract = artifacts.require("./ENRTNCrowdsale.sol");

module.exports = async function(deployer, network, accounts) {
    deployer.then(async () => {
        await deployer.deploy(ENRTNTokenContract);

        await deployer.link(ENRTNTokenContract, ENRTNCrowdsaleContract);
        return await deployer.deploy(ENRTNCrowdsaleContract, ENRTNTokenContract.address, accounts[9]);
    });

    console.log('Ok!');
};
