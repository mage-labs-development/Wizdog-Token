async function main() {
    const [deployer] = await ethers.getSigners();
  
    console.log("Deploying contracts with the account:", deployer.address);
    
    const LABS = await ethers.getContractFactory("LABS");
    
    console.log("Deploying LABS implementation...");
    const labs = await upgrades.deployProxy(LABS, [], { initializer: 'LABSConstructor' });
    await labs.waitForDeployment();
    
    console.log("LABS deployed to:", await labs.getAddress());
  
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });