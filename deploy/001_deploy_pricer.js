const { NonceManager } = require("@ethersproject/experimental");

const delay = ms => new Promise(res => setTimeout(res, ms));
const etherscanChains = ["poly", "bsc", "poly_mumbai", "ftm", "arbitrum", "avax", "avax_fuji"];
const sourcifyChains = ["xdai", "celo", "arbitrum"];

const main = async function (hre) {
    const { deployments, getNamedAccounts } = hre;
    const { deploy } = deployments;
    const { deployer } = await getNamedAccounts();
    const managedDeployer = new NonceManager(deployer);
    const signer = await hre.ethers.getSigner(deployer);

    // We get the contract to deploy
    const pricerHandlerV1 = await deploy("PricerHandlerV1", {
        
        from: managedDeployer.signer, 
        proxy: {
            execute: {
                init: {
                    methodName: 'initialize',
                    args: [signer.address]
                },
            },
        },
        log: true,
        deterministicDeployment: "0x9c22ff5f21f0b81b113e63f7db6da94fedef11b2119b4088b89664fb9a3cb658"
    });
    console.log("PricerHandlerV1 deployed to:", pricerHandlerV1.address);

    const pricer = await deploy("Pricer", {
        from: managedDeployer.signer, 
        log: true, 
        args: [signer.address],
        deterministicDeployment: "0x9c22ff5f21f0b81b113e63f7db6da94fedef11b2119b4088b89664fb9a3cb658"
    });
    console.log("Pricer deployed to:", pricer.address);
    const PricerContractFactory = await ethers.getContractFactory("Pricer");
    const pricerContract = await PricerContractFactory.attach(pricer.address);
    if ((await pricerContract.implementation()) !== pricerHandlerV1.address) {
        await pricerContract.connect(signer).setImplementation(pricerHandlerV1.address);
        console.log("set pricer implementation to pricerHandlerV1");
    }
    const chain = hre.network.name;
    try {
        await verify(hre, chain, pricer.address, [signer.address]);
    } catch (error) {
        console.log(error);
    }

    try {
        await verify(hre, chain, pricerHandlerV1.implementation, []);
    } catch { }
}

async function verify(hre, chain, contract, args) {
    const isEtherscanAPI = etherscanChains.includes(chain);
    const isSourcify = sourcifyChains.includes(chain);
    if (!isEtherscanAPI && !isSourcify)
        return;

    console.log('verifying...');
    await delay(5000);
    if (isEtherscanAPI) {
        await hre.run("verify:verify", {
            address: contract,
            network: chain,
            constructorArguments: args
        });
    } else if (isSourcify) {
        try {
            await hre.run("sourcify", {
                address: contract,
                network: chain,
                constructorArguments: args
            });
        } catch (error) {
            console.log("verification failed: sourcify not supported?");
        }
    }
}

module.exports = main;