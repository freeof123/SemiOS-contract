const { TypedDataDomain } = require("@ethersproject/abstract-signer");
const { StandardMerkleTree } = require("@openzeppelin/merkle-tree");
const { getImplementationAddress } = require("@openzeppelin/upgrades-core");
const { Address } = require("cluster");
const { ethers } = require("ethers");

function findValueByKey(obj, key) {
  for (const k in obj) {
    if (k === key) {
      return obj[k];
    } else if (typeof obj[k] === "object") {
      const result = findValueByKey(obj[k], key);
      if (result) {
        return result;
      }
    }
  }
  return undefined;
}

async function generatePermissionControlSignature(privateKey, permissionControlAddress, value) {
  const signer = new ethers.Wallet(privateKey);
  const provider = new ethers.providers.JsonRpcProvider(`http://127.0.0.1:7545`);
  // All properties on a domain are optional
  const domain = {
    name: "D4AProtocol",
    version: "2",
    chainId: (await provider.getNetwork()).chainId,
    verifyingContract: permissionControlAddress,
  };

  // The named list of all type definitions
  const types = {
    AddPermission: [
      { name: "daoId", type: "bytes32" },
      { name: "whitelist", type: "Whitelist" },
      { name: "blacklist", type: "Blacklist" },
    ],
    Blacklist: [
      { name: "minterAccounts", type: "address[]" },
      { name: "canvasCreatorAccounts", type: "address[]" },
    ],
    Whitelist: [
      { name: "minterMerkleRoot", type: "bytes32" },
      { name: "minterNFTHolderPasses", type: "address[]" },
      { name: "canvasCreatorMerkleRoot", type: "bytes32" },
      { name: "canvasCreatorNFTHolderPasses", type: "address[]" },
    ],
  };

  const signature = await signer._signTypedData(domain, types, value);
  return signature;
}

async function generateMintNFTSignature(privateKey, protocolAddress, value) {
  const signer = new ethers.Wallet(privateKey);
  const provider = new ethers.providers.JsonRpcProvider(`http://127.0.0.1:7545`);
  // All properties on a domain are optional
  const domain = {
    name: "D4AProtocol",
    version: "2",
    chainId: (await provider.getNetwork()).chainId,
    verifyingContract: protocolAddress,
  };

  // The named list of all type definitions
  const types = {
    MintNFT: [
      { name: "canvasID", type: "bytes32" },
      { name: "tokenURIHash", type: "bytes32" },
      { name: "flatPrice", type: "uint256" },
    ],
  };

  const signature = await signer._signTypedData(domain, types, value);
  return signature;
}

function buildMerkleTree(accounts) {
  const tree = StandardMerkleTree.of(
    accounts.map((account) => [account]),
    ["address"],
  );

  return tree;
}

function getProof(tree, account) {
  for (const [i, v] of tree.entries()) {
    if (v[0] === account) {
      const proof = tree.getProof(i);
      return proof;
    }
  }
}

function getPrivateKey(index) {
  const privateKeyList = [
    // private key with mnemonic
    // "test test test test test test test test test test test junk"
    "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80",
    "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d",
    "0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a",
    "0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6",
    "0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a",
    "0x8b3a350cf5c34c9194ca85829a2df0ec3153be0318b5e2d3348e872092edffba",
    "0x92db14e403b83dfe3df233f83dfa3a0d7096f21ca9b0d6d6b8d88b2b4ec1564e",
    "0x4bbbf85ce3377467afe5d46f804f221813b2bb87f24d81f60f1fcdbf7cbf4356",
    "0xdbda1821b80551c9d65939329250298aa3472ba22feea921c0cf5d620ea67b97",
    "0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6",
  ];
  return privateKeyList[index];
}

async function getImplAddress(network = "homestead", proxyAddress) {
  const provider = new ethers.providers.InfuraProvider(network);
  const currentImplAddress = await getImplementationAddress(provider, proxyAddress);
  return currentImplAddress;
}

module.exports = {
  findValueByKey,
  generatePermissionControlSignature,
  generateMintNFTSignature,
  buildMerkleTree,
  getProof,
  getPrivateKey,
  getImplAddress,
};
