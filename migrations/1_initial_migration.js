//const { deployProxy } = require('@openzeppelin/truffle-upgrades');
const Token = artifacts.require("SpinWheel");
//const Router = artifacts.require("IUniswapV2Router02");
const currTime = Number(Math.round(new Date().getTime() / 1000));

module.exports = async function (deployer, network, accounts) {
  await deployer.deploy(Token,1078,"0x77c21c770Db1156e271a3516F89380BA53D594FA");

  // let tokenInstance = await Token.deployed();

  // await addLiq(tokenInstance, accounts[0]);

};

const addLiq = async (tokenInstance, account) => {

  const routerInstance = await Router.at(
    "0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3"
  );
  
  let supply = await tokenInstance.totalSupply();
  await tokenInstance.approve(routerInstance.address, BigInt(supply), {
    from: account,
  });

  await routerInstance.addLiquidityETH(
    tokenInstance.address,
    BigInt(supply / 2),
    0,
    0,
    routerInstance.address,
    currTime + 100,
    { value: 1e16, from: account }
  );

}
