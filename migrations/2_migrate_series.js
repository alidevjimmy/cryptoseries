var Series = artifacts.require("./Series.sol");

module.exports = function (deployer) {
  deployer.deploy(Series , "Game Of Thrones" , web3.utils.toWei("0.005" , "ether") , 14*24*60*60/15);
}
