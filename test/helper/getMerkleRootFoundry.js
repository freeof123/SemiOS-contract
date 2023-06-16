const { StandardMerkleTree } = require("@openzeppelin/merkle-tree");
const { ethers } = require("ethers");

function buildMerkleTree(accounts) {
  const tree = StandardMerkleTree.of(
    accounts.map((account) => [account]),
    ["address"]
  );

  return tree;
}

const tree = buildMerkleTree(
  process.argv[2].includes(" ") ? process.argv[2].split(" ") : [process.argv[2]]
);

process.stdout.write(tree.root);
