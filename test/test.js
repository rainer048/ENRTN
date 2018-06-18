const TokenContract = artifacts.require("./ENRTNToken.sol");
const CrowdsaleContract = artifacts.require("./ENRTNCrowdsale.sol");

contract('ManagementContract', async (accounts) => {

    beforeEach(async function() {
        token = await TokenContract.deployed();
        crowdsale = await CrowdsaleContract.deployed();
    });

    it('should return the correct totalSupply erc20 after construction', async function() {
        let totalSupply_ = await token.totalSupply();
        const pendingSupply = 72800000 * 10 ** 18;
        assert.equal(totalSupply_.valueOf(),  pendingSupply, "total supply is not correct");
    });

});
