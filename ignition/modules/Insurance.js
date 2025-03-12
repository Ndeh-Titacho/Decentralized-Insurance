// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");


module.exports = buildModule("Insurance", (m) => {
    // Get the deployer's address (this will be the admin)
    // const deployer = m.getAccount(0); // First account in Hardhat network (admin)
  
    // Deploy the DecentralizedInsurance contract with the deployer's address as the admin
    const Insurance = m.contract("decentralizedInsurance", []);
  
    return { Insurance };
  });