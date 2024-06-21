async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  
  // Deploy the logic contract (LABS.sol)
  const LABS = await ethers.getContractFactory("LABS");
  console.log("Deploying LABS logic contract...");
  const labsLogic = await LABS.deploy();
  await labsLogic.waitForDeployment();
  console.log("LABS logic contract deployed to:", await labsLogic.getAddress());

  // Prepare the constructor data for the LABS contract
  const constructData = LABS.interface.encodeFunctionData("LABSConstructor", []);
  console.log("Constructor data:", constructData);
  
  // Deploy the custom proxy contract (LABSProxy.sol)
  const LABSProxy = await ethers.getContractFactory("LABSProxy");
  console.log("Deploying custom proxy contract...");
  const proxy = await LABSProxy.deploy(constructData, await labsLogic.getAddress());
  await proxy.waitForDeployment();
  console.log("Custom proxy contract deployed to:", await proxy.getAddress());

  // Create an instance of the LABS contract at the proxy address
  const labs = LABS.attach(await proxy.getAddress());

  console.log("Deployment and initialization complete");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });