import "@nomicfoundation/hardhat-foundry"
import { HardhatUserConfig } from "hardhat/config"

export const RPC_URL = "http://127.0.0.1:8545"

const networksConfig = {
    hardhat: {
        accounts: {
            mnemonic:
                "test test test test test test test test test test test junk",
        },
        forking: {
            url: RPC_URL,
            enabled: true,
            // blockNumber: 97010949,
        },
    },

    optimism: {
        url:  RPC_URL,
        accounts: [
            "ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80",
            // default account derived from mnemonic "test test test test test test test test test test test junk"
        ],
    },

}

const config: HardhatUserConfig = {
    defaultNetwork: "optimism",

    networks: networksConfig,
    solidity: {
        version: "0.8.18",
        settings: {
            optimizer: {
                enabled: true,
                runs: 200,
            },
        },
    },
}

export default config
