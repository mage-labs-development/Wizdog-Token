async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  
  // Deploy the logic contract (WIZDOG.sol)
  const WIZDOG = await ethers.getContractFactory("WIZDOG");
  console.log("Deploying WIZDOG logic contract...");
  const wizdogLogic = await WIZDOG.deploy();
  await wizdogLogic.waitForDeployment();
  console.log("WIZDOG logic contract deployed to:", await wizdogLogic.getAddress());

  // Prepare the constructor data for the WIZDOG contract
  const constructData = WIZDOG.interface.encodeFunctionData("WizdogConstructor", []);
  console.log("Constructor data:", constructData);
  
  // Deploy the custom proxy contract (WIZDOGProxy.sol)
  const WIZDOGProxy = await ethers.getContractFactory("WIZDOGProxy");
  console.log("Deploying custom proxy contract...");
  const proxy = await WIZDOGProxy.deploy(constructData, await wizdogLogic.getAddress());
  await proxy.waitForDeployment();
  console.log("Custom proxy contract deployed to:", await proxy.getAddress());

  // Create an instance of the WIZDOG contract at the proxy address
  const wizdog = WIZDOG.attach(await proxy.getAddress());

  console.log("Deployment and initialization complete");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });