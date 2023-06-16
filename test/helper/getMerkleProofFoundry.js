const { StandardMerkleTree } = require("@openzeppelin/merkle-tree");
const { ethers } = require("ethers");

function buildMerkleTree(accounts) {
  const tree = StandardMerkleTree.of(
    accounts.map((account) => [account]),
    ["address"]
  );

  return tree;
}

function getProof(tree, account) {
  for (const [i, v] of tree.entries()) {
    if (v[0] === account) {
      const proof = tree.getProof(i);
      const abiCoder = new ethers.utils.AbiCoder();
      process.stdout.write(abiCoder.encode(["bytes32[]"], [proof]));
    }
  }
}

const tree = buildMerkleTree(
  process.argv[2].includes(" ") ? process.argv[2].split(" ") : [process.argv[2]]
);
getProof(tree, process.argv[3]);
