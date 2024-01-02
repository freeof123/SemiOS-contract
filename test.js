const { ethers } = require("ethers");

const abiCoder = ethers.AbiCoder.defaultAbiCoder();

const proof = [
    "0x123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0",
    "0xabcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789"
];


console.log(abiCoder.encode(["bytes32[]"], [proof]))

// console.log(ethers.AbiCoder.defaultAbiCoder)