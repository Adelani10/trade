import { DeployFunction } from "hardhat-deploy/dist/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { developmentChains, VERIFICATION_BLOCK_CONFIRMATIONS} from "../helper-hardhat-config"
import verify from "../utils/verify";


const deployTransact: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
    const {deployments, getNamedAccounts,network, ethers} = hre
    const {deploy, log} = deployments
    const {deployer} = await getNamedAccounts()
    const waitBlockConfirmations = developmentChains.includes(network.name)
    ? 1
    : VERIFICATION_BLOCK_CONFIRMATIONS

    log("------------------------------")
    const args: any[] = []
    const transact = await deploy("Transact", {
        from: deployer,
        args: args,
        log: true,
        waitConfirmations: waitBlockConfirmations,
    })

    if(developmentChains .includes(network.name) && process.env.ETHERSCAN_API_KEY){
        log("verifying...")
        await verify(transact.address, args)
    }

    log("-------------------------------")

}

export default deployTransact
deployTransact.tags = ["all", "transact"]