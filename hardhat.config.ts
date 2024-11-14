import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
require("hardhat-tracer");

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.27", settings: {
      // viaIR: true,
    },
  }
};

export default config;
